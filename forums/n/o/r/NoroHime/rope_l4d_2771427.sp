#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
//#include <sdktools_functions>


#define ZOMBIECLASS_SMOKER	1
#define ZOMBIECLASS_BOOMER	2
#define ZOMBIECLASS_HUNTER	3
#define ZOMBIECLASS_SPITTER	4
#define ZOMBIECLASS_JOCKEY	5
#define ZOMBIECLASS_CHARGER	6 

#define PARTICLE_BLOOD		"blood_impact_headshot_01"
#define SOUND_FIRE "player/smoker/miss/smoker_reeltonguein_01.wav"
 
#define MODEL_W_PIPEBOMB "models/w_models/weapons/w_eq_pipebomb.mdl"
#define particle_smoker_tongue "smoker_tongue"

int ZOMBIECLASS_TANK = 5;
bool L4D2Version;

#define Pai 3.141592653589793

bool enabled[MAXPLAYERS+1];

enum STATE {SHOT = 1, NONE = 0}
STATE states[MAXPLAYERS+1];
float scopes[MAXPLAYERS+1];

float time_last[MAXPLAYERS+1];
float time_hurt[MAXPLAYERS+1];
float time_jump[MAXPLAYERS+1];
int targets[MAXPLAYERS+1];
bool frees[MAXPLAYERS+1];
int ents[MAXPLAYERS+1][3];
float position_target [MAXPLAYERS+1][3];
bool isHookMode[MAXPLAYERS+1];
int button_last[MAXPLAYERS+1];

ConVar l4d_rope_damage; 
ConVar l4d_rope_distance ;
ConVar l4d_rope_drop_from_witch ;
ConVar l4d_rope_drop_from_tank ;
 

int g_PointHurt = 0;
int g_iVelocity = 0;
public Plugin:myinfo = {
	name = "Rope and Hook",
	author = " pan xiao hai & NoroHime",
	description = " ",
	version = "1.0",
	url = "http://forums.alliedmods.net"
}

public OnPluginStart() { 	 
	GameCheck(); 	
	
	if(!L4D2Version)return;
	
	HookEvent("player_spawn", player_spawn);	
	HookEvent("player_death", player_death); 

	HookEvent("player_bot_replace", player_bot_replace );	  
	HookEvent("bot_player_replace", bot_player_replace );	
 

	HookEvent("round_start", round_end);
	HookEvent("round_end", round_end);
	HookEvent("finale_win", round_end);
	HookEvent("mission_lost", round_end);
	HookEvent("map_transition", round_end);	
	
	HookEvent("witch_killed", witch_killed ); 
	HookEvent("tank_killed", tank_killed );	
	
	
	RegConsoleCmd("sm_rope", sm_rope);
	RegConsoleCmd("sm_hook", sm_hook);
	
	g_iVelocity = FindSendPropInfo("CBasePlayer", "m_vecVelocity[0]");
	
	l4d_rope_damage = CreateConVar("l4d_rope_damage", "10", " damage", FCVAR_NOTIFY);
 	l4d_rope_distance = CreateConVar("l4d_rope_distance", "900.0", "range", FCVAR_NOTIFY);
 
	l4d_rope_drop_from_witch = CreateConVar("l4d_rope_drop_from_witch", "50.0", " ", FCVAR_NOTIFY);
 	l4d_rope_drop_from_tank = CreateConVar("l4d_rope_drop_from_tank", "50.0", "", FCVAR_NOTIFY);
	
	AutoExecConfig(true, "rope_l4d");  
}

public OnMapStart() {
	ResetAllState();
	
	PrecacheModel(MODEL_W_PIPEBOMB);
	PrecacheSound(SOUND_FIRE); 
	
	PrecacheParticle(PARTICLE_BLOOD);

		
	PrecacheParticle(particle_smoker_tongue);
 
} 

public Action:round_start(Handle:event, const String:name[], bool dontBroadcast) {
	ResetAllState();
}
 
public Action:round_end(Handle:event, const String:name[], bool dontBroadcast) {
	ResetAllState();
}

ResetAllState() {
	g_PointHurt=0; 
	for(int i=1; i<=MaxClients; i++)
	{
		ResetClientState(i); 
	}
}

ResetClientState(client) {
	enabled[client]=false;
	states[client]=NONE;
	ents[client][0]=0;
	ents[client][1]=0;
	ents[client][2]=0;
}

public Action sm_rope(client, args) {
	if(isClient(client)) {

		if(enabled[client]) {
			if (isHookMode[client]) {
				PrintCenterText(client, "Switch to Rope Modd");
				isHookMode[client] = false;
			} else
				DisableRope(client);
		} else {
			isHookMode[client] = false;
			EnableRope(client);
		}
	}

	return Plugin_Handled;
}

public Action sm_hook(client, args) {
	if(isClient(client)) {

		if(enabled[client]) {
			if (!isHookMode[client]) {
				PrintCenterText(client, "Switch to Hook Mode");
				isHookMode[client] = true;
			} else
				DisableRope(client);
		} else {
			isHookMode[client] = true;
			EnableRope(client);
		}
	}
	return Plugin_Handled;
}

void GiveRope(client) {
	if(!enabled[client]) {
		bool hooks = 50.0 > GetRandomFloat(0.0, 100.0);
		EnableRope(client);
		isHookMode[client] = hooks;
	}
}

public void witch_killed(Event event, const char[] name, bool b_DontBroadcast)
{ 
	int witchid = GetEventInt(event, "witchid");
	int attacker = GetClientOfUserId(GetEventInt(event, "userid"));
	if(!attacker || IsFakeClient(attacker))
		return;
		
	if(witchid>0 && attacker>0) {
		if(GetRandomFloat(0.0, 100.0)<GetConVarFloat(l4d_rope_drop_from_witch)) {
			GiveRope(attacker);
			PrintToChatAll("\x04[\x05Notice\x04]\x05 %N \x03 Pickup %s..", attacker, isHookMode[attacker] ? "Hook" : "Rope");
		}
	}
}
public void tank_killed(Event event, const char[] name, bool DontBroadcast) {
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	if (isHumanSurvivor(attacker)) {
		if(GetRandomFloat(0.0, 100.0)<GetConVarFloat(l4d_rope_drop_from_tank)) {
			GiveRope(attacker);
			PrintToChatAll("\x04[\x05Notice\x04]\x05 %N \x03 Picked%s..", attacker, isHookMode[attacker] ? "Hook" : "Rope");
		}
		
	}
}

public void player_bot_replace(Event event, const char[] name, bool Spawn_Broadcast) {
	int client = GetClientOfUserId(GetEventInt(event, "player"));
	int bot = GetClientOfUserId(GetEventInt(event, "bot"));

	if(enabled[client])
		DisableRope(client);

	ResetClientState(client);
	ResetClientState(bot);

}
public void bot_player_replace(Event event, const char[] name, bool Spawn_Broadcast) {
	int client = GetClientOfUserId(GetEventInt(event, "player"));
	int bot = GetClientOfUserId(GetEventInt(event, "bot"));  
	if(enabled[client])
	{
		DisableRope(client);
	}
	ResetClientState(client);
	ResetClientState(bot);
  
}
public void player_spawn(Event event, const char[] name, bool DontBroadcast) {
	int client = GetClientOfUserId(GetEventInt(event, "userid"));  
	ResetClientState(client);
}
 

public void player_death(Event event, const char[] name, bool DontBroadcast) {

	int dead = GetClientOfUserId(GetEventInt(event, "userid")); 
	
	if(isClient(dead) && enabled[dead]) {
		DisableRope(dead);

		for(int i=1; i<=MaxClients; i++)
			if(enabled[i] && targets[i] == dead) {
				targets[i]=0;
				StopRope(i);
			}
	}

}

void DisableRope(client) {
	if(!enabled[client]) return;
	enabled[client]=false;
	
	StopRope(client);
	PrintCenterText(client, "%sDropped...", isHookMode[client] ? "Hook" : "Rope"); 
}
void EnableRope(client) {

	if (isInfected(client)) {
		PrintCenterText(client, "not infected allow"); 
		return;
	}

	if(enabled[client]) return;
	enabled[client] =true;
	states[client] = NONE;
	
	PrintCenterText(client, "Picked%s", isHookMode[client] ? "Hook" : "Rope"); 
	PrintToChat(client, "\x03 use \x05%s\x03 to shoot", isHookMode[client] ? "shove" : "scope");
	PrintToChat(client, "\x03 use on air %s", isHookMode[client] ? "or \x05Ctrl\x03 to adjust": "\x05Shift\x03 or \x05Ctrl\x03 to control");
}

int grabber[MAXPLAYERS + 1];

void StartRope(client) {
	if(states[client] != NONE) return;
	
	float pos[3], angle[3], hitpos[3];
	GetClientEyePosition(client, pos);
	GetClientEyeAngles(client, angle);	
 
	int target = GetEnt(client, pos, angle, hitpos); 
	if(GetVectorDistance(pos, hitpos) > l4d_rope_distance.FloatValue) {
		PrintCenterText(client, "too far");
		return;
	}

	scopes[client] = GetVectorDistance(pos, hitpos);
	frees[client] = true;
		
	time_hurt[client]=GetEngineTime()-1.0;
	time_last[client]=GetEngineTime()-0.01;
	time_jump[client]=GetEngineTime()-0.5;
	
	states[client] = SHOT; 
	CreateRope(client,target, pos, hitpos, 0); 
	CopyVector(hitpos,position_target[client]);
	
	if (isClient(target)) {
		grabber[target] = client;
	}
	// if(target>0 && target<=MaxClients)PrintHintText(client, "Rope Hooked %N", target);
	EmitSoundToAll(SOUND_FIRE, 0,  SNDCHAN_WEAPON, SNDLEVEL_NORMAL, SND_NOFLAGS, 1.0, SNDPITCH_NORMAL, -1, pos, NULL_VECTOR, true, 0.0);

	//PrintToChatAll("StartRope");
}

static const float VOID_VECTOR[3];
void StopRope(client) {
	if(states[client]!=SHOT)return;

	states[client]=NONE;
	
	int ent1=ents[client][0];
	int ent2=ents[client][1];
	int particle=ents[client][2];
	
	// float hide[3];
	// PrintToChat(client, "target %d source %d particle %d", ent1, ent2, ents[client][2]);
	// PrintToChat(client, "ent1 edict %b, entity %b", IsValidEdict(ent1-3), IsValidEntity(ent1-3));
	// PrintToChat(client, "ent2 edict %b, entity %b", IsValidEdict(ent2-3), IsValidEntity(ent2-3));
	// PrintToChat(client, "particle edict %b, entity %b", IsValidEdict(particle-3), IsValidEntity(particle-3));
	
	ClearClientEnts(client);

	for (int i = 1; i <= MaxClients; i++) {
		if (grabber[i] == client)
			grabber[i] = 0;
	}

}

void ClearClientEnts(int client) {
	int ent_target = ents[client][0],
		ent_source = ents[client][1],
		ent_particle = ents[client][2];

	if (IsValidEdict(ent_target)) {
		AcceptEntityInput(ent_target, "ClearParent");  
		TeleportEntity(ent_target, VOID_VECTOR, VOID_VECTOR, NULL_VECTOR);
		ents[client][0] = 0;
		CreateTimer(1.0, Timer_KillEntity, ent_target);
	}

	if (IsValidEdict(ent_source)) {
		AcceptEntityInput(ent_source, "ClearParent");  
		TeleportEntity(ent_source, VOID_VECTOR, VOID_VECTOR, NULL_VECTOR);
		ents[client][1] = 0;
		CreateTimer(1.0, Timer_KillEntity, ent_source);
	}

	if (IsValidEdict(ent_particle)) {
		AcceptEntityInput(ent_particle, "Stop");  
		CreateTimer(1.0, Timer_KillEntity, ent_particle);
		ents[client][2] = 0;
	}
}

public Action Timer_KillEntity(Handle timer, int entity) {
	if (IsValidEdict(entity)) {
		AcceptEntityInput(entity, "Kill");
		RemoveEdict(entity);
	}
	return Plugin_Handled;
}

int CreateDummyEnt() {
	int ent = CreateEntityByName("prop_dynamic_override");//	 pipe_bomb_projectile
	SetEntityModel(ent, MODEL_W_PIPEBOMB);	 // MODEL_W_PIPEBOMB
	DispatchSpawn(ent);  
	SetEntityMoveType(ent, MOVETYPE_NONE);   
	SetEntProp(ent, Prop_Send, "m_CollisionGroup", 2);   
	SetEntityRenderMode(ent, RenderMode:3);
	SetEntityRenderColor(ent, 0,0, 0,0);	
	return ent;
}

void CreateRope(int client, int target, float pos[3], float endpos[3], index = 0) {
	
	int dummy_target = CreateDummyEnt();
	int dummy_source = CreateDummyEnt();
	
	if(isInfected(target) || isSurvivor(target)) {
		SetVector(pos, 0.0, 0.0, 50.0);	
		AttachEnt(target, dummy_target, "", pos, NULL_VECTOR);
		SetVector(pos, 0.0, 0.0, 0.0);	
		targets[client]=target;
	} else {	
		targets[client]=0;
		TeleportEntity(dummy_target, endpos, NULL_VECTOR, NULL_VECTOR);
	}
	
	SetVector(pos,   10.0,  0.0, 0.0); 
	AttachEnt(client, dummy_source, "armL", pos, NULL_VECTOR);
	
	//TeleportEntity(dummy_source, pos, NULL_VECTOR, NULL_VECTOR);
		
	char dummy_target_name[64];
	char dummy_source_name[64];
	Format(dummy_target_name, sizeof(dummy_target_name), "target%d", dummy_target);
	Format(dummy_source_name, sizeof(dummy_source_name), "target%d", dummy_source);
	DispatchKeyValue(dummy_target, "targetname", dummy_target_name);
	DispatchKeyValue(dummy_source, "targetname", dummy_source_name);
	
	int particle = CreateEntityByName("info_particle_system");

	DispatchKeyValue(particle, "effect_name", particle_smoker_tongue);
	DispatchKeyValue(particle, "cpoint1", dummy_target_name);
	
	DispatchSpawn(particle);
	ActivateEntity(particle); 
	
	SetVector(pos, 0.0, 0.0, 0.0);	
	AttachEnt(dummy_source, particle, "", pos, NULL_VECTOR);
	
	AcceptEntityInput(particle, "start");  
	
	ents[client][0]=dummy_target;
	ents[client][1]=dummy_source;
	ents[client][2]=particle; 
}

void AttachEnt(int owner, int ent, char[] positon="medkit", float pos[3]=NULL_VECTOR,float ang[3]=NULL_VECTOR) {
	char tname[64];
	Format(tname, sizeof(tname), "target%d", owner);
	DispatchKeyValue(owner, "targetname", tname); 		
	DispatchKeyValue(ent, "parentname", tname);
	
	SetVariantString(tname);
	AcceptEntityInput(ent, "SetParent",ent, ent, 0); 	
	if(strlen(positon)!=0)
	{
		SetVariantString(positon); 
		AcceptEntityInput(ent, "SetParentAttachment");
	}
	TeleportEntity(ent, pos, ang, NULL_VECTOR);
}

bool IsEnt(int ent) {
	return ent && IsValidEdict(ent);
}

public Action:OnPlayerRunCmd(int client, &buttons, &impulse, float vel[3], float angles[3], &weapon) {

	if (grabber[client] && buttons & IN_ZOOM) {
		StopRope(grabber[client]);
	}

	if(!enabled[client]) return Plugin_Continue; 
	
	bool start_rope = ((buttons & IN_ZOOM) && !(button_last[client] & IN_ZOOM));
	bool on_ground = GetEntityFlags(client) & FL_ONGROUND ? true : false;

	if (isHookMode[client]) {
		if (((buttons & IN_ATTACK2) && !(button_last[client] & IN_ATTACK2)) && states[client] == NONE && !on_ground)
			StartRope(client);
		if (!(buttons & IN_ATTACK2) && button_last[client] & IN_ATTACK2 && states[client] == SHOT)
			StopRope(client);
	}

	if(start_rope) 
		if (states[client] == NONE)
			StartRope(client);
		else 
			StopRope(client);
	
	if(states[client]==SHOT)
	{

		int last_button=button_last[client];
		float engine_time= GetEngineTime();
		
		float duration=engine_time-time_last[client];
		if(duration>1.0)duration=1.0;
		else if(duration<=0.0)duration=0.01;
		time_last[client] = engine_time; 
		
	
		int target=targets[client];
		float target_position[3];
		
		
		
		float client_angle[3];
		GetClientEyeAngles(client, client_angle);  
		 
		float client_eye_position[3];
		GetClientEyePosition(client, client_eye_position);
		
		if(on_ground && GetVectorDistance(client_eye_position, position_target[client])>GetConVarFloat(l4d_rope_distance))
		{
			PrintCenterText(client, "broken because too far");
			StopRope(client);
			
			return Plugin_Continue;
		}
		
		if(IsEnt(target))
		{
			
			GetEntPropVector(target, Prop_Send, "m_vecOrigin", target_position);
			target_position[2]+=50.0;
			CopyVector(target_position, position_target[client] );	
		}
		else
		{
			targets[client]=0;
			if(target>0)
			{
				StopRope(client);
				return Plugin_Continue;
			}
			target=0; 
			CopyVector(position_target[client], target_position);	
		} 
		

		

		
		float dir[3];
		//drag target
		int press_drag = (buttons & IN_SPEED);

		if (isHookMode[client] && buttons & IN_ATTACK2)
			press_drag = true;

		if(target>0 && press_drag)
		{
			GetAngleVectors(client_angle, dir, NULL_VECTOR, NULL_VECTOR);
		 
			NormalizeVector(dir, dir);
			ScaleVector(dir, 90.0);
			AddVectors(dir, client_eye_position,client_eye_position);	
			
			float force[3];
			SubtractVectors(target_position, client_eye_position, force);
			float rope_length=GetVectorLength(force);
			scopes[client]=rope_length;
			
			NormalizeVector(force, force); 
 
			float drag_force=300.0;
			if(rope_length<50.0)drag_force=rope_length;
			
			ScaleVector(force, -1.0*drag_force);
			TeleportEntity(target, NULL_VECTOR, NULL_VECTOR,force);
			
			bool hurt_target=false;
			if(engine_time-time_hurt[client]>0.1)
			{
				hurt_target=true;
				time_hurt[client]=engine_time;
			}
			
			if(hurt_target && isInfected(target))
			{
				 
				DoPointHurtForInfected(target, client, GetConVarFloat(l4d_rope_damage));
				float angle[3];
				ScaleVector(force, -1.0);
				GetVectorAngles(force, angle);
				ShowParticle(target_position, angle, PARTICLE_BLOOD, 0.1);
			 
			}	
			
		} 
		else if(target==0)
		{ 
			float target_distacne=GetVectorDistance(target_position, client_eye_position);
			//scopes[client]=rope_length;
			if(on_ground)
			{
				on_ground=true; 
				SetEntityGravity(client, 1.0);
			}
			
			if(on_ground)
			{
				scopes[client]=target_distacne; 
				frees[client]=true;
			}
			else
			{
				
			}
 
			
			if(isHookMode[client] || !on_ground && (buttons & IN_SPEED))
			{
				scopes[client]-=360.0 * duration; 
				if(scopes[client]<20.0) scopes[client]=20.0;
				frees[client]=false;
				
			}
			if(!on_ground && (buttons & IN_DUCK))
			{
				scopes[client]+=350.0 * duration; 
				//if(scopes[client]<30.0) scopes[client]=30.0;
				frees[client]=false;
			} 
			
			if(!frees[client])
			{
				
				float diff=target_distacne-scopes[client];
				if(diff>20.0)
				{
					if((client_eye_position[2]<target_position[2]))scopes[client]=target_distacne-20.0;
					diff=20.0;
				}
				if(diff>0)
				{
					//SetEntityGravity(client, 1.0);
					float grivaty_dir[3];
					grivaty_dir[2]=-1.0;
				
								 	
					float drag_dir[3];
					SubtractVectors(target_position, client_eye_position,drag_dir);
					NormalizeVector(drag_dir, drag_dir); 
					
					float add_force_dir[3];
					AddVectors(grivaty_dir,drag_dir,add_force_dir);
					NormalizeVector(add_force_dir, add_force_dir); 
					
					
					float client_vel[3];
					GetEntDataVector(client, g_iVelocity, client_vel);
					

					
					float plane[3];
					CopyVector(drag_dir, plane);
					//GetVectorCrossProduct(client_vel, drag_dir, plane);
					
					float vel_on_plane[3];
					GetProjection(plane, client_vel, vel_on_plane); 
			 		
					
					
					float factor=diff/20.0;
					
					ScaleVector(drag_dir, factor*350.0);
					//ScaleVector(client_vel, 1.0-factor);
					
					float new_vel[3];
					AddVectors(vel_on_plane,drag_dir,new_vel); 
	 	
					if(client_eye_position[2]<target_position[2])
					{
						TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, new_vel);
					}
				 		
					if((buttons & IN_JUMP) && !(last_button & IN_JUMP) && engine_time-time_jump[client]>1.0)
					{
						time_jump[client]=engine_time;
						// float dir[3];
						GetAngleVectors(client_angle, dir, NULL_VECTOR, NULL_VECTOR); 
						NormalizeVector(dir, dir);
						
						grivaty_dir[2]=1.0;
						AddVectors(dir,grivaty_dir,dir);
						//dir[2]=1.0;
						NormalizeVector(dir, dir);
						ScaleVector(dir, 3000.0);
						TeleportEntity(client, NULL_VECTOR, NULL_VECTOR,dir);
						scopes[client]+=10.0;
					}
				} 
				else 
				{
					//SetEntityGravity(client, 1.0);
				}
					
			}
			else
			{
				if(GetVectorDistance(target_position, client_eye_position)>GetConVarFloat(l4d_rope_distance))
				{
					StopRope(client);
					return Plugin_Continue;
				}
			}

			CheckSpeed(client);		
			
		}
	}

	
	button_last[client]=buttons;
	return Plugin_Continue;
}
CheckSpeed(client)
{
	float velocity[3];
	GetEntDataVector(client, g_iVelocity, velocity);
	float vel=GetVectorLength(velocity);
	if(vel>500.0)
	{
		NormalizeVector(velocity, velocity);
		ScaleVector(velocity, 500.0);
		TeleportEntity(client, NULL_VECTOR, NULL_VECTOR,velocity);
	}
}
 
CopyVector(float source[3], float target[3])
{
	target[0]=source[0];
	target[1]=source[1];
	target[2]=source[2];
}
SetVector(float target[3], float x, float y, float z)
{
	target[0]=x;
	target[1]=y;
	target[2]=z;
}

GameCheck()
{
	char GameName[16];
	GetConVarString(FindConVar("mp_gamemode"), GameName, sizeof(GameName));
 
	GetGameFolderName(GameName, sizeof(GameName));
	if (StrEqual(GameName, "left4dead2", false))
	{
		ZOMBIECLASS_TANK=8;
		L4D2Version=true;
	}	
	else
	{
		ZOMBIECLASS_TANK=5;
		L4D2Version=false;
	}
}

public bool TraceRayDontHitSelfAndHuman(entity, mask, any:data)
{
	if(entity == data) 
	{
		return false; 
	} 
	if(entity<=MaxClients && entity>0)
	{
		if(IsClientInGame(entity) && IsPlayerAlive(entity) && GetClientTeam(entity)==2)
		{
			return false; 
		}
	}
	return true;
} 
public bool TraceRayDontHitSelf(entity, mask, any:data)
{
	if(entity == data) 
	{
		return false; 
	} 
	
	return true;
} 
public bool TraceRayDontHitAlive(entity, mask, any:data)
{
	if(entity==0)return false;
	if(entity == data) 
	{
		return false; 
	} 
	if(entity<=MaxClients && entity>0)
	{
		return false;  
	}
	else 
	{
		char classname[32];
		GetEdictClassname(entity, classname,32);
		if(StrEqual(classname, "infected", true) || StrEqual(classname, "witch", true) )
		{
			return false;  
		}
	}
	return true;
} 
CreatePointHurt()
{
	int pointHurt=CreateEntityByName("point_hurt");
	if(pointHurt)
	{

		DispatchKeyValue(pointHurt,"Damage","10");
		DispatchKeyValue(pointHurt,"DamageType","2");
		DispatchSpawn(pointHurt);
	}
	return pointHurt;
}
DoPointHurtForInfected(victim, attacker=0,  float damage=0.0)
{
	static char N[20];
	if(g_PointHurt > 0)
	{
		if(IsValidEdict(g_PointHurt))
		{
			if(victim>0 && IsValidEdict(victim))
			{		
				Format(N, 20, "target%d", victim);
				DispatchKeyValue(victim,"targetname", N);
				DispatchKeyValue(g_PointHurt,"DamageTarget", N);
				//DispatchKeyValue(g_PointHurt,"classname","");
				DispatchKeyValueFloat(g_PointHurt,"Damage", damage);
				DispatchKeyValue(g_PointHurt,"DamageType","-2130706430");
				AcceptEntityInput(g_PointHurt,"Hurt",(attacker>0) ? attacker : -1);
			}
		}
		else g_PointHurt=CreatePointHurt();
	}
	else g_PointHurt=CreatePointHurt();
}

public PrecacheParticle(String:particlename[])
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
public Action:DeleteParticles(Handle:timer, any:particle)
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
public Action:DeleteParticletargets(Handle:timer, any:target)
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
}
public ShowParticle(float pos[3], float ang[3],String:particlename[], float time)
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

GetEnt(client, float pos[3], float angle[3], float hitpos[3])
{

	Handle trace= TR_TraceRayFilterEx(pos, angle, MASK_SOLID, RayType_Infinite, TraceRayDontHitSelf2, client); 
	int ent=-1;
 
	if(TR_DidHit(trace))
	{			
		ent=0;
		TR_GetEndPosition(hitpos, trace);
		ent=TR_GetEntityIndex(trace);
	}
	CloseHandle(trace); 

	return ent;
}
public bool TraceRayDontHitSelf2 (entity, mask, any:data)
{
	if(entity<=0)return false;
	if(entity == data) 
	{
		return false; 
	}
	
	return true;
}

/* 
* get vector t's projection on a plane, the plane's normal vector is n, r is the result
*/
GetProjection(float n[3], float t[3], float r[3])
{
	float A=n[0];
	float B=n[1];
	float C=n[2];
	
	float a=t[0];
	float b=t[1];
	float c=t[2];
	
	float p=-1.0*(A*a+B*b+C*c)/(A*A+B*B+C*C);
	r[0]=A*p+a;
	r[1]=B*p+b;
	r[2]=C*p+c; 
	//AddVectors(p, r, r);
}

bool isHumanSurvivor(int client) {
	return isSurvivor(client) && !IsFakeClient(client);
}

bool isInfected(int client) {
	return isClient(client) && GetClientTeam(client) == 3;
}

bool isSurvivor(int client) {
	return isClient(client) && GetClientTeam(client) == 2;
}

bool isClient(int client) {
	return isClientIndex(client) && IsValidEntity(client) && IsClientInGame(client);
}

bool isClientIndex(int client) {
	return (1 <= client <= MaxClients);
}