#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <sdktools_functions>
#include <sdkhooks>

#define CVAR_FLAGS FCVAR_NOTIFY
#define SOUND_FLAME	"weapons/molotov/fire_loop_1.wav"
 
#define Pai 3.14159265358979323846 
#define Particle_jet_01_flame "fire_jet_01_flame" 
#define Particle_gas_explosion_pump "gas_explosion_pump"
#define Particle_gas_explosion_main "gas_explosion_main"
#define Particle_st_elmos_fire "st_elmos_fire"
#define Particle_electrical_arc_01_system "electrical_arc_01_system"

#define MODEL_MISSILE "models/w_models/weapons/w_HE_grenade.mdl"
#define MODEL_W_PIPEBOMB "models/w_models/weapons/w_eq_pipebomb.mdl"

#define Type_Pistol	5
#define Type_Rifle	1
#define Type_Shotgun 2
#define Type_Sniper	3
#define Type_Smg	4

#define GetClassName
#define g_iBlockDamage

int Cannon[MAXPLAYERS + 1] = {0, ...}, Flame[MAXPLAYERS + 1][3], ShowMsg[MAXPLAYERS + 1] = {0, ...}, GameMode, L4D2Version, g_sprite;
float FlameDamage[MAXPLAYERS + 1] = {0.0, ...}, FlameLength[MAXPLAYERS + 1] = {0.0, ...}, FlameTick[MAXPLAYERS + 1] = {0.0, ...};
float Bullet[MAXPLAYERS + 1] = {0.0, ...}, FlameStartTime[MAXPLAYERS + 1] = {0.0, ...}, ShotTime[MAXPLAYERS + 1] = {0.0, ...};

public Plugin myinfo = 
{
	name = "Dangerous Weapons",
	author = "Pan Xiaohai",
	description = "",
	version = "1.1",	
}

ConVar l4d_dangerous_enable;
ConVar l4d_dangerous_message;
ConVar l4d_dangerous_safe;
ConVar l4d_dangerous_particle;
ConVar l4d_dangerous_power[6];
ConVar l4d_dangerous_drop_ci;
ConVar l4d_dangerous_drop_si;
ConVar l4d_dangerous_damage_hit;
ConVar l4d_dangerous_damage_explode;
ConVar l4d_dangerous_damage_radius;
ConVar l4d_dangerous_drop_pickupcount;
ConVar l4d_dangerous_cannon_catchfire;
ConVar l4d_dangerous_flame_damage;
ConVar l4d_dangerous_flame_length;
ConVar l4d_dangerous_flame_duration;
ConVar l4d_dangerous_pickup_mode;
ConVar l4d_dangerous_mode_cannon;
ConVar l4d_dangerous_mode_electromagnetic;
ConVar l4d_dangerous_mode_flamethrower;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();
	if(test == Engine_Left4Dead)
	{
	    L4D2Version = false;
	}
	else if(test == Engine_Left4Dead2)
	{
	    L4D2Version = true;
	}
	else
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead series.");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

public void OnPluginStart()
{
 	l4d_dangerous_enable = CreateConVar("l4d_dangerous_enable", "1", "  0:disable, 1:enable in coop mode, 2: enable in all mode ", CVAR_FLAGS);
 	l4d_dangerous_message=CreateConVar("l4d_dangerous_message", "3", "how many times to display usage information ,0 disable  ", CVAR_FLAGS);	
 	l4d_dangerous_safe=CreateConVar("l4d_dangerous_safe", "1", "1:more safe to use", CVAR_FLAGS);

	l4d_dangerous_power[Type_Rifle] = CreateConVar("l4d_dangerous_power_rifle", "1.1", "power of rifle 0.0: disable [0.0, 3.0]", CVAR_FLAGS);
	l4d_dangerous_power[Type_Sniper] = CreateConVar("l4d_dangerous_power_sniper", "1.8", " ", CVAR_FLAGS);
	l4d_dangerous_power[Type_Shotgun] = CreateConVar("l4d_dangerous_power_shotgun", "0.8", " ", CVAR_FLAGS);
	l4d_dangerous_power[Type_Pistol]  = CreateConVar("l4d_dangerous_power_magnum", "1.5", " ", CVAR_FLAGS);	
	l4d_dangerous_power[Type_Smg]  = CreateConVar("l4d_dangerous_power_smg", "0.5", "", CVAR_FLAGS);	

	l4d_dangerous_drop_ci  = CreateConVar("l4d_dangerous_drop_ci", "10.0", "drop chance for common infected", CVAR_FLAGS);	
	l4d_dangerous_drop_si  = CreateConVar("l4d_dangerous_drop_si", "30.0", "drop chance for special infected", CVAR_FLAGS);
	l4d_dangerous_drop_pickupcount  = CreateConVar("l4d_dangerous_drop_pickupcount", "5", "bullet count for every pick up", CVAR_FLAGS);
	
	l4d_dangerous_damage_hit  = CreateConVar("l4d_dangerous_damage_hit", "300.0", "direct hit damage", CVAR_FLAGS);	
	l4d_dangerous_damage_explode  = CreateConVar("l4d_dangerous_damage_explode", "300.0", "explode damage", CVAR_FLAGS);
	l4d_dangerous_damage_radius  = CreateConVar("l4d_dangerous_damage_radius", "10.0", "explode radius", CVAR_FLAGS);
	l4d_dangerous_particle  = CreateConVar("l4d_dangerous_particle", "1", "1:show particle , 0: disable", CVAR_FLAGS);
	l4d_dangerous_cannon_catchfire  = CreateConVar("l4d_dangerous_cannon_catchfire", "0", "1:firing cannon, 0: disable", CVAR_FLAGS);

	l4d_dangerous_flame_damage  = CreateConVar("l4d_dangerous_flame_damage", "20.0", "flame damage", CVAR_FLAGS);	
	l4d_dangerous_flame_length  = CreateConVar("l4d_dangerous_flame_length", "200.0", "flame length", CVAR_FLAGS);	
	l4d_dangerous_flame_duration  = CreateConVar("l4d_dangerous_flame_duration", "5.0", "flame duration", CVAR_FLAGS);
	
	l4d_dangerous_pickup_mode  = CreateConVar("l4d_dangerous_pickup_mode", "1", "1: pick up mode (l4d2) 2:direct give mode", CVAR_FLAGS);	

	l4d_dangerous_mode_cannon  = CreateConVar("l4d_dangerous_mode_cannon", "1", "1: enable Mini Cannon, 0: disable", CVAR_FLAGS);	
	l4d_dangerous_mode_electromagnetic  = CreateConVar("l4d_dangerous_mode_electromagnetic", "1", "1: enable Electromagnetic Cannon, 0: disable", CVAR_FLAGS);	
	l4d_dangerous_mode_flamethrower  = CreateConVar("l4d_dangerous_mode_flamethrower", "1", "1: enable Flamethrower, 0: disable", CVAR_FLAGS);	

	AutoExecConfig(true, "l4d_dangerous_weapon");   

	HookEvent("player_death", player_death); 
	HookEvent("weapon_fire", weapon_fire);
	if(!L4D2Version) HookEvent("grenade_bounce", grenade_bounce); 
	
	HookEvent("round_start", round_end);
	HookEvent("round_end", round_end);
	HookEvent("finale_win", round_end);
	HookEvent("mission_lost", round_end);
	HookEvent("map_transition", round_end);

	ResetAllState();
}

void ResetAllState()
{
	for(int i = 1; i <= MaxClients; i++)
	{
		ShowMsg[i] = 0;
		ShotTime[i] = 0.0;
		Bullet[i] = 0.0;
		Cannon[i] = 0;
		Flame[i][0] = Flame[i][1] = Flame[i][2] = 0;
		FlameStartTime[i] = 0.0;
		SDKUnhook(i, SDKHook_PreThink,  PreThinkFlame);  
	}
}

void StartElec(int client, int type)
{
	float pos[3], angle[3], hitpos[3];
	GetClientEyePosition(client, pos);
	GetClientEyeAngles(client , angle);	 
	int victim = GetEnt(client, hitpos ,MASK_SHOT);
	float distance = GetVectorDistance(pos, hitpos);
	if(l4d_dangerous_safe.IntValue == 1 && distance < l4d_dangerous_damage_radius.FloatValue * l4d_dangerous_power[type].FloatValue)
	{
		PrintHintText(client, "It is too dangerous to shoot");
		return;
	}
	CreateElec(client, pos, hitpos, angle); 

	if(victim > 0)
	{
		DoPointHurtForInfected(victim, client, l4d_dangerous_damage_hit.FloatValue * l4d_dangerous_power[type].FloatValue);
	}

	DataPack h = new DataPack();
	h.WriteCell(type);
	h.WriteFloat(hitpos[0]);
	h.WriteFloat(hitpos[1]);
	h.WriteFloat(hitpos[2]);
	CreateDataTimer(0.2, DelayExplode, h, TIMER_DATA_HNDL_CLOSE);
	Bullet[client]--;
	PrintHintText(client, "Special Bullet Remain: %d", Bullet[client] );
}

Action DelayExplode(Handle timer, DataPack h)
{
	h.Reset();
 	float pos[3];
	int type = h.ReadCell();
	pos[0] = h.ReadFloat();
	pos[1] = h.ReadFloat();
	pos[2] = h.ReadFloat();
	Explode(pos, type);
	return Plugin_Stop;
}
 
int GetEnt(int client, float hitpos[3], int flag, float offset = -50.0)
{
	float pos[3], angle[3];
	GetClientEyePosition(client, pos);
	GetClientEyeAngles(client , angle);
	Handle trace = TR_TraceRayFilterEx(pos, angle, flag, RayType_Infinite, TraceRayDontHitSelf, client); 
	int ent = -1; 
	if(TR_DidHit(trace))
	{		 
		TR_GetEndPosition(hitpos, trace);
		ent = TR_GetEntityIndex(trace); 
		float vec[3];
		GetAngleVectors(angle, vec, NULL_VECTOR, NULL_VECTOR);
		NormalizeVector(vec, vec);
		ScaleVector(vec,  offset);
		AddVectors(hitpos, vec, hitpos);
	}
	CloseHandle(trace);  
	return ent;
}

int GetEnt2(int client, float pos[3], float angle[3], float hitpos[3], int flag, float offset = -50.0)
{
	Handle trace = TR_TraceRayFilterEx(pos, angle, flag, RayType_Infinite, TraceRayDontHitSelf, client); 
	int ent = -1;
	if(TR_DidHit(trace))
	{		 
		TR_GetEndPosition(hitpos, trace);
		ent = TR_GetEntityIndex(trace); 
		float vec[3];
		GetAngleVectors(angle, vec, NULL_VECTOR, NULL_VECTOR);
		NormalizeVector(vec, vec);
		ScaleVector(vec,  offset);
		AddVectors(hitpos, vec, hitpos);
	}
	CloseHandle(trace);  
	return ent;
}

void StartFlame(int client, int type)
{ 
	StopFlame(client);
	FlameStartTime[client] = GetEngineTime();
	FlameTick[client] = 0.0;
 	FlameDamage[client] = l4d_dangerous_flame_damage.FloatValue * l4d_dangerous_power[type].FloatValue;	
	FlameLength[client] = l4d_dangerous_flame_length.FloatValue * l4d_dangerous_power[type].FloatValue;	

	char tName[32];

	Format(tName, sizeof(tName), "target%d", client);
	DispatchKeyValue(client, "targetname", tName);

	int flame = CreateEntityByName("env_steam");			
	DispatchKeyValue(flame, "parentname", tName);
	DispatchKeyValue(flame,"SpawnFlags", "1");
	DispatchKeyValue(flame,"Type", "0");		 
	DispatchKeyValue(flame,"InitialState", "1");
	DispatchKeyValue(flame,"Spreadspeed", "10");  
	DispatchKeyValue(flame,"Speed", "1000");
	DispatchKeyValue(flame,"Startsize", "4");
	DispatchKeyValue(flame,"EndSize", "100");
	DispatchKeyValue(flame,"Rate", "20");
	DispatchKeyValue(flame,"RenderColor", "255 0 0");

	char strFlameLength[32];
	IntToString(RoundFloat(FlameLength[client]), strFlameLength, 32);
	DispatchKeyValue(flame,"JetLength", strFlameLength); 
	DispatchKeyValue(flame,"RenderAmt", "180");
	DispatchSpawn(flame);

	SetVariantString(tName);
	AcceptEntityInput(flame, "SetParent", flame, flame, 0);
	SetVariantString("forward");
	AcceptEntityInput(flame, "SetParentAttachment", flame, flame, 0);
	AcceptEntityInput(flame, "TurnOn");

	float pos[3], ang[3]; 	
	SetVector(pos,  22.0, 0.0, -15.0);	
	SetVector(ang, -3.0, 8.0,0.0);	
	TeleportEntity(flame, pos, ang, NULL_VECTOR);

	int flame2 = CreateEntityByName("env_steam");
	DispatchKeyValue(flame2, "parentname", tName);
	DispatchKeyValue(flame2,"SpawnFlags", "1");
	DispatchKeyValue(flame2,"Type", "0");		 
	DispatchKeyValue(flame2,"InitialState", "1");
	DispatchKeyValue(flame2,"Spreadspeed", "10"); 
	DispatchKeyValue(flame2,"Speed", "1000");
	DispatchKeyValue(flame2,"Startsize", "10");
	DispatchKeyValue(flame2,"EndSize", "140");
	DispatchKeyValue(flame2,"Rate", "95");
	DispatchKeyValue(flame2,"RenderColor", "16 85 160");

	DispatchKeyValue(flame2,"JetLength", strFlameLength); 
	DispatchKeyValue(flame2,"RenderAmt", "180");
	DispatchSpawn(flame2); 

	SetVariantString(tName);
	AcceptEntityInput(flame2, "SetParent", flame2, flame2, 0);
	SetVariantString("forward");
	AcceptEntityInput(flame2, "SetParentAttachment", flame2, flame2, 0);
	AcceptEntityInput(flame2, "TurnOn");	 

	TeleportEntity(flame2, pos, ang, NULL_VECTOR);

	Flame[client][0]=flame;
	Flame[client][1]=flame2;

	EmitSoundToAll(SOUND_FLAME, client, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, 1.0, SNDPITCH_NORMAL, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
	SDKUnhook(client, SDKHook_PreThink,  PreThinkFlame);  
	SDKHook(client, SDKHook_PreThink,  PreThinkFlame);  
	Bullet[client]--;
	PrintHintText(client, "Special Bullet Remain: %d", Bullet[client] );
}

void StopFlame(int client)
{  
	if(client > 0)
	{
		SDKUnhook(client, SDKHook_PreThink,  PreThinkFlame);  
		StopSound(client, SNDCHAN_AUTO, SOUND_FLAME);
		if(IsValidEntS(Flame[client][0], "env_steam"))
		{
			AcceptEntityInput(Flame[client][0], "ClearParent");
			AcceptEntityInput(Flame[client][0], "TurnOff");
			AcceptEntityInput(Flame[client][0], "kill");
			 
		}
		if(IsValidEntS(Flame[client][1], "env_steam"))
		{
			AcceptEntityInput(Flame[client][1], "ClearParent");
			AcceptEntityInput(Flame[client][1], "TurnOff");
			AcceptEntityInput(Flame[client][1], "kill");
		}
		Flame[client][0] = Flame[client][1] = 0;
	}
}

bool IsValidEntS(int ent, char classname[64])
{
	if(IsValidEnt(ent))
	{ 
		char name[64]; 
		GetEdictClassname(ent, name, 64); 
		if(StrEqual(classname, name) )
		{
			return true;
		}
	}
	return false;
}

bool IsValidEnt(int ent)
{
	return ent > 0 && IsValidEdict(ent) && IsValidEntity(ent);
}

float g_flame_radius = 50.0;
void PreThinkFlame(int client)
{
	if(client > 0 && IsClientInGame(client) && IsPlayerAlive(client))
	{
		float time = GetEngineTime();
		int button = GetClientButtons(client);
		if(FlameStartTime[client] + l4d_dangerous_flame_duration.FloatValue < time )
		{
			StopFlame(client);
			return;
		}
		float eyepos[3], startpos[3], endpos[3], angle[3], dir[3], temp[3];
		GetClientEyePosition(client, eyepos);
		GetClientEyeAngles(client, angle);	 
		GetAngleVectors(angle, dir, NULL_VECTOR, NULL_VECTOR);
		NormalizeVector(dir, dir);
		CopyVector(dir, temp);
		ScaleVector(temp, g_flame_radius/2.0+20.0);
		AddVectors(eyepos, temp, startpos);

		CopyVector(dir, temp);
		ScaleVector(temp, FlameLength[client]);
		AddVectors(startpos, temp, endpos);

		Handle trace = TR_TraceRayFilterEx(startpos, endpos, MASK_SOLID, RayType_EndPoint, TraceRayDontHitLive, client);
		if(TR_DidHit(trace))
		{		 
			TR_GetEndPosition(endpos, trace);  
		}
		CloseHandle(trace); 
		float len = GetVectorDistance(endpos, startpos);
		if(FlameTick[client] > len) FlameTick[client] = 0.0;

		CopyVector(dir, temp);
		ScaleVector(temp, FlameTick[client]);
		AddVectors(startpos, temp, temp);

		int fire = 0;
		if(button & IN_ATTACK) fire = 1;

		if(FlameTick[client] == 0.0) HurtPositon(client, temp, g_flame_radius / 2.0, FlameDamage[client], fire);
		else HurtPositon(client, temp, g_flame_radius, FlameDamage[client], fire);
		
		float up[3];
		up[2] = 1.0;
	
		FlameTick[client] += g_flame_radius / 2.0;
	}
	else StopFlame(client);
}

void HurtPositon(int client, float pos[3], float radius, float damage, int fire)
{
	int pointHurt = CreateEntityByName("point_hurt"); 
	DispatchKeyValueFloat(pointHurt, "DamageRadius", radius); 

	if(fire == 1)
	{
		DispatchKeyValueFloat(pointHurt, "Damage", damage); 
		DispatchKeyValue(pointHurt, "DamageType", "8"); 
	}
	else
	{
		DispatchKeyValueFloat(pointHurt, "Damage", damage*2.0); 
		DispatchKeyValue(pointHurt, "DamageType", "64"); 
	}
	DispatchKeyValue(pointHurt, "DamageDelay", "0.0"); 
	DispatchSpawn(pointHurt);
	TeleportEntity(pointHurt, pos, NULL_VECTOR, NULL_VECTOR); 
	AcceptEntityInput(pointHurt, "Hurt", client); 
	AcceptEntityInput(pointHurt, "Kill"); 	
}

void StartCannon(int client, int type)
{
	float pos[3], hitpos[3], dir[3], angle[3], temp[3];
	GetClientEyePosition(client, pos);
	GetClientEyeAngles(client , angle);	

	float newpos[3], right[3];
	GetAngleVectors(angle, NULL_VECTOR, right, NULL_VECTOR);
	NormalizeVector(right, right);
	ScaleVector(right, 9.0);
	AddVectors(pos, right, newpos);	

	GetAngleVectors(angle, dir, NULL_VECTOR, NULL_VECTOR);
	NormalizeVector(dir, dir);
	CopyVector(dir,temp);
	ScaleVector(temp, 40.0);
	AddVectors(newpos, temp,newpos);

	int victim = GetEnt2(client, newpos, angle, hitpos, MASK_ALL); 
	if(victim != -1 && l4d_dangerous_safe.IntValue == 1)
	{
		float distance = GetVectorDistance(pos, hitpos);
		if(distance < l4d_dangerous_damage_radius.FloatValue * l4d_dangerous_power[type].FloatValue)
		{
			PrintHintText(client, "It is too dangerous to shoot");
			return;
		}	
	}   
	int ent = CreateGLprojectile(client, type, newpos, dir, 300.0);
	if(L4D2Version)	SDKHook(ent, SDKHook_StartTouch , GLprojectileTouch);  
	else 
	{
		SetEntPropEnt(ent, Prop_Data, "m_hOwnerEntity", client)	;
		if(Cannon[client] > 0 && IsValidEdict(Cannon[client]) && IsValidEntity(Cannon[client]))
		{
			AcceptEntityInput(Cannon[client], "kill");
		}
		Cannon[client]=ent;
	}

	Bullet[client]--;
	PrintHintText(client, "Special Bullet Remain: %d", Bullet[client] );
}

Action grenade_bounce(Event h_Event, const char[] s_Name, bool b_DontBroadcast)
{ 
	int client = GetClientOfUserId(h_Event.GetInt("userid"));
	if(client > 0)
	{
		if(Cannon[client] > 0 && IsValidEdict(Cannon[client]) && IsValidEntity(Cannon[client]))
		{
			float pos[3];
			GetEntPropVector(Cannon[client], Prop_Send, "m_vecOrigin", pos); 		
			AcceptEntityInput(Cannon[client], "kill");

			float f = GetEntPropFloat(Cannon[client], Prop_Send, "m_fadeMaxDist");
			int data = RoundFloat(f);
			int type = data / 10000; 
			Explode(pos, type);  
		}
		Cannon[client] = 0;
	}
	return Plugin_Continue;
}

void GLprojectileTouch(int ent, int other)
{ 
  	float f = GetEntPropFloat(ent, Prop_Send, "m_fadeMaxDist");
	int data = RoundFloat(f);
	int type = data / 10000;
	int client = data % 10000;
	
	bool explode = true;
	if(other > 0 && IsValidEdict(other) && IsValidEntity(other))
	{		
		DoPointHurtForInfected(other, client,  l4d_dangerous_damage_hit.FloatValue * l4d_dangerous_power[type].FloatValue);
	}
	if(explode || other == 0)
	{
		SDKUnhook(ent, SDKHook_StartTouch, GLprojectileTouch);
		float pos[3];
		GetEntPropVector(ent, Prop_Send, "m_vecOrigin", pos); 
		AcceptEntityInput(ent, "kill");
		Explode(pos, type );  
	}
}

void CreateElec(int client, float pos[3], float endpos[3], float angle[3])
{
	if(L4D2Version)
	{
		char tname1[10], tname2[10]; 

		for(int i = 0; i < 1; i++)
		{
			int ent = CreateEntityByName("info_particle_target"); 
			DispatchSpawn(ent);  
			TeleportEntity(ent, endpos, NULL_VECTOR, NULL_VECTOR); 
			
			Format(tname1, sizeof(tname1), "target%d", client);
			Format(tname2, sizeof(tname1), "target%d", ent);
			DispatchKeyValue(client, "targetname", tname1);
			DispatchKeyValue(ent, "targetname", tname2);

			int particle = CreateEntityByName("info_particle_system");
			DispatchKeyValue(particle, "effect_name",  Particle_st_elmos_fire ); //st_elmos_fire fire_jet_01_flame
			DispatchKeyValue(particle, "cpoint1", tname2);
			DispatchKeyValue(particle, "parentname", tname1);
			DispatchSpawn(particle);
			ActivateEntity(particle); 
			SetVariantString(tname1);
			AcceptEntityInput(particle, "SetParent",particle, particle, 0);   
			SetVariantString("muzzle_flash"); 
			AcceptEntityInput(particle, "SetParentAttachment");
			float v[3];
			SetVector(v, 0.0,  0.0,  0.0);  
			TeleportEntity(particle, v, NULL_VECTOR, NULL_VECTOR); 
			AcceptEntityInput(particle, "start");  
			CreateTimer(1.0, DeleteParticles, particle);
			CreateTimer(0.5, DeleteParticletargets, ent);
			ShowParticle(endpos, NULL_VECTOR, Particle_electrical_arc_01_system, 3.0);
		}
	}
	else
	{
		float newpos[3], right[3];
		GetAngleVectors(angle, NULL_VECTOR, right, NULL_VECTOR);
		NormalizeVector(right, right);
		ScaleVector(right, 7.0);
		AddVectors(pos, right, newpos);	
		int color[4];
		color[0] = 255;
		color[3] = 255;
		 
		TE_SetupBeamPoints(newpos, endpos, g_sprite, 0, 0, 0, 0.1, 5.0, 5.0, 1, 0.0, color, 0);
		TE_SendToAll();
	}
}

int CreateGLprojectile(int client, int type, float pos[3], float dir[3], float velocity = 1000.0, float gravity = 0.01, float modelScale = 3.5)
{
	if(type == Type_Pistol) velocity = 700.0;
	else if(type == Type_Rifle) velocity = 600.0;
	else if(type == Type_Shotgun) velocity = 460.0;
	else if(type == Type_Sniper) velocity = 1000.0;
	else if(type == Type_Smg) velocity = 500.0;
	 
	float v[3];
	CopyVector(dir, v);
	NormalizeVector(v,v);
	ScaleVector(v, velocity);
	int ent = 0;
	if(L4D2Version)
	{
		ent = CreateEntityByName("grenade_launcher_projectile");	
		DispatchKeyValue(ent, "model", MODEL_MISSILE); 
	}
	else
	{
		ent = CreateEntityByName("molotov_projectile");	
		DispatchKeyValue(ent, "model", "models/w_models/weapons/w_eq_molotov.mdl"); 
	}
	
	gravity = 0.5;
	SetEntityGravity(ent, gravity);  
	DispatchSpawn(ent);
	ActivateEntity(ent);

	float ang[3];
	GetVectorAngles(dir, ang);
	ang[0] += 90.0;
	TeleportEntity(ent, pos, ang, v);

	if(L4D2Version)
	{
		SetEntProp(ent, Prop_Send, "m_iGlowType", 3);
		SetEntProp(ent, Prop_Send, "m_nGlowRange", 0);
		SetEntProp(ent, Prop_Send, "m_nGlowRangeMin", 10);
		SetEntProp(ent, Prop_Send, "m_glowColorOverride", 255);
		SetEntPropFloat(ent, Prop_Send, "m_flModelScale", modelScale * l4d_dangerous_power[type].FloatValue);	
	}
	else
	{
		SetEntPropEnt(ent, Prop_Data, "m_hOwnerEntity", client);
 	}

	SetEntPropFloat(ent, Prop_Send, "m_fadeMinDist", 20000.0); 
	float data = (client + type * 10000) * 1.0;
	SetEntPropFloat(ent, Prop_Send, "m_fadeMaxDist", data);   

	if(L4D2Version && l4d_dangerous_cannon_catchfire.IntValue == 1)
	{
		char tname2[20]; 
		Format(tname2, sizeof(tname2), "missile%d", ent);
		DispatchKeyValue(ent, "targetname", tname2); 	
		int particle = CreateEntityByName("info_particle_system");
		DispatchKeyValue(particle, "effect_name", Particle_jet_01_flame); //st_elmos_fire fire_jet_01_flame
		DispatchKeyValue(particle, "parentname", tname2);
		DispatchSpawn(particle);
		ActivateEntity(particle); 
		TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);

		SetVariantString(tname2);
		AcceptEntityInput(particle, "SetParent",particle, particle, 0);   
		AcceptEntityInput(particle, "start"); 
	}
	
	return ent;
}

void DropBullet(int victim, int attacker)
{
	if(victim > 0 && IsValidEdict(victim) && IsValidEntity(victim))
	{ 
		float pos[3], vel[3];
		GetEntPropVector(victim, Prop_Send, "m_vecOrigin", pos); 
		pos[2] += 50.0;

		int ent = CreateEntityByName("grenade_launcher_projectile");	
		DispatchKeyValue(ent, "model", MODEL_MISSILE); 
		SetEntityGravity(ent, 0.1); 
		SetEntityMoveType(ent, MOVETYPE_NONE);
		DispatchSpawn(ent);  
		SetEntPropFloat(ent, Prop_Send,"m_flModelScale",3.0);	 

		SetVector(vel, GetRandomFloat(-10.0, 10.0), GetRandomFloat(-10.0, 10.0), GetRandomFloat(-10.0, 10.0));
		SetVector(vel, 0.0,0.0, 20.0);
		TeleportEntity(ent, pos, NULL_VECTOR, vel);

		SetEntProp(ent, Prop_Send, "m_iGlowType", 3);
		SetEntProp(ent, Prop_Send, "m_nGlowRange", 0);
		SetEntProp(ent, Prop_Send, "m_nGlowRangeMin", 10);
		SetEntProp(ent, Prop_Send, "m_glowColorOverride", 0+200*256);

		SetEntPropFloat(ent, Prop_Send, "m_fadeMinDist", 20000.0); 
		float data = (attacker + 10000) * 1.0;
		SetEntPropFloat(ent, Prop_Send, "m_fadeMaxDist", data);  

		int button = CreateButton(ent);
		SetEntPropFloat(button, Prop_Send, "m_fadeMaxDist", ent * 1.0);   
		CreateTimer(60.0, TimerKillDrop, EntIndexToEntRef(ent), TIMER_FLAG_NO_MAPCHANGE);
	}
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	if(damagetype & (DMG_BLAST|DMG_GENERIC))
	{
		damage /= 0.0;
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

Action TimerKillDrop(Handle timer, any ent)
{
	if(ent != INVALID_ENT_REFERENCE && IsValidEntity(ent) && IsValidEdict(ent))
	{
		AcceptEntityInput(ent, "kill");
	}
	return Plugin_Stop;
} 
 
void Explode(float pos[3], int type)
{
	float power = l4d_dangerous_power[type].FloatValue;
	float radius = l4d_dangerous_damage_radius.FloatValue * power;
	float damage = l4d_dangerous_damage_explode.FloatValue * power;

	int ent1 = 0;		
	int ent2 = 0;
	int ent3 = 0;
	if(power >= 0.6)
	{
		ent1 = CreateEntityByName("prop_physics"); 
		DispatchKeyValue(ent1, "model", "models/props_junk/propanecanister001a.mdl"); 
		DispatchSpawn(ent1); 
		TeleportEntity(ent1, pos, NULL_VECTOR, NULL_VECTOR);
		AcceptEntityInput(ent1, "break");
	}
	if(power >= 1.3)
	{
		ent2 = CreateEntityByName("prop_physics"); 	
		DispatchKeyValue(ent2, "model", "models/props_junk/propanecanister001a.mdl"); 
		DispatchSpawn(ent2); 
		TeleportEntity(ent2, pos, NULL_VECTOR, NULL_VECTOR);
		AcceptEntityInput(ent2, "break");
	}
	if(power >= 1.5)
	{
		ent3 = CreateEntityByName("prop_physics"); 
		DispatchKeyValue(ent3, "model", "models/props_junk/propanecanister001a.mdl"); 
		DispatchSpawn(ent3); 
		TeleportEntity(ent3, pos, NULL_VECTOR, NULL_VECTOR);
		AcceptEntityInput(ent3, "break");
	}	

	int pointHurt = CreateEntityByName("point_hurt");    	
	DispatchKeyValueFloat(pointHurt, "Damage", damage);        
	DispatchKeyValueFloat(pointHurt, "DamageRadius", radius);   
	if(L4D2Version)	DispatchKeyValue(pointHurt, "DamageType", "64"); 
	else DispatchKeyValue(pointHurt, "DamageType", "64"); 
	DispatchKeyValue(pointHurt, "DamageDelay", "0.0");   
	DispatchSpawn(pointHurt);
	TeleportEntity(pointHurt, pos, NULL_VECTOR, NULL_VECTOR);  
	AcceptEntityInput(pointHurt, "Hurt");    
	CreateTimer(0.1, DeletePointHurt, pointHurt); 

	int push = CreateEntityByName("point_push");         
	DispatchKeyValueFloat(push, "magnitude",damage*2.0);                     
	DispatchKeyValueFloat(push, "radius", radius);                     
	SetVariantString("spawnflags 24");                     
	AcceptEntityInput(push, "AddOutput");
	DispatchSpawn(push);   
	TeleportEntity(push, pos, NULL_VECTOR, NULL_VECTOR);  
	AcceptEntityInput(push, "Enable");
	CreateTimer(0.5, DeletePushForce, push);   
	
	if(l4d_dangerous_particle.IntValue == 1)
	{
		if(power<1.7)ShowParticle(pos, NULL_VECTOR,Particle_gas_explosion_pump  , 1.0);	
		else ShowParticle(pos, NULL_VECTOR, Particle_gas_explosion_main , 1.0);	//gas_explosion_main
	}
}

Action weapon_fire(Event event, const char[] name, bool dontBroadcast)
{
	if(CanUse())
	{
		int client = GetClientOfUserId(event.GetInt("userid"));
		if(client > 0 && IsClientInGame(client) && GetClientTeam(client) == 2)
		{
			int button = GetClientButtons(client);
			if(button & IN_USE )
			{
				float Time = GetEngineTime();
				if(Time >= ShotTime[client] + 1.0)
				{
					char item[65];
					int type = 0;
					event.GetString("weapon", item, 65);
					if(l4d_dangerous_power[Type_Shotgun].FloatValue > 0.0 && StrContains(item, "shot") >= 0) type = Type_Shotgun;
					else if(l4d_dangerous_power[Type_Smg].FloatValue > 0.0 && StrContains(item, "smg") >= 0) type = Type_Smg;
					else if(l4d_dangerous_power[Type_Sniper].FloatValue > 0.0 && (StrContains(item, "sniper") >= 0 || StrContains(item, "hunting") >= 0)) type = Type_Sniper;
					else if(l4d_dangerous_power[Type_Rifle].FloatValue > 0.0 && StrContains(item, "rifle") >= 0) type = Type_Rifle; 				
					else if(l4d_dangerous_power[Type_Pistol].FloatValue > 0.0 && StrContains(item, "magnum") >=0) type = Type_Pistol;

					if(type > 0)				
					{  
						int cannon = l4d_dangerous_mode_cannon.IntValue;
						int ecannon = l4d_dangerous_mode_electromagnetic.IntValue;
						int flame = l4d_dangerous_mode_flamethrower.IntValue;

						if(Bullet[client] > 0)
						{
							if((button & IN_DUCK))
							{
								if(ecannon == 1) StartElec(client, type);
							}
							else if((button & IN_SPEED))
							{
								if(flame == 1) StartFlame(client, type);
							}
							else
							{
								if(cannon == 1) StartCannon(client, type);
							}
						} 
						else
						{
							PrintHintText(client, "Please kill infected to get more bullets");
						}
					}
					ShotTime[client] = Time; 
				}
			}
		}
	}
	return Plugin_Continue;
}
 
Action player_death(Event hEvent, const char[] strName, bool DontBroadcast)
{ 
	if(CanUse())
	{
		int victim = GetClientOfUserId(hEvent.GetInt("userid"));
		int attacker = GetClientOfUserId(hEvent.GetInt("attacker"));
		int entityid = hEvent.GetInt("entityid") ; 
		if(attacker > 0)
		{
			if(victim > 0)
			{		
				if(GetRandomFloat(0.0, 100.0) < l4d_dangerous_drop_si.FloatValue)
				{
					if(L4D2Version && l4d_dangerous_pickup_mode.IntValue == 1) DropBullet(victim, attacker);
					else GiveBullet(victim, attacker);
				}
				Bullet[victim] = 3.0;
				StopFlame(victim);
				ResetPlayer(victim);
			}
			else if(entityid > 0)
			{
				if(GetRandomFloat(0.0, 100.0) < GetConVarFloat(l4d_dangerous_drop_ci))
				{
					if(L4D2Version && l4d_dangerous_pickup_mode.IntValue == 1) DropBullet(entityid, attacker);
					else GiveBullet(entityid, attacker);
				}
			}
		}
	}
	return Plugin_Continue;	 
}

int Kills[MAXPLAYERS + 1] = {0, ...};

Action round_end(Event event, const char[] name, bool dontBroadcast)
{
	ResetAllState();
	return Plugin_Continue;
}

void ResetPlayer(int client)
{
	Bullet[client] = 0.0;
	Cannon[client] = 0;
	Flame[client][0] = Flame[client][1] = Flame[client][2] = 0;
	Kills[client] = 0;
}

public void OnMapStart()
{
	PrecacheModel(MODEL_W_PIPEBOMB);
	PrecacheModel("models/props_junk/propanecanister001a.mdl", true);
	PrecacheParticle(Particle_gas_explosion_pump);
	PrecacheParticle(Particle_gas_explosion_main);
	PrecacheSound(SOUND_FLAME, true);
	if(L4D2Version)
	{
		g_sprite = PrecacheModel("materials/sprites/laserbeam.vmt");	
		PrecacheModel(MODEL_MISSILE);
		PrecacheParticle(Particle_jet_01_flame);
		PrecacheParticle(Particle_st_elmos_fire);
		PrecacheParticle(Particle_electrical_arc_01_system);
	}
	else
	{
		g_sprite = PrecacheModel("materials/sprites/laser.vmt");
	}
	g_sprite = g_sprite + 0;
}

bool CanUse()
{
 	bool mode = l4d_dangerous_enable.BoolValue;
	if(!mode) return false;
	if(mode && GameMode == 2) return false;
	return true;
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

Action DeletePointHurt(Handle timer, any ent)
{
	if (ent> 0 && IsValidEntity(ent) && IsValidEdict(ent))
	{
		char classname[64];
		GetEdictClassname(ent, classname, sizeof(classname));
		if (StrEqual(classname, "point_hurt", false))
		{
			AcceptEntityInput(ent, "Kill"); 
			RemoveEdict(ent);
		}
	}
	return Plugin_Stop;
}

Action DeletePushForce(Handle timer, any ent)
{
	if (ent > 0 && IsValidEntity(ent) && IsValidEdict(ent))
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
	return Plugin_Stop;
}

void PrecacheParticle(char[] particlename)
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

Action DeleteParticles(Handle timer, any particle)
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
	return Plugin_Stop;
}

int ShowParticle(float pos[3], float ang[3], char[] particlename, float time)
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

Action DeleteParticletargets(Handle timer, any target)
{
	if (IsValidEntity(target))
	{
		char classname[64];
		GetEdictClassname(target, classname, sizeof(classname));
		if (StrEqual(classname, "info_particle_target", false))
		{
			AcceptEntityInput(target, "stop");
			AcceptEntityInput(target, "kill");
			RemoveEdict(target);
		}
	}
	return Plugin_Stop;
}

//code modify from  "[L4D & L4D2] Extinguisher and Flamethrower", SilverShot;
int CreateButton(int entity)
{ 
	char sTemp[16];
	int button;
	bool type = false;
	if(type) button = CreateEntityByName("func_button");
	else button = CreateEntityByName("func_button_timed"); 

	Format(sTemp, sizeof(sTemp), "target%d",  button );
	DispatchKeyValue(entity, "targetname", sTemp);
	DispatchKeyValue(button, "glow", sTemp);
	DispatchKeyValue(button, "rendermode", "3");
 
	if(type )
	{
		DispatchKeyValue(button, "spawnflags", "1025");
		DispatchKeyValue(button, "wait", "1");
	}
	else
	{
		DispatchKeyValue(button, "spawnflags", "0");
		DispatchKeyValue(button, "auto_disable", "1");
		Format(sTemp, sizeof(sTemp), "%f", 1.0);
		DispatchKeyValue(button, "use_time", sTemp);
	}
	DispatchSpawn(button);
	AcceptEntityInput(button, "Enable");
	ActivateEntity(button);

	Format(sTemp, sizeof(sTemp), "ft%d", button);
	DispatchKeyValue(entity, "targetname", sTemp);
	SetVariantString(sTemp);
	AcceptEntityInput(button, "SetParent", button, button, 0);
	TeleportEntity(button, view_as<float>({0.0, 0.0, 0.0}), NULL_VECTOR, NULL_VECTOR);

	SetEntProp(button, Prop_Send, "m_nSolidType", 0, 1);
	SetEntProp(button, Prop_Send, "m_usSolidFlags", 4, 2);

	float vMins[3] = {-5.0, -5.0, -5.0}, vMaxs[3] = {5.0, 5.0, 5.0};
	SetEntPropVector(button, Prop_Send, "m_vecMins", vMins);
	SetEntPropVector(button, Prop_Send, "m_vecMaxs", vMaxs);

	if( L4D2Version )
	{
		SetEntProp(button, Prop_Data, "m_CollisionGroup", 1);
		SetEntProp(button, Prop_Send, "m_CollisionGroup", 1);
	}

	if(type)
	{	
		HookSingleEntityOutput(button, "OnPressed", OnPressed);
	}
	else
	{
		SetVariantString("OnTimeUp !self:Enable::1:-1");
		AcceptEntityInput(button, "AddOutput");
		HookSingleEntityOutput(button, "OnTimeUp", OnPressed);
	}
	return button;
}

public void OnPressed(const char[] output, int caller, int activator, float delay)
{ 
	//PrintToChatAll("%N pick up", activator);
	float f = GetEntPropFloat(caller, Prop_Send, "m_fadeMaxDist");	
	int ent = RoundFloat(f); 
	f = GetEntPropFloat(ent, Prop_Send, "m_fadeMaxDist");	
	//PrintToChatAll("pick up ent %d onwer %N", ent, owner); 
	AcceptEntityInput(ent, "kill");  
	if(activator > 0 && activator <= MaxClients && IsClientInGame(activator))
	{ 
		Bullet[activator] += l4d_dangerous_drop_pickupcount.IntValue;
		PrintHintText(activator, "You pick up some special bullets, Total:%d", Bullet[activator]);
		if(ShowMsg[activator] < l4d_dangerous_message.IntValue)
		{
			PrintUsageMessage(activator);
			ShowMsg[activator]++;
		}
	}
}

stock void GiveBullet(int victim, int attacker)
{
	if(attacker > 0 && attacker <= MaxClients && IsClientInGame(attacker))
	{
		Bullet[attacker] += l4d_dangerous_drop_pickupcount.IntValue;
		PrintHintText(attacker, "You get some special bullets, Total:%d", Bullet[attacker]);
		if(ShowMsg[attacker] < l4d_dangerous_message.IntValue)
		{
			PrintUsageMessage(attacker);
			ShowMsg[attacker]++;
		}
	}
}

void PrintUsageMessage(int client)
{
	char buffer[320] = "";
	if(l4d_dangerous_power[Type_Shotgun].FloatValue > 0.0) Format(buffer, sizeof(buffer), "%s Shotgun", buffer) ;
	if(l4d_dangerous_power[Type_Rifle].FloatValue > 0.0) Format(buffer, sizeof(buffer), "%s Rifle", buffer) ;
	if(l4d_dangerous_power[Type_Sniper].FloatValue > 0.0) Format(buffer, sizeof(buffer), "%s Sniper", buffer) ;
	if(l4d_dangerous_power[Type_Pistol].FloatValue > 0.0) Format(buffer, sizeof(buffer), "%s Magnum", buffer) ;
	if(l4d_dangerous_power[Type_Smg].FloatValue > 0.0) Format(buffer, sizeof(buffer), "%s Smg", buffer) ;
	PrintToChat(client, "\x01Use \x04E%s \x03 to shot special bullets", buffer);
	if(l4d_dangerous_mode_cannon.BoolValue) PrintToChat(client, "\x01Mini Cannon: \x04E+Fire");
	if(l4d_dangerous_mode_electromagnetic.BoolValue) PrintToChat(client, "\x01Electromagnetic Cannon: \x04Duck+E+Fire ");
	if(l4d_dangerous_mode_flamethrower.BoolValue) PrintToChat(client, "\x01Flamethrower:\x04Walk+E+Fire ");
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
void DoPointHurtForInfected(int victim, int attacker = 0, float FireDamage)
{
	int g_PointHurt = CreatePointHurt();		
	Format(N, 20, "target%d", victim);
	DispatchKeyValue(victim,"targetname", N);
	DispatchKeyValue(g_PointHurt,"DamageTarget", N); 
 	DispatchKeyValueFloat(g_PointHurt,"Damage", FireDamage);
	if(L4D2Version) DispatchKeyValueFloat(g_PointHurt,"Damage", FireDamage);
	else
	{
		if(float(GetEntProp(victim, Prop_Data, "m_iHealth")) * 1.0 <= FireDamage)  DispatchKeyValue(g_PointHurt, "DamageType", "64");
		else  DispatchKeyValue(g_PointHurt, "DamageType", "-1073741822"); 
	}
	AcceptEntityInput(g_PointHurt,"Hurt",(attacker>0)?attacker:-1);
	AcceptEntityInput(g_PointHurt,"kill" ); 
}

bool TraceRayDontHitSelf(int entity, int mask, any data)
{
	return entity != data;
}

bool TraceRayDontHitLive(int entity, int mask, any data)
{
	if(entity > 0 && entity > MaxClients && entity != data) 
	{
		char edictname[128];
		GetEdictClassname(entity, edictname, 128);
		if(!StrEqual(edictname, "infected")) return true;
	}
	return false;
}

stock void ShowLaser(int colortype, float pos1[3], float pos2[3], float life = 10.0, float width1 = 1.0, float width2 = 11.0)
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
stock void ShowPos(int color, float pos1[3], float pos2[3], float life = 10.0, float length = 200.0, float width1 = 1.0, float width2 = 11.0)
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
	ShowLaser(color,pos1, t, life,   width1, width2);
}

//draw line start from pos, the line's drection is dir.
stock void ShowDir(int color, float pos[3], float dir[3], float life = 10.0, float length = 200.0, float width1 = 1.0, float width2 = 11.0)
{
	float pos2[3];
	CopyVector(dir, pos2);
	NormalizeVector(pos2,pos2);
	ScaleVector(pos2, length);
	AddVectors(pos, pos2,pos2);
	ShowLaser(color,pos, pos2, life,   width1, width2);
}

//draw line start from pos, the line's angle is angle.
stock void ShowAngle(int color, float pos[3], float angle[3], float life = 10.0, float length = 200.0, float width1 = 1.0, float width2 = 11.0)
{
	float pos2[3];
	GetAngleVectors(angle, pos2, NULL_VECTOR, NULL_VECTOR); 
	NormalizeVector(pos2,pos2);
	ScaleVector(pos2, length);
	AddVectors(pos, pos2,pos2);
	ShowLaser(color,pos, pos2, life, width1, width2);
}
