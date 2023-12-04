#define PLUGIN_VERSION "2.0.2"
#define PLUGIN_NAME		"l4d_rope"
#define PLUGIN_PHRASES	"l4d_rope.phrases"

#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

/**
 *	v2.0 new features:
 *		new rope mode 'hook', press shove on air to shoot and auto tighten, release key to release rope
 *		translation (english/chinese preset) supports and announce position support 
 *		make +zoom key dont shoot under hook mode, we can use sniper now
 *		completely turn to new syntax
 *		code clean and remove unused code
 *		plugin name/config/translation now "l4d_rope"
 *		use safe SDK takedamage to instead point_hurt entity
 *		optional 'hook chance from looted'
 *		optional 'specify admin flag to access ropes command'
 *		optional 'deny or allow infected to use'
 *		fix entity not be remove cause server no free edicts
 *		rope grabbed target can press zoom key to release from grab; 23-2-22
 *	v2.0.1 hold ctrl can landing under hook mode rather than stopping at air; 25-2-22
 *	v2.0.2 fix compile warn and error at SM1.10; 26-2-22
 * 
 */

#define ANNOUNCE_CENTER	(1 << 0)
#define ANNOUNCE_CHAT	(1 << 1)
#define ANNOUNCE_HINT	(1 << 2)

#define SOUND_FIRE				"player/smoker/miss/smoker_reeltonguein_01.wav"
 
#define MODEL_W_PIPEBOMB		"models/w_models/weapons/w_eq_pipebomb.mdl"
#define particle_smoker_tongue	"smoker_tongue"

#define Pai 3.141592653589793

static bool hasTranslations;

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
float position_target[MAXPLAYERS+1][3];
bool isHookMode[MAXPLAYERS+1];
int button_last[MAXPLAYERS+1];

ConVar Plugin_enabled;
ConVar Rope_damage;			float rope_damage;
ConVar Rope_distance;		float rope_distance;
ConVar Rope_chance_witch;	float rope_chance_witch;
ConVar Rope_chance_tank;	float rope_chance_tank;
ConVar Announce_types;		int announce_types;
ConVar Access;				int access;
ConVar Rope_chance_hook;	float rope_chance_hook;
ConVar Allow_infected;		bool allow_infected;
 
int g_iVelocity = 0;

public Plugin myinfo = {
	name = "Rope & Hook <fork>",
	author = " pan xiao hai & NoroHime",
	description = "Swinging Rope like Tarzan",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?p=2050712"
}

public void OnPluginStart() { 	 
	
	g_iVelocity =		FindSendPropInfo("CBasePlayer", "m_vecVelocity[0]");

	CreateConVar("rope_version", PLUGIN_VERSION, "Version of 'Rope & Hook <fork>'", FCVAR_SPONLY|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
	Plugin_enabled =	CreateConVar("rope_enabled", "1", "enable 'Rope & Hook'", FCVAR_NOTIFY);
	Rope_damage =		CreateConVar("rope_damage", "10", "rope damage when attack infected", FCVAR_NOTIFY);
 	Rope_distance =		CreateConVar("rope_distance", "900.0", "rope max distance allowed", FCVAR_NOTIFY);
 
	Rope_chance_witch =	CreateConVar("rope_chance_witch", "50.0", "chance of witch loot 100:certainly", FCVAR_NOTIFY);
 	Rope_chance_tank =	CreateConVar("rope_chance_tank", "50.0", "chance of tank loot 100:certainly", FCVAR_NOTIFY);
	Rope_chance_hook =	CreateConVar("rope_chance_hook", "50", "chance to get hook if looted from witch&tank", FCVAR_NOTIFY);
	Announce_types =	CreateConVar("rope_announce_types", "4", "announce positions 1=center 2=chat 4=hint 7=all. add together you want", FCVAR_NOTIFY);
	Access =			CreateConVar("rope_access", "f", "admin flag to access rope cmd f:slay, leave empty to allow everyone", FCVAR_NOTIFY);
	Allow_infected =	CreateConVar("rope_allow_infected", "0", "also allow infected team use rope", FCVAR_NOTIFY);

	RegConsoleCmd("sm_rope", sm_rope);
	RegConsoleCmd("sm_hook", sm_hook);

	char path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, PLATFORM_MAX_PATH, "translations/%s.txt", PLUGIN_PHRASES);
	hasTranslations = FileExists(path);

	if (hasTranslations)
		LoadTranslations(PLUGIN_PHRASES);
	
	Rope_damage.AddChangeHook(OnConVarChanged);
	Rope_distance.AddChangeHook(OnConVarChanged);
	Rope_chance_witch.AddChangeHook(OnConVarChanged);
	Rope_chance_hook.AddChangeHook(OnConVarChanged);
	Announce_types.AddChangeHook(OnConVarChanged);
	Access.AddChangeHook(OnConVarChanged);
	Allow_infected.AddChangeHook(OnConVarChanged);
	
	AutoExecConfig(true, PLUGIN_NAME);  
}

public void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue) {
	ApplyCvars();
}

public void OnConfigsExecuted() {
	ApplyCvars();
}

public void ApplyCvars() {

	static char flags[32];
	static bool hooked = false;
	bool plugin_enabled = Plugin_enabled.BoolValue;

	if (plugin_enabled && !hooked) {

		HookEvent("player_spawn", player_spawn);
		HookEvent("player_death", player_death);
		HookEvent("player_bot_replace", player_bot_replace);
		HookEvent("bot_player_replace", bot_player_replace);
		HookEvent("round_start", round_end);
		HookEvent("round_end", round_end);
		HookEvent("finale_win", round_end);
		HookEvent("mission_lost", round_end);
		HookEvent("map_transition", round_end);
		HookEvent("witch_killed", witch_killed);
		HookEvent("tank_killed", tank_killed);

		hooked = true;

	} else if (!plugin_enabled && hooked) {

		UnhookEvent("player_spawn", player_spawn);
		UnhookEvent("player_death", player_death);
		UnhookEvent("player_bot_replace", player_bot_replace);
		UnhookEvent("bot_player_replace", bot_player_replace);
		UnhookEvent("round_start", round_end);
		UnhookEvent("round_end", round_end);
		UnhookEvent("finale_win", round_end);
		UnhookEvent("mission_lost", round_end);
		UnhookEvent("map_transition", round_end);
		UnhookEvent("witch_killed", witch_killed);
		UnhookEvent("tank_killed", tank_killed);

		hooked = false;
	}

	rope_damage = Rope_damage.FloatValue;
	rope_distance = Rope_distance.FloatValue;
	rope_chance_witch = Rope_chance_witch.FloatValue;
	rope_chance_tank = Rope_chance_tank.FloatValue;
	rope_chance_hook = Rope_chance_hook.FloatValue;
	announce_types = Announce_types.IntValue;
	Access.GetString(flags, sizeof(flags));
	access = flags[0] ? ReadFlagString(flags) : 0;
	allow_infected = Allow_infected.BoolValue;
}

bool HasPermision(int client) {

	int flag_client = GetUserFlagBits(client);

	if (!access || flag_client & ADMFLAG_ROOT) return true;

	return view_as<bool>(flag_client & access);
}

public void OnMapStart() {
	ResetAllState();
	PrecacheModel(MODEL_W_PIPEBOMB);
	PrecacheSound(SOUND_FIRE); 
} 

public void round_start(Event event, const char[] name, bool dontBroadcast) {
	ResetAllState();
}
 
public void round_end(Event event, const char[] name, bool dontBroadcast) {
	ResetAllState();
}

void ResetAllState() {
	for(int i = 1; i <= MaxClients; i++)
		ResetClientState(i); 
}

void ResetClientState(int client) {
	enabled[client] = false;
	states[client] = NONE;
	ents[client][0] = 0;
	ents[client][1] = 0;
	ents[client][2] = 0;
}

public Action sm_rope(int client, int args) {
	if(isAliveHumanClient(client)) {
		if (HasPermision(client))
			if(enabled[client]) {
				if (isHookMode[client]) {
					Announce(client, "%t", "Switched", "Rope");
					isHookMode[client] = false;
				} else
					DisableRope(client);
			} else {
				isHookMode[client] = false;
				EnableRope(client);
			}
		else 
			Announce(client, "%t", "Denied");
	}
	return Plugin_Handled;
}

public Action sm_hook(int client, int args) {
	if(isAliveHumanClient(client)) {
		if (HasPermision(client)) {
			if(enabled[client]) {
				if (!isHookMode[client]) {
					Announce(client, "%t", "Switched", "Hook");
					isHookMode[client] = true;
				} else
					DisableRope(client);
			} else {
				isHookMode[client] = true;
				EnableRope(client);
			}
		} else {
			Announce(client, "%t", "Denied");
		}
	}
	return Plugin_Handled;
}

void GiveRope(int client) {
	if(isAliveHumanClient(client) && !enabled[client]) {
		bool hooks = rope_chance_hook > GetRandomFloat(0.0, 100.0);
		isHookMode[client] = hooks;
		EnableRope(client);
	}
}

public void witch_killed(Event event, const char[] name, bool b_DontBroadcast) { 
	int attacker = GetClientOfUserId(event.GetInt("userid"));
	if (isAliveHumanClient(attacker) && !enabled[attacker]) {
		if(GetRandomFloat(0.0, 100.0) < rope_chance_witch) {
			GiveRope(attacker);
		}
	}
}
public void tank_killed(Event event, const char[] name, bool DontBroadcast) {
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	if (isAliveHumanClient(attacker) && !enabled[attacker]) {
		if(GetRandomFloat(0.0, 100.0) < rope_chance_tank) {
			GiveRope(attacker);
		}
	}
}

public void player_bot_replace(Event event, const char[] name, bool Spawn_Broadcast) {
	int client = GetClientOfUserId(event.GetInt("player"));
	int bot = GetClientOfUserId(event.GetInt("bot"));

	if(enabled[client])
		DisableRope(client);

	ResetClientState(client);
	ResetClientState(bot);

}
public void bot_player_replace(Event event, const char[] name, bool Spawn_Broadcast) {
	int client = GetClientOfUserId(event.GetInt("player"));
	int bot = GetClientOfUserId(GetEventInt(event, "bot"));

	if(enabled[client])
		DisableRope(client);

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

void DisableRope(int client) {
	if (enabled[client]) {
		StopRope(client);
		enabled[client] = false;
		Announce(client, "%t", "Dropped", isHookMode[client] ? "Hook" : "Rope"); 
	}
}
void EnableRope(int client) {

	if (!allow_infected && isInfected(client)) {
		Announce(client, "%t", "Not Allowed");
		return;
	}

	if(enabled[client]) return;
	enabled[client] = true;
	states[client] = NONE;
	
	Announce(client, "%t", isHookMode[client] ? "Usage Hook" : "Usage Rope");
}

int grabber[MAXPLAYERS + 1];

void StartRope(int client) {
	if(states[client] != NONE) return;
	
	float pos[3], angle[3], hitpos[3];
	GetClientEyePosition(client, pos);
	GetClientEyeAngles(client, angle);	
 
	int target = GetEnt(client, pos, angle, hitpos); 
	if(GetVectorDistance(pos, hitpos) > rope_distance) {
		Announce(client, "%t", "Far", isHookMode[client] ? "Hook" : "Rope");
		return;
	}

	scopes[client] = GetVectorDistance(pos, hitpos);
	frees[client] = true;

	time_hurt[client] = GetEngineTime() - 1.0;
	time_last[client] = GetEngineTime() - 0.01;
	time_jump[client] = GetEngineTime() - 0.5;
	
	states[client] = SHOT; 
	CreateRope(client, target, pos, hitpos); 
	CopyVector(hitpos, position_target[client]);
	
	if (isClient(target)) {
		grabber[target] = client;
		Announce(client, "%t", "Grabbed", target);
	}
	EmitSoundToAll(SOUND_FIRE, 0,  SNDCHAN_WEAPON, SNDLEVEL_NORMAL, SND_NOFLAGS, 1.0, SNDPITCH_NORMAL, -1, pos, NULL_VECTOR, true, 0.0);

}

static const float VOID_VECTOR[3];
void StopRope(int client) {

	if (states[client] == SHOT) {
		states[client]=NONE;
		
		ClearClientEnts(client);

		for (int i = 1; i <= MaxClients; i++) {
			if (grabber[i] == client)
				grabber[i] = 0;
		}
	}
}

void ClearClientEnts(int client) {
	int ent_target = ents[client][0],
		ent_source = ents[client][1],
		ent_particle = ents[client][2];

	if (IsValidEdict(ent_target)) {
		AcceptEntityInput(ent_target, "ClearParent");  
		TeleportEntity(ent_target, VOID_VECTOR, NULL_VECTOR, NULL_VECTOR);
		ents[client][0] = 0;
		CreateTimer(1.0, Timer_KillEntity, ent_target);
	}

	if (IsValidEdict(ent_source)) {
		AcceptEntityInput(ent_source, "ClearParent");  
		TeleportEntity(ent_source, VOID_VECTOR, NULL_VECTOR, NULL_VECTOR);
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
	SetEntityRenderMode(ent, view_as<RenderMode>(3));
	SetEntityRenderColor(ent, 0,0, 0,0);	
	return ent;
}

void CreateRope(int client, int target, float pos[3], float endpos[3]) {
	
	int dummy_target = CreateDummyEnt();
	int dummy_source = CreateDummyEnt();
	
	if(isClient(target)) {
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

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon) {

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

	if (start_rope && !isHookMode[client]) 
		if (states[client] == NONE)
			StartRope(client);
		else 
			StopRope(client);
	
	if (states[client] == SHOT) {

		int last_button = button_last[client];
		float engine_time = GetEngineTime();
		
		float duration = engine_time-time_last[client];

		if(duration > 1.0)
			duration=1.0;
		else if (duration <= 0.0)
			duration=0.01;

		time_last[client] = engine_time; 
		
		int target = targets[client];
		float target_position[3];
		
		float client_angle[3];
		GetClientEyeAngles(client, client_angle);  
		 
		float client_eye_position[3];
		GetClientEyePosition(client, client_eye_position);
		
		if (on_ground && GetVectorDistance(client_eye_position, position_target[client]) > rope_distance) {
			Announce(client, "%t", "Far", isHookMode[client] ? "Hook" : "Rope");
			StopRope(client);
			return Plugin_Continue;
		}
		
		if (IsEnt(target)) {
			GetEntPropVector(target, Prop_Send, "m_vecOrigin", target_position);
			target_position[2] += 50.0;
			CopyVector(target_position, position_target[client]);	
		} else {
			targets[client] = 0;
			if(target > 0) {
				StopRope(client);
				return Plugin_Continue;
			}
			target = 0; 
			CopyVector(position_target[client], target_position);	
		} 
		
		float dir[3];
		int press_drag = (buttons & IN_SPEED);

		if (isHookMode[client] && buttons & IN_ATTACK2)
			press_drag = true;

		if (target > 0 && press_drag) {
			GetAngleVectors(client_angle, dir, NULL_VECTOR, NULL_VECTOR);
		 
			NormalizeVector(dir, dir);
			ScaleVector(dir, 90.0);
			AddVectors(dir, client_eye_position,client_eye_position);	
			
			float force[3];
			SubtractVectors(target_position, client_eye_position, force);
			float rope_length = GetVectorLength(force);
			scopes[client] = rope_length;
			
			NormalizeVector(force, force); 
 
			float drag_force = 300.0;
			if (rope_length < 50.0)drag_force = rope_length;
			
			ScaleVector(force, -1.0 * drag_force);
			TeleportEntity(target, NULL_VECTOR, NULL_VECTOR,force);
			
			bool hurt_target = false;
			if (engine_time - time_hurt[client]>0.1)
			{
				hurt_target = true;
				time_hurt[client] = engine_time;
			}
			
			if(hurt_target && isInfected(target)) {
				SDKHooks_TakeDamage(target, 0, client, rope_damage, DMG_ENERGYBEAM);
			}	
		} else if(target == 0) { 
			float target_distacne=GetVectorDistance(target_position, client_eye_position);
			if (on_ground) {
				on_ground = true; 
				SetEntityGravity(client, 1.0);
			}
			
			if (on_ground) {
				scopes[client] = target_distacne; 
				frees[client] = true;
			}
 
			
			if (!on_ground && (isHookMode[client] && !(buttons & IN_DUCK)) || (buttons & IN_SPEED)) {
				scopes[client] -= 360.0 * duration; 
				if (scopes[client] < 20.0) scopes[client] = 20.0;
				frees[client] = false;
				
			}
			if (!on_ground && (buttons & IN_DUCK)) {
				scopes[client] += 350.0 * duration; 
				frees[client] = false;
			} 
			
			if (!frees[client]) {
				
				float diff = target_distacne-scopes[client];
				if (diff > 20.0) {
					if ((client_eye_position[2] < target_position[2]))
						scopes[client] = target_distacne-20.0;
					diff = 20.0;
				}
				if (diff > 0) {
					float grivaty_dir[3];
					grivaty_dir[2] =- 1.0;
								 	
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
					
					float vel_on_plane[3];
					GetProjection(plane, client_vel, vel_on_plane); 
			 		
					float factor = diff / 20.0;
					
					ScaleVector(drag_dir, factor * 350.0);
					
					float new_vel[3];
					AddVectors(vel_on_plane,drag_dir,new_vel); 
	 	
					if(client_eye_position[2] < target_position[2]) {
						TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, new_vel);
					}
				 		
					if((buttons & IN_JUMP) && !(last_button & IN_JUMP) && engine_time - time_jump[client] > 1.0) {
						time_jump[client] = engine_time;
						GetAngleVectors(client_angle, dir, NULL_VECTOR, NULL_VECTOR); 
						NormalizeVector(dir, dir);
						
						grivaty_dir[2] = 1.0;
						AddVectors(dir,grivaty_dir,dir);
						NormalizeVector(dir, dir);
						ScaleVector(dir, 3000.0);
						TeleportEntity(client, NULL_VECTOR, NULL_VECTOR,dir);
						scopes[client] += 10.0;
					}
				}
					
			} else {
				if(GetVectorDistance(target_position, client_eye_position) > rope_distance) {
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

void CheckSpeed(int client) {

	float velocity[3];
	GetEntDataVector(client, g_iVelocity, velocity);

	float vel = GetVectorLength(velocity);

	if(vel > 500.0) {

		NormalizeVector(velocity, velocity);
		ScaleVector(velocity, 500.0);
		TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, velocity);
	}
}
 
void CopyVector(float source[3], float target[3]) {
	target[0] = source[0];
	target[1] = source[1];
	target[2] = source[2];
}

void SetVector(float target[3], float x, float y, float z) {
	target[0] = x;
	target[1] = y;
	target[2] = z;
}


int GetEnt(int client, float pos[3], float angle[3], float hitpos[3]) {

	Handle trace = TR_TraceRayFilterEx(
		pos, 
		angle, 
		MASK_SOLID, 
		RayType_Infinite, 
		TraceRayDontHitSelf2, 
		client
	);

	int ent =-1;
 
	if (TR_DidHit(trace)) {			
		ent = 0;
		TR_GetEndPosition(hitpos, trace);
		ent = TR_GetEntityIndex(trace);
	}

	CloseHandle(trace); 
	return ent;
}
public bool TraceRayDontHitSelf2 (int entity, int contentsMask, any data) {
	return !(entity <= 0 || entity == data);
}

void GetProjection(float n[3], float t[3], float r[3]) {
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
}

void Announce(int client, const char[] format, any ...) {

	static char buffer[254];

	SetGlobalTransTarget(client);
	VFormat(buffer, sizeof(buffer), format, 3);
	ReplaceColor(buffer, sizeof(buffer));

	if (isClient(client)) {

		if (announce_types & ANNOUNCE_CHAT)
			PrintToChat(client, "%s", buffer);

		if (announce_types & ANNOUNCE_HINT)
			PrintHintText(client, "%s", buffer);

		if (announce_types & ANNOUNCE_CENTER)
			PrintCenterText(client, "%s", buffer);
	}
}

stock void ReplaceColor(char[] message, int maxLen) {

	ReplaceString(message, maxLen, "{white}", "\x01", false);
	ReplaceString(message, maxLen, "{default}", "\x01", false);
	ReplaceString(message, maxLen, "{cyan}", "\x03", false);
	ReplaceString(message, maxLen, "{lightgreen}", "\x03", false);
	ReplaceString(message, maxLen, "{orange}", "\x04", false);
	ReplaceString(message, maxLen, "{olive}", "\x04", false);
	ReplaceString(message, maxLen, "{green}", "\x05", false);
}


bool isInfected(int client) {
	return isClient(client) && GetClientTeam(client) == 3;
}

bool isAliveHumanClient(int client) {
	return isAliveClient(client) && !IsFakeClient(client);
}

bool isAliveClient(int client) {
	return isClient(client) && IsPlayerAlive(client);
}

bool isClient(int client) {
	return isClientIndex(client) && IsValidEntity(client) && IsClientInGame(client);
}

bool isClientIndex(int client) {
	return (1 <= client <= MaxClients);
}
