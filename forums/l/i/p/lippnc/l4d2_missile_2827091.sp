#pragma newdecls required
#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdktools_functions>
#include <sdkhooks>

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

Handle l4d2_missile_enable;
Handle l4d2_missile_radius;
Handle l4d2_missile_damage;
Handle l4d2_missile_damage_tosurvivor;
Handle l4d2_missile_push;
Handle l4d2_missile_limit;
Handle l4d2_missile_kills;
Handle l4d2_missile_safe;
Handle l4d2_missile_tracefactor;
Handle l4d2_missile_radar_range;

Handle l4d2_missile_infected_smoker; 
Handle l4d2_missile_infected_charger;
Handle l4d2_missile_infected_spitter;
Handle l4d2_missile_infected_boomer;
Handle l4d2_missile_infected_hunter;  
Handle l4d2_missile_infected_witch;  
Handle l4d2_missile_infected_tank_throw;
Handle l4d2_missile_infected_anti; 

Handle l4d2_missile_weapon_rifle;
Handle l4d2_missile_weapon_sniper;
Handle l4d2_missile_weapon_shotgun;
Handle l4d2_missile_weapon_magnum;
Handle l4d2_missile_weapon_smg;
Handle l4d2_missile_weapon_pistol;
Handle l4d2_missile_weapon_grenade;

bool gamestart=false;
bool Hooked[MAXPLAYERS+1];

int MissileCount[MAXPLAYERS+1];
int MissileEntity[MAXPLAYERS+1];
int MissileFlame[MAXPLAYERS+1];
int MissileOwner[MAXPLAYERS+1];
int MissileTeams[MAXPLAYERS+1];
int MissleModel[MAXPLAYERS+1];
int MissileType[MAXPLAYERS+1]; 
int MissileEnemy[MAXPLAYERS+1];
int ShowMsg[MAXPLAYERS+1];
int g_iVelocity;
int L4D2Version;
int GameMode;
int g_sprite;

float LastUseTime[MAXPLAYERS+1];
float LastTime[MAXPLAYERS+1];
float modeloffset=50.0; //180.0 normal
float MissileScanTime[MAXPLAYERS+1];
float PrintTime[MAXPLAYERS+1];
float missilespeed_trace=250.0;  
float missilespeed_trace2=180.0;
float missilespeed_normal=800.0; //500

public Plugin myinfo = 
{
	name = "L4D2 Missiles Galore",
	author = "Pan Xiaohai",
	description = "Missiles for weapons in L4D & L4D2",
	version = "2.0",
	url = "http://expmapsl4d2.site.nfoservers.com/"
} 

public void OnPluginStart()
{ 
	l4d2_missile_enable = CreateConVar("l4d2_missile_enable", "0", "Enable missile plugin. (0=Disabled, 1=Enabled)");
 	l4d2_missile_radius = CreateConVar("l4d2_missile_radius", "200.0", "Missile explode radius. [Min=100.0,  Max=500.0]");
	l4d2_missile_damage = CreateConVar("l4d2_missile_damage", "500.0", "Missile damage to special infected. [Min=100.0,  Max=3000.0]");
	l4d2_missile_damage_tosurvivor = CreateConVar("l4d2_missile_damage_tosurvivor", "0.0", "Missile damage to survivors. [Min=0.0,  Max=100.0]");
	l4d2_missile_push = CreateConVar("l4d2_missile_push", "1200.0", "Push force of missile explosion. [Min=0.0,  Max=2000.0]");	
	l4d2_missile_safe = CreateConVar("l4d2_missile_safe", "1", "0:Normal chance to hurt survivor, 1:Less chance to hurt survivor");
	
	l4d2_missile_infected_smoker = CreateConVar("l4d2_missile_infected_smoker", "0.0", "Smoker launches a missile when draggin a survivor. [0.0, 30.0]%");
	l4d2_missile_infected_charger = CreateConVar("l4d2_missile_infected_charger", "0.0", "Charger launches 	a missile when charging a survivor. [0.0, 30.0]%");
	l4d2_missile_infected_spitter = CreateConVar("l4d2_missile_infected_spitter", "0.0", "Spitter launches a missile when spitter spits on a survivor. [0.0, 30.0]%");
	l4d2_missile_infected_hunter = CreateConVar("l4d2_missile_infected_hunter", "0.0", "Hunter launches a missile when hunter pounces survivor. [0.0, 30.0]%");
	l4d2_missile_infected_boomer = CreateConVar("l4d2_missile_infected_boomer", "0.0", "Boomer launches missile when boomer booms a survivor. [0.0, 30.0]%");
	l4d2_missile_infected_witch = CreateConVar("l4d2_missile_infected_witch", "0.0", "Witch launches missile when witch is startled by survivor. [0.0, 30.0]%");
 	l4d2_missile_infected_tank_throw = CreateConVar("l4d2_missile_infected_tank_throw", "0.0", "Launch missile when tank throws rock at a survivor. [0.0, 30.0]%");	
	l4d2_missile_infected_anti = CreateConVar("l4d2_missile_infected_anti", "0.0", "Infected launch a missile when a survivor launches a missile. [0.0, 30.0]%");
	
	l4d2_missile_weapon_rifle = CreateConVar("l4d2_missile_weapon_rifle", "1", "Enable or disable for rifles. (0=Disabled, 1=Enabled)");
	l4d2_missile_weapon_sniper = CreateConVar("l4d2_missile_weapon_sniper", "1", "Enable or disable for  snipers. (0=Disabled, 1=Enabled)");
	l4d2_missile_weapon_shotgun = CreateConVar("l4d2_missile_weapon_shotgun", "1", "Enable or disable for shotguns. (0=Disabled, 1=Enabled)");
	l4d2_missile_weapon_magnum  = CreateConVar("l4d2_missile_weapon_magnum", "0", "Enable or disable. for magnum (0=Disabled, 1=Enabled)");	
	l4d2_missile_weapon_smg  = CreateConVar("l4d2_missile_weapon_smg", "1", "Enable or disable for smgs. (0=Disabled, 1=Enabled)");	
	l4d2_missile_weapon_pistol  = CreateConVar("l4d2_missile_weapon_pistol", "0", "Enable or disable for pistol. (0=Disabled, 1=Enabled)");	
	l4d2_missile_weapon_grenade = CreateConVar("l4d2_missile_weapon_grenade", "1", "Enable or disable missiles for grenade launcher. (0=Disabled, 1=Enabled)");
	
	l4d2_missile_limit = CreateConVar("l4d2_missile_limit", "1", "Missile limit survivor can carry. [Min=1.0, Max=50.0]");
 	l4d2_missile_kills = CreateConVar("l4d2_missile_kills", "75", "How many kills reward a missile. [1.0, 100.0]");	
 	l4d2_missile_tracefactor = CreateConVar("l4d2_missile_tracefactor", "1.5", "Trace factor of missile. Do not need to change. [0.5, 3.0]");		
 	l4d2_missile_radar_range = CreateConVar("l4d2_missile_radar_range", "1500.0", "Radar scan range for missile to not lock on target. [Min=500.0, Max=2000.0");	
	
	g_iVelocity = FindSendPropInfo("CBasePlayer", "m_vecVelocity[0]");
	
	char GameName[16];
	GetConVarString(FindConVar("mp_gamemode"), GameName, sizeof(GameName));
	
	if(StrEqual(GameName, "survival", false))
		GameMode = 3;
	else if(StrEqual(GameName, "versus", false) || StrEqual(GameName, "teamversus", false) || StrEqual(GameName, "scavenge", false) || StrEqual(GameName, "teamscavenge", false))
		GameMode = 2;
	else if(StrEqual(GameName, "coop", false) || StrEqual(GameName, "realism", false))
		GameMode = 1;
	else
	{
		GameMode = 0;
 	}
	
	GetGameFolderName(GameName, sizeof(GameName));
	if(StrEqual(GameName, "left4dead2", false))
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
			HookEvent("tongue_grab", tongue_grab);
			HookEvent("witch_harasser_set", witch_harasser_set);
			HookEvent("ability_use", ability_use);
		}
		
		ResetAllState();
		Set();
		gamestart=false;
	}	
}
public Action MissileHelp(int client, int args)
{
	if(GetConVarInt(l4d2_missile_enable)==1)
	{
		PrintToChat(client, "[L4D2 MISSILES] For every %d infected killed you earn 1 missile.", GetConVarInt(l4d2_missile_kills));
		PrintToChat(client, "[L4D2 MISSILES] Type 1 = Missile launch at crosshair: Press USE key while firing.");
		PrintToChat(client, "[L4D2 MISSILES] Type 2 = Auto tracking missile: Press DUCK + USE key while firing.");
	}
	return Plugin_Continue;
}
public Action ability_use(Handle event, const char[] name, bool dontBroadcast)
{
	char s[20];
	GetEventString(event, "ability", s, 32);
	if(StrEqual(s, "ability_spit", true))
	{
		int client = GetClientOfUserId(GetEventInt(event, "userid"));
		if(MissileEntity[client]==0 && GetRandomFloat(0.0, 100.0)<GetConVarFloat(l4d2_missile_infected_spitter))
		{
			LaunchMissile(client, missilespeed_trace2, MissileTrace, true, 30.0);
		}
	}
	
	if(StrEqual(s, "ability_vomit", true))
	{
		int client = GetClientOfUserId(GetEventInt(event, "userid"));
		if(MissileEntity[client]==0 && GetRandomFloat(0.0, 100.0)<GetConVarFloat(l4d2_missile_infected_boomer))
		{
			LaunchMissile(client, missilespeed_trace2, MissileTrace, true, 30.0);
		}
	}
	
	if(StrEqual(s, "ability_lunge", true))
	{
		int client = GetClientOfUserId(GetEventInt(event, "userid"));
		if(MissileEntity[client]==0 && GetRandomFloat(0.0, 100.0)<GetConVarFloat(l4d2_missile_infected_hunter))
		{
			LaunchMissile(client, missilespeed_trace2, MissileTrace, true, 30.0);
		}
	}	

	else if(StrEqual(s, "ability_throw", true))
	{
		int client = GetClientOfUserId(GetEventInt(event, "userid"));
		if(!Hooked[client] && GetRandomFloat(0.0, 100.0)<GetConVarFloat(l4d2_missile_infected_tank_throw))
		{
			LaunchMissile(client,missilespeed_trace2, MissileTrace, true, 30.0);
		}		
	}
	return Plugin_Continue;
}
public Action witch_harasser_set(Handle hEvent, const char[] strName, bool DontBroadcast)
{ 
	if(GetRandomFloat(0.0, 100.0)<GetConVarFloat(l4d2_missile_infected_witch))
	{
		CreateTimer(GetRandomFloat(0.1, 0.5), InfectedAntiMissile, 0);
	}
	return Plugin_Continue;
}
 
public Action charger_charge_start(Handle event, const char[] name, bool dontBroadcast)
{	 
 	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(!Hooked[client] && GetRandomFloat(0.0, 100.0)<GetConVarFloat(l4d2_missile_infected_charger))
	{
		LaunchMissile(client, missilespeed_trace2, MissileTrace, true, 30.0);
	}
	return Plugin_Continue;
}
public Action tongue_grab(Handle event, const char[] name, bool dontBroadcast)
{	 
 	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(!Hooked[client] && GetRandomFloat(0.0, 100.0)<GetConVarFloat(l4d2_missile_infected_smoker))
	{
		LaunchMissile(client, missilespeed_trace2, MissileTrace, true, 30.0);
	}
	return Plugin_Continue;
}

public Action weapon_fire(Handle event, const char[] name, bool dontBroadcast)
{
	if(gamestart==false)
	{
		return Plugin_Continue;
	}
	
 	int client = GetClientOfUserId(GetEventInt(event, "userid"));	 
	if(GetClientTeam(client)==2)
	{
		if(GetClientButtons(client) & IN_USE)
		{
			float time=GetEngineTime();
			if(time-LastUseTime[client]>1.0)
			{
				LastUseTime[client]=time; 
				bool ok=false;
				char item[65];
				GetEventString(event, "weapon", item, 65);	
				if(GetConVarInt(l4d2_missile_weapon_shotgun)>0 && StrContains(item, "shot")>=0) ok=true;
				else if(GetConVarInt(l4d2_missile_weapon_sniper)>0 && (StrContains(item, "sniper")>=0 || StrContains(item, "hunting")>=0)) ok=true;	
				else if(GetConVarInt(l4d2_missile_weapon_rifle)>0 && StrContains(item, "rifle")>=0) ok=true;	 				
				else if(GetConVarInt(l4d2_missile_weapon_magnum)>0 && StrContains(item, "magnum")>=0) ok=true;
				else if(GetConVarInt(l4d2_missile_weapon_pistol)>0 && StrContains(item, "pistol")>=0) ok=true;	
				else if(GetConVarInt(l4d2_missile_weapon_smg)>0 && StrContains(item, "smg")>=0) ok=true;
				else if(GetConVarInt(l4d2_missile_weapon_grenade)>0 && StrContains(item, "grenade")>=0) ok=true;
				
				if(ok)
				{				 
					int type=MissileNormal;
					if(GetClientButtons(client) & IN_DUCK) 
					{
						type=MissileTrace;
						StartMissile(client, type);
					}
				}
			}
		}
	}
	return Plugin_Continue;
}
public Action InfectedAntiMissile(Handle timer, any ent)
{
	int selected=0;
	int andidate[MAXPLAYERS+1];
	int index=0;
	for(int client = 1; client <= MaxClients; client++)
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
	return Plugin_Continue;
}
int upgradekillcount[MAXPLAYERS+1];
int totalkillcount[MAXPLAYERS+1];
void UpGrade(int x, int kill)
{
 	upgradekillcount[x]+=kill;
	totalkillcount[x]+=kill;
	int v=upgradekillcount[x]/GetConVarInt(l4d2_missile_kills);
	upgradekillcount[x]=upgradekillcount[x]%GetConVarInt(l4d2_missile_kills);
	MissileCount[x]+=v;
	if(v>0 && (GetUserFlagBits(x) & ADMFLAG_ROOT))
	{
		PrintHintText(x, "Infected pwnd: %d", totalkillcount[x]);
	}
	if(MissileCount[x]>GetConVarInt(l4d2_missile_limit))
	{
		MissileCount[x]=GetConVarInt(l4d2_missile_limit);
		PrintHintText(x, "Missiles available: %d", MissileCount[x]);
	}
	if(ShowMsg[x]<3)
	{
		PrintToChat(x, "Type !m in to chat to learn how to use missile launcher.", MissileCount[x]);
		ShowMsg[x]++;
	}		
}
public Action Event_InfectedDeath(Handle hEvent, const char[] strName, bool DontBroadcast)
{
 
	int attacker = GetClientOfUserId(GetEventInt(hEvent, "attacker"));
	if(attacker<=0) 
	{
 		return Plugin_Continue;
	}
	if(IsClientInGame(attacker))
	{
		if(GetClientTeam(attacker) == 2)
		{
			UpGrade(attacker, 1);
		}
	}
 
	return Plugin_Continue;
}
public Action player_death(Handle hEvent, const char[] strName, bool DontBroadcast)
{ 
	int victim = GetClientOfUserId(GetEventInt(hEvent, "userid"));
 	int attacker = GetClientOfUserId(GetEventInt(hEvent, "attacker"));
	if(victim <= 0 || attacker<=0) 
	{
 		return Plugin_Continue;
	}
	if(IsClientInGame(attacker))
	{
		if(GetClientTeam(attacker) == 2)
		{
			if(IsClientInGame(victim))
			{
				if(GetClientTeam(victim) == 3)
				{
					bool headshot=GetEventBool(hEvent, "headshot");
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
void UnHookMissile(int client)
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
bool IsEntityMissile(int ent)
{
	bool r=false;
	if(ent>0 && IsValidEdict(ent) && IsValidEntity(ent))
	{
		char g_classname[64];
		GetEdictClassname(ent, g_classname, 64);	
		if(StrEqual(g_classname, "molotov_projectile"))
		{
			r=true;
		}
	}
	return r;
}
bool IsEntityMissileModel(int ent)
{
	bool r=false;
	if(ent>0 && IsValidEdict(ent) && IsValidEntity(ent))
	{ 
		char g_classname[64];
		GetEdictClassname(ent, g_classname, 64);	
		if(StrEqual(g_classname, "prop_dynamic_override", true))
		{
			r=true;
		}
	}
	return r;
}
void StartMissile(int client, int type = MissileTrace)
{
	if(MissileCount[client]-1>=0)
	{ 
		bool ok;
		if(type==MissileNormal)	
		{
			ok=LaunchMissile(client, missilespeed_normal, type, false, 15.0);
		}
		else 
		{
			ok=LaunchMissile(client, missilespeed_trace, type, false, 15.0);
		}
		if(ok && GetRandomFloat(0.0, 100.0)<GetConVarFloat(l4d2_missile_infected_anti))
		{
			CreateTimer(GetRandomFloat(0.1, 1.0), InfectedAntiMissile, 0, TIMER_FLAG_NO_MAPCHANGE);
		}
		if(ok)
		{
			PrintHintText(client, "Total Missiles: %d", MissileCount[client]);
		}
		if(GetClientTeam(client)==3)
		{
			PrintToChatAll("\x04%N \x03Launched a smack-my-bitch-up missile!", client);
		}
	}
	else
	{
		PrintHintText(client, "Einstein, you have no missiles!");
	} 
}
bool LaunchMissile(int client, float force, int type = MissileTrace, bool up = false, float offset)
{
	if(Hooked[client])UnHookMissile(client);
	
	float pos[3];
	float angles[3];
	float velocity[3];
	GetClientEyePosition(client, pos); 
	GetClientEyeAngles(client, angles);
	if(up)
	{
		angles[1]=-90.0;
		angles[0]=-90.0;
		angles[2]=0.0;
	} 
	
	GetAngleVectors(angles, velocity, NULL_VECTOR, NULL_VECTOR);
	NormalizeVector(velocity, velocity);
	ScaleVector(velocity, force); 
	{
		float vec[3];
		GetAngleVectors(angles,vec, NULL_VECTOR, NULL_VECTOR); 
		NormalizeVector(vec,vec); 
		ScaleVector(vec, offset);
 		AddVectors(pos, vec, pos);
	}
	 
	float temp[3];
	float dis=CalRay(pos, angles, 0.0, 0.0, temp, client, false, FilterSelf);

	if(dis<150.0)
	{
		PrintHintText(client, "No space to launch your tiny missile!");
		return false;
	}
 
	bool ok=CreateMissile(client,type,  pos, velocity, angles); 
	if(!ok)	return false;
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
	
	if(L4D2Version) 
	{
		EmitSoundToAll("physics/destruction/explosivegasleak.wav", 0, SNDCHAN_WEAPON, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, pos, NULL_VECTOR, false, 0.0);
	}
	else 
	{
		EmitSoundToAll("physics/destruction/explosivegasleak.wav", 0, SNDCHAN_WEAPON, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, pos, NULL_VECTOR, false, 0.0);
	}
	//PrintHintText(client, "Missiles: %d", MissileCount[client]);	
	//if(GetClientTeam(client)==3) PrintToChatAll("\x04%N \x03Launched their huge missile", client);
	return true;
}
bool CreateMissile(int client, int type, float pos[3], float vol[3], float ang[3])
{	 
	int ok=false;
 	type=type+0;
	int ent=CreateEntityByName("molotov_projectile");  
	if(ent>0)DispatchKeyValue(ent, "model", Missile_model_dummy);  
	float ang1[3];
	if(ent>0)
	{
		SetEntPropEnt(ent, Prop_Data, "m_hOwnerEntity", -1)	;	 
		CopyVector(ang, ang1);
		ScaleVector(vol , 1.0);
		if(!L4D2Version)ang1[0]-=90.0; 
		DispatchKeyValueVector(ent, "origin", pos); 
		SetEntityGravity(ent, 0.01); 
		DispatchSpawn(ent);  
		ok=true;
	}
	else ok=false; 
	int ment=0;
	if(ok)
	{
		ment=CreateEntityByName("prop_dynamic_override");
		if(ment>0 && ok)
		{
			char tname[20];
			Format(tname, 20, "missile%d", ent);
			DispatchKeyValue(ent, "targetname", tname);
			if(L4D2Version)
			{
				DispatchKeyValue(ment, "model", Missile_model2);  
				
			}
			else 
			{
				DispatchKeyValue(ment, "model", Missile_model);
			}				
			DispatchKeyValue(ment, "parentname", tname);  
			 
			float ang2[3]; 
			float offset[3];
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
			AcceptEntityInput(ment, "SetParent", ment, ment, 0);
			
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
void AttachFlame(int client, int ent)
{ 
	char flame_name[128];
	Format(flame_name, sizeof(flame_name), "target%d", ent);
 	
	float origin[3];
	SetVector(origin,  0.0, 0.0,  0.0);
	float ang[3];
	if(L4D2Version)	SetVector(ang, 0.0, 180.0, 0.0); 
	else SetVector(ang, 90.0, 0.0, 0.0); 
	 
	int flame3 = CreateEntityByName("env_steam");
	DispatchKeyValue(ent,"targetname", flame_name);
	DispatchKeyValue(flame3,"SpawnFlags", "1");
	DispatchKeyValue(flame3,"Type", "0");
	DispatchKeyValue(flame3,"InitialState", "1");
	DispatchKeyValue(flame3,"Spreadspeed", "10");
	DispatchKeyValue(flame3,"Speed", "350");
	DispatchKeyValue(flame3,"Startsize", "5");
	DispatchKeyValue(flame3,"EndSize", "10");
	DispatchKeyValue(flame3,"Rate", "555");
	DispatchKeyValue(flame3,"RenderColor", "0 160 55"); //"242 55 55"
	DispatchKeyValue(flame3,"JetLength", "50"); 
	DispatchKeyValue(flame3,"RenderAmt", "180");
	
	DispatchSpawn(flame3);	 
	SetVariantString(flame_name);
	AcceptEntityInput(flame3, "SetParent", flame3, flame3, 0);
	TeleportEntity(flame3, origin, ang,NULL_VECTOR);
	AcceptEntityInput(flame3, "TurnOn");	
	
	MissileFlame[client]=flame3;
	 
}
public void ThinkMissile(int client)
{ 
	if(Hooked[client]==false)
	{
		UnHookMissile(client);
		return;
	}
	if(IsClientInGame(client))
	{
		float time=GetEngineTime();
		float duration=time-LastTime[client];
		LastTime[client]=time;	
		if(duration>0.1)duration=0.1;
		else if(duration<0.01)duration=0.01;
		
		if(MissileType[client]==MissileTrace)TraceMissile(client, time, duration);
		else if(MissileType[client]==MissileNormal)Missile(client, duration);  
	}
	else
	{
		UnHookMissile(client);
	}
}
void TraceMissile(int client, float time, float duration)
{	 
	int ent=MissileEntity[client];
	float posradar[3];
	float posmissile[3];
	float voffset[3];			
	float velocitymissile[3];
	GetClientEyePosition(client, posradar);
	GetEntPropVector(ent, Prop_Send, "m_vecOrigin", posmissile);	
	GetEntDataVector(ent, g_iVelocity, velocitymissile);
	
	NormalizeVector(velocitymissile, velocitymissile);	
	CopyVector(velocitymissile, voffset);
	ScaleVector(voffset, modeloffset);
	AddVectors(posmissile, voffset, posmissile);
	
	int myteam=MissileTeams[client];	
	int enemyteam=myteam==SurvivorTeam?InfectedTeam:SurvivorTeam;
	int enemy=MissileEnemy[client];
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

	float velocityenemy[3];
	float vtrace[3];
	
	vtrace[0]=vtrace[1]=vtrace[2]=0.0;	
	bool visible=false;
	float missionangle[3];
 
	float disenemy=1000.0;
	float disobstacle=1000.0;
	float disexploded=20.0;
	bool show=false;
	bool enemyismissile=false;
	if(time-PrintTime[client]>0.2)
	{
		PrintTime[client]=time;
		show=true;
	} 
	float speed=0.0;
	if(myteam==SurvivorTeam)speed=missilespeed_trace;
	else speed=missilespeed_trace2;
	float tracefactor=GetConVarFloat(l4d2_missile_tracefactor);
	if(enemy>0)	
	{
		float posenemy[3];
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
				if(client > 0 && IsClientInGame(client) && IsPlayerAlive(client)) PrintHintText(enemy, "%N's missile is locked on! Distance: %d", client, RoundFloat(disenemy));
				else PrintHintText(enemy, "Your missile locked on enemy's missile. Distance: %d", RoundFloat(disenemy));
				EmitSoundToClient(enemy, "ui/beep07.wav");
			}
			if(client > 0 && IsClientInGame(client) && IsPlayerAlive(client))
			{
				if(enemy>0 && IsClientInGame(enemy) && IsPlayerAlive(enemy)) PrintHintText(client, "Missile lock on %N! Distance: %d", enemy, RoundFloat(disenemy));
				else PrintHintText(client, "Your missile locked onenemy's missile. Distance: %d", RoundFloat(disenemy));
			}
		}	 
	}
	else if(enemy<0)
	{
		enemy=-enemy; 
		
		float posenemy[3];
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
			if(client > 0 && IsClientInGame(client) && IsPlayerAlive(client) && GetConVarInt(l4d2_missile_enable)==1)
			{
				if(enemy>0 && IsClientInGame(enemy) && IsPlayerAlive(enemy))
				{
					PrintHintText(client, "Enemy missile lock by %N!/nDistance to pwnage: %d", enemy, RoundFloat(disenemy));
				}
			}
		}		 
		enemyismissile=true;
	}
	else if(show)
	{
		if(client>0 && IsClientInGame(client) && IsPlayerAlive(client) && GetConVarInt(l4d2_missile_enable)==1)
		{
			PrintHintText(client, "Nice shot Annie Oakley, duh... NOT!");
		}
	}
	if(enemy==0 && myteam==2)
	{
		speed=missilespeed_trace2;
		float dis=GetVectorDistance(posmissile,posradar);
		{	  
			float posenemy[3];
			CopyVector(posradar, posenemy);			 
			disenemy=dis;	 
			MakeVectorFromPoints(posmissile, posenemy, vtrace);
		}
	}
	
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
	
	vfront[0]=vfront[1]=vfront[2]=0.0;	
	 
	float factor2=0.5; 
	float factor1=0.2; 
	float t;
	float base=1500.0;
	if(visible)
	{
		base=80.0;
	}
	{
		int flag=FilterSelfAndInfected;
		bool print=false;
		int self=MissleModel[client];
		float front=CalRay(posmissile, missionangle, 0.0, 0.0, vfront, self, print, flag);
		print=false;
		disobstacle=CalRay(posmissile, missionangle, 0.0, 0.0, vfront, self, print, FilterSelf);
		 
		float down=CalRay(posmissile, missionangle, 90.0, 0.0, vdown, self, print,  flag);
		float up=CalRay(posmissile, missionangle, -90.0, 0.0, vup, self, print);
		float left=CalRay(posmissile, missionangle, 0.0, 90.0, vleft, self, print, flag);
		float right=CalRay(posmissile, missionangle, 0.0, -90.0, vright, self, print, flag);
		
		float f1=CalRay(posmissile, missionangle, 30.0, 0.0, vv1, self, print, flag);
		float f2=CalRay(posmissile, missionangle, 30.0, 45.0, vv2, self, print, flag);
		float f3=CalRay(posmissile, missionangle, 0.0, 45.0, vv3, self, print, flag);
		float f4=CalRay(posmissile, missionangle, -30.0, 45.0, vv4, self, print, flag);
		float f5=CalRay(posmissile, missionangle, -30.0, 0.0, vv5, self, print,flag);
		float f6=CalRay(posmissile, missionangle, -30.0, -45.0, vv6, self, print, flag);	
		float f7=CalRay(posmissile, missionangle, 0.0, -45.0, vv7, self, print, flag);
		float f8=CalRay(posmissile, missionangle, 30.0, -45.0, vv8, self, print, flag);					
		  
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
	 
		float b2=10.0;
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
	
	float a=GetAngle(vfront, velocitymissile);			 
	float amax=3.14159*duration*tracefactor;
	 
	if(a>amax) a=amax;
	
	ScaleVector(vfront ,a);
	
	float newvelocitymissile[3];
	AddVectors(velocitymissile, vfront, newvelocitymissile);
	
	ScaleVector(newvelocitymissile,speed); 
	
	float angle[3];
	GetVectorAngles(newvelocitymissile, angle);
	if(!L4D2Version)angle[0]-=90.0;
	TeleportEntity(ent, NULL_VECTOR,  angle ,newvelocitymissile); 
 	
	if(disenemy<disexploded || disobstacle<disexploded)
	{
		bool hitenemy=false;
		if(disenemy<150.0)hitenemy=true;
		 
		if(enemyismissile)
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

void Missile(int client, float duration)
{
	float missionangle[3];
	float voffset[3];
 	float missilepos[3];
	float velocitymissile[3];
	int ent=MissileEntity[client];
	duration=duration*1.0;
	GetEntPropVector(ent, Prop_Send, "m_vecOrigin", missilepos);
	GetEntDataVector(ent, g_iVelocity, velocitymissile);
	NormalizeVector(velocitymissile,velocitymissile);
 	CopyVector(velocitymissile, voffset);
	ScaleVector(voffset, modeloffset);
	AddVectors(missilepos, voffset, missilepos);

	float temp[3];
	GetVectorAngles(velocitymissile, missionangle);
	float disenemy=CalRay(missilepos, missionangle, 0.0, 0.0, temp, MissileEntity[client], false, FilterSelf);
	
	float angle[3];
	GetVectorAngles(velocitymissile,  angle);
	if(!L4D2Version)angle[0]-=90.0;
  
	DispatchKeyValueVector(ent, "Angles", angle);
	if(disenemy<20.0)
	{
		MissileHit(client);
		UnHookMissile(client);
	} 
}
 
void MissileHitMissileMsg(int client, int enemy, bool hit = true)
{
	if((hit) && GetConVarInt(l4d2_missile_enable)==1)
	{
		if(enemy>0 && IsClientInGame(enemy))
		{
			if(client> 0 && IsClientInGame(client))
			{
				PrintHintText(enemy, "Your missile was intercepted by %N!", client);
			}
			else 
			{
				PrintHintText(enemy, "Your missile was intercepted by the enemy!");
			}
		}
		if(client>0 && IsClientInGame(client))
		{
			if(enemy>0 && IsClientInGame(enemy) && IsPlayerAlive(enemy))
			{
				PrintHintText(client, "You intercepted %N's missile!", enemy);
			}
			else
			{
				PrintHintText(client, "You intercepted the enemy's missile!");
			}
		}
	}
	else
	{
		if(client> 0 && IsClientInGame(client))
		{
			PrintHintText(client, "Your missile hit jack shite!");
		}
	}
}
void MissileHitPlayerMsg(int client, int enemy, bool hit)
{
	if((hit) && GetConVarInt(l4d2_missile_enable)==1)
	{
		if(enemy>0 && IsClientInGame(enemy))
		{
			if(client> 0 && IsClientInGame(client))
			{
				PrintHintText(enemy, "You were pwnd by %N's missile!", client);
			}
			else 
			{
				PrintHintText(enemy, "You were pwnd by enemy's missile!");
			}
		}
		if(client>0 && IsClientInGame(client))
		{
			if(enemy>0 && IsClientInGame(enemy))
			{
				PrintHintText(client, "Your missile pwnd %N!", enemy);
			}
			else 
			{
				PrintHintText(client, "Your missile pwnd enemy!");
			}
		}
	}
	else
	{
		if(client> 0 && IsClientInGame(client) && GetConVarInt(l4d2_missile_enable)==1)
		{
			PrintHintText(client, "Your tiny missile didn't hit shite!");
		}
	}
}
void MissileHit(int client, int num = 2)
{ 
	float pos[3];
	float voffset[3];	
	GetEntPropVector(MissileEntity[client], Prop_Send, "m_vecOrigin", pos);		
	
	float velocitymissile[3];	
	GetEntDataVector(MissileEntity[client], g_iVelocity, velocitymissile);
	NormalizeVector(velocitymissile, velocitymissile);

	CopyVector(velocitymissile, voffset);
	ScaleVector(voffset, modeloffset);
	AddVectors(pos, voffset, pos);
	
	int ent1=0;		
	int ent2=0;
	int ent3=0;
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
	Handle h=CreateDataPack();		
	WritePackCell(h, ent1);
	WritePackCell(h, ent2);
	WritePackCell(h, ent3);
 
	WritePackFloat(h, pos[0]);
	WritePackFloat(h, pos[1]);
	WritePackFloat(h, pos[2]);
	
	float damage=0.0;
	if(MissileTeams[client]==SurvivorTeam)
	{
		damage=GetConVarFloat(l4d2_missile_damage_tosurvivor);
	}
	else
	{
		damage=GetConVarFloat(l4d2_missile_damage);
	}
		
	float radius=GetConVarFloat(l4d2_missile_radius);
	float pushforce=GetConVarFloat(l4d2_missile_push);		
	
	if(GetConVarInt(l4d2_missile_safe)==1 && MissileTeams[client]==SurvivorTeam)
	{
		float mindistance=GetSurvivorMinDistance(pos);
		if(mindistance<radius)radius=mindistance;
	}		 
	WritePackFloat(h, damage);
	WritePackFloat(h, radius);
	WritePackFloat(h, pushforce);
	
	ExplodeG(INVALID_HANDLE, h);

	if(MissileType[client]!=MissileTrace &&  IsClientInGame(client) && IsPlayerAlive(client))
	{
		PrintHintText(client, "Missile went big bada ba-boom!");
	}
}

void ScanEnemy(float missilePos[3], float radarPos[3], float vec[3], int enemyteam)
{
	float min=4.0;
	float enemyPos[3];
	float dir[3];
	float t;
	bool hasmissile=false;
	float range=GetConVarFloat(l4d2_missile_radar_range);
	for(int client = 1; client <= MaxClients; client++)
	{
		if(IsClientInGame(client))
		{
			bool playerok=IsPlayerAlive(client) && GetClientTeam(client)==enemyteam;
			bool ismissile=Hooked[client] && MissileTeams[client]==enemyteam;
			if(playerok || ismissile)
			{
				if(ismissile)
				{
					GetEntPropVector(MissileEntity[client], Prop_Send, "m_vecOrigin", enemyPos);
					if(enemyteam==2 || GetVectorDistance(enemyPos,radarPos)<range)
					{					
						if(!hasmissile)min=4.0;
						hasmissile=true;
						
						MakeVectorFromPoints(missilePos, enemyPos, dir);
						t=GetAngle(vec, dir);
						if(t<=min)
						{
							min=t;
							//selected=-client;
						}
					}
				}
				if(!hasmissile && playerok)
				{
					GetClientEyePosition(client, enemyPos);
					if(enemyteam==2 || GetVectorDistance(enemyPos,radarPos)<range)
					{
						MakeVectorFromPoints(missilePos, enemyPos,  dir);
						t=GetAngle(vec,  dir);
						//PrintToChatAll("%N %f", client, 360.0*t/3.1415926/2.0);
						
						if(t<=min)
						{
							min=t;
							//selected=client;
						}
					}
				}				
			}
		}
	}
}

float GetSurvivorMinDistance(float pos[3])
{
	float min=99999.0;
	float pos2[3];
	float t;
	for(int client = 1; client <= MaxClients; client++)
	{
		if(IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client)==2)
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
bool IfTwoPosVisible(float pos1[3], float pos2[3], int self, int team = SurvivorTeam)
{
	bool r=true;
	Handle trace;
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
float CalRay(float posmissile[3], float angle[3], float offset1, float offset2, float force[3], int ent, bool printlaser = true, int flag = FilterSelf) 
{
	float ang[3];
	CopyVector(angle, ang);
	ang[0]+=offset1;
	ang[1]+=offset2;
	GetAngleVectors(ang, force, NULL_VECTOR,NULL_VECTOR);
	float dis=GetRayDistance(posmissile, ang, ent, flag);	
	if(printlaser)ShowLarserByAngleAndDistance(posmissile, ang, dis*0.5);
	return dis;
}
void ShowLarserByAngleAndDistance(float pos1[3], float angle[3], float dis, int flag = 0, float life = 0.06)
{ 
	float pos2[3];
	GetAngleVectors(angle, pos2, NULL_VECTOR,NULL_VECTOR);
	NormalizeVector(pos2, pos2);
	ScaleVector(pos2, dis);
	AddVectors(pos1, pos2, pos2);
	ShowLarserByPos(pos1, pos2, flag, life);	
}
void ShowLarserByPos(float pos1[3], float pos2[3], int flag = 0, float life = 0.06)
{
	int color[4];
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
	
	float width1=0.5;
	float width2=0.5;		
	if(L4D2Version)
	{
		width2=0.3;
		width2=0.3;
	}
 	
	TE_SetupBeamPoints(pos1, pos2, g_sprite, 0, 0, 0, life, width1, width2, 1, 0.0, color, 0);
	TE_SendToAll();
}
void CopyVector(float source[3], float target[3])
{
	target[0]=source[0];
	target[1]=source[1];
	target[2]=source[2];
}
void SetVector(float target[3], float x, float y, float z)
{
	target[0]=x;
	target[1]=y;
	target[2]=z;
}
float GetRayDistance(float pos[3], float  angle[3], int self, int flag)
{
	float hitpos[3];
	GetRayHitPos(pos, angle, hitpos, self, flag);
	return GetVectorDistance(pos, hitpos);
}
float GetAngle(float x1[3], float x2[3])
{
	return ArcCosine(GetVectorDotProduct(x1, x2)/(GetVectorLength(x1)*GetVectorLength(x2)));
}
void GetRayHitPos(float pos[3], float angle[3], float hitpos[3], int self, int flag)
{
	Handle trace;
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
	}
	CloseHandle(trace);	
}
public Action ExplodeG(Handle timer, Handle h)
{
	ResetPack(h);
 
	int ent1=ReadPackCell(h);
	int ent2=ReadPackCell(h);
	int ent3=ReadPackCell(h);

	float pos[3];
	pos[0]=ReadPackFloat(h);
	pos[1]=ReadPackFloat(h);
	pos[2]=ReadPackFloat(h);
	float damage=ReadPackFloat(h);
	float radius=ReadPackFloat(h);
	float force=ReadPackFloat(h);
	CloseHandle(h);
	
 	if(ent1>0 && IsValidEntity(ent1) && IsValidEdict(ent1))
	{		 
 		AcceptEntityInput(ent1, "break");
		AcceptEntityInput(ent1, "kill");
 		if(ent2>0 && IsValidEntity(ent2) && IsValidEdict(ent2))
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
 	int pointHurt = CreateEntityByName("point_hurt");   
 	
 	DispatchKeyValueFloat(pointHurt, "Damage", damage);        
	DispatchKeyValueFloat(pointHurt, "DamageRadius", radius);     
 	DispatchKeyValue(pointHurt, "DamageDelay", "0.0");   
	DispatchSpawn(pointHurt);
	TeleportEntity(pointHurt, pos, NULL_VECTOR, NULL_VECTOR);  
	AcceptEntityInput(pointHurt, "Hurt");    
	CreateTimer(0.1, DeletePointHurt, pointHurt); 
 
	int push = CreateEntityByName("point_push");         
  	DispatchKeyValueFloat (push, "magnitude", force);                     
	DispatchKeyValueFloat (push, "radius", radius*1.0);                     
  	SetVariantString("spawnflags 24");                     
	AcceptEntityInput(push, "AddOutput");
 	DispatchSpawn(push);   
	TeleportEntity(push, pos, NULL_VECTOR, NULL_VECTOR);  
 	AcceptEntityInput(push, "Enable");
	CreateTimer(0.5, DeletePushForce, push);
	
	return Plugin_Continue;
}
public Action DeleteParticles(Handle timer, any particle)
{
	if(particle> 0 && IsValidEntity(particle) && IsValidEdict(particle))
	{
		char classname[64];
		GetEdictClassname(particle, classname, sizeof(classname));
		if(StrEqual(classname, "info_particle_system", false))
		{
			AcceptEntityInput(particle, "stop");
			AcceptEntityInput(particle, "kill");
			RemoveEdict(particle);
		}
	}
	return Plugin_Continue;
}
public Action DeletePushForce(Handle timer, any ent)
{
	if(ent> 0 && IsValidEntity(ent) && IsValidEdict(ent))
	{
		char classname[64];
		GetEdictClassname(ent, classname, sizeof(classname));
		if(StrEqual(classname, "point_push", false))
		{
 			AcceptEntityInput(ent, "Disable");
			AcceptEntityInput(ent, "Kill"); 
			RemoveEdict(ent);
		}
	}
	return Plugin_Continue;
}
public Action DeletePointHurt(Handle timer, any ent)
{
	if(ent> 0 && IsValidEntity(ent) && IsValidEdict(ent))
	{
		char classname[64];
		GetEdictClassname(ent, classname, sizeof(classname));
		if(StrEqual(classname, "point_hurt", false))
		{
			AcceptEntityInput(ent, "Kill"); 
			RemoveEdict(ent);
		}
	}
	return Plugin_Continue;
}
public void ShowParticle(float pos[3], char[] particlename, float time)
{
	int particle = CreateEntityByName("info_particle_system");
	if(IsValidEdict(particle))
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
public Action round_start(Handle event, const char[] name, bool dontBroadcast)
{
	ResetAllState(); 
	gamestart=true;
	return Plugin_Continue;
}
public Action round_end(Handle event, const char[] name, bool dontBroadcast)
{
	UnHookAll();
	ResetAllState(); 
	gamestart=false;
	return Plugin_Continue;
}
void ResetAllState()
{
	for (int x = 1; x < MAXPLAYERS+1; x++)
	{
		ResetClientState(x);
 	}
}
void ResetClientState(int x)
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
void UnHookAll()
{
	for (int x = 1; x < MAXPLAYERS+1; x++)
	{
		UnHookMissile(x);
 	}	
}
public void OnConfigExecuted()
{
	ResetAllState();
	Set();
}
void Set()
{
 
}
public void CvarChanged(Handle convar, const char[] oldValue, const char[] newValue)
{
	Set();
}
public void OnMapStart()
{
	PrecacheParticle("fire_small_01");
	PrecacheModel("models/props_junk/propanecanister001a.mdl", true); 
	PrecacheModel(Missile_model_dummy, true);
	PrecacheParticle("gas_explosion_pump"); 
	PrecacheSound("ui/beep07.wav", true);
	
	if(L4D2Version)
	{
		PrecacheModel(Missile_model, true);
		g_sprite = PrecacheModel("materials/sprites/laserbeam.vmt");	
		PrecacheSound("physics/destruction/explosivegasleak.wav", true);	
	}
	else
	{
		PrecacheModel(Missile_model, true);
		g_sprite = PrecacheModel("materials/sprites/laser.vmt");	
		PrecacheSound("physics/destruction/explosivegasleak.wav", true);	
	}
	ResetAllState();
	gamestart=true;
	
	// fix for the first missile do not lag the server
	int ment = CreateEntityByName("prop_dynamic_override");
	DispatchKeyValue(ment, "model", L4D2Version ? Missile_model2 : Missile_model);
	DispatchSpawn(ment);
	AcceptEntityInput(ment, "kill");	
}
void PrecacheParticle(const char[] sEffectName)
{
    static int table = INVALID_STRING_TABLE;

    if( table == INVALID_STRING_TABLE )
    {
        table = FindStringTable("ParticleEffectNames");
    }

    if( FindStringIndex(table, sEffectName) == INVALID_STRING_INDEX )
    {
        bool save = LockStringTables(false);
        AddToStringTable(table, sEffectName);
        LockStringTables(save);
    }
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
	else if(entity>0 && entity<=MaxClients)
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
	else if(entity>0 && entity<=MaxClients)
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
	else if(entity>0 && entity<=MaxClients)
	{
		if(IsClientInGame(entity) && GetClientTeam(entity)==3)
		{
			return false;
		}
	}
	return true;
}
