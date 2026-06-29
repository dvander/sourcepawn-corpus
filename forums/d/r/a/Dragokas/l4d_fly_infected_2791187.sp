#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>

//#define SOUNDMISSILELOCK "UI/Beep07.wav" 

#define FilterSelf 0
#define FilterSelfAndPlayer 1
#define FilterSelfAndSurvivor 2
#define FilterSelfAndInfected 3
#define FilterSelfAndPlayerAndCI 4

#define State_NotHandle -1
#define State_None 0
#define State_Start 1
#define State_Fly 2

int JetPack[MAXPLAYERS+1][2];
int Flame[MAXPLAYERS+1][2];
int ClientState[MAXPLAYERS+1];
int LastButton[MAXPLAYERS+1];
int Enemy[MAXPLAYERS+1];
//int Clone[MAXPLAYERS+1];
int g_iVelocity;
int g_iLight[6][MAXPLAYERS+1];

float ClientVelocity[MAXPLAYERS+1][3];
float LastTime[MAXPLAYERS+1]; 
float LastPos[MAXPLAYERS+1][3]; 
float FireTime[MAXPLAYERS+1]; 
float StartTime[MAXPLAYERS+1];
float ScanTime[MAXPLAYERS+1];

ConVar l4d_flyinfected_chance_throw;
ConVar l4d_flyinfected_chance_tankclaw;
ConVar l4d_flyinfected_chance_tankjump;
ConVar l4d_flyinfected_speed; 
ConVar l4d_flyinfected_maxtime;
//ConVar l4d_flyinfected_health;
ConVar l4d_flyinfected_tankjump_apex;
ConVar l4d_flyinfected_remove_ragdoll;
ConVar g_ConVarDifficulty;
ConVar l4d_flyinfected_shove_on_fly;
ConVar l4d_flyinfected_shove_turn_around;
ConVar l4d_flyinfected_chance;
ConVar l4d_flyinfected_number;
ConVar l4d_flyinfected_allow_easy;
ConVar l4d_flyinfected_allow_normal;
ConVar l4d_flyinfected_allow_hard;
ConVar l4d_flyinfected_allow_expert;

bool g_bLateload;
bool g_bLeft4Dead2;
bool g_bEasy = false;
bool g_bNormal = false;
bool g_bHard = false;
bool g_bExpert = false;

#define PLUGIN_VERSION "2.0.7"
#define CVAR_FLAGS	  FCVAR_NOTIFY

public Plugin myinfo = 
{
	name = "[L4D] DragoTanks: Sky Tank (Archon)",
	author = "Pan Xiaohai & AlexMy & Dragokas",
	description = "",
	version = PLUGIN_VERSION,
	url = "https://github.com/dragokas/"
}

/*
	Fork by Dragokas
	(based on AlexMy's pre-2.0 fork release ver. of "'Fly infected' by Pan Xiaohai" as more stable in my opinion and testing)
	
	Credits:
	 - Pan Xiaohai - for the original plugin
	 - AlexMy - for several modifications and crash fix
	
	ChangeLog:
	
	2.0.1
	 - Removed code to set tank health.
	 - Removed code for resetting tank color.
	 - Removed "missile lock" sound.
	
	2.0.2
	 - Added restriction to handle only first tank as fly tank (new tank state: State_NotHandle)
	 - Added coloring fly tank with cyan
	 - Fixed one memory leak (in trace handles)
	 - complete convertion to new methodmaps
	 - some code optimizations
	 - stop fly when player showed the tank
	 - more reliable check of game version
	 
	2.0.3
	 - Added "oracle" lights (thanks to "BHaType" for some code samples)
	 - Begin tank fly once it is spawned
	 - Optimized jetpack code, now jetpack and flame doesn't disappear once tank is stopping to fly
	 - Plugin is renamed to "Sky Tank"
	 - Removed unused code (clone, <sdktools_functions>).
	 - Added "l4d_flyinfected_remove_ragdoll" ConVar to remove tank ragdoll immediately after death.
	 
	2.0.4 (hard)
	 - Plugin is activated only in Hard / Expert game difficulty
	 
	2.0.5
	 - Added changing the angle of all infected on shove
	 
	2.0.6 (11-May-2020)
	 - L4D2 compatibility
*/

public APLRes AskPluginLoad2(Handle myself, bool late, char [] error, int err_max) 
{
	EngineVersion test = GetEngineVersion();
	if (test == Engine_Left4Dead2) {
		g_bLeft4Dead2 = true;
	}
	else if (test != Engine_Left4Dead) {
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 1 & 2.");
		return APLRes_SilentFailure;
	}
	g_bLateload = late;
	return APLRes_Success;
}

public void OnPluginStart()
{
	CreateConVar( "l4d_flyinfected_version", PLUGIN_VERSION, "Plugin version", FCVAR_DONTRECORD | FCVAR_NOTIFY );

	l4d_flyinfected_chance_throw    	= 	CreateConVar("l4d_flyinfected_chance_throw", 		"30.0", 	"Chance after roch throw [0.0, 100.0]", CVAR_FLAGS);	
 	l4d_flyinfected_chance_tankclaw 	= 	CreateConVar("l4d_flyinfected_chance_tankclaw", 	"10.0", 	"Chance after hit [0.0, 100.0]", CVAR_FLAGS);	
 	l4d_flyinfected_chance_tankjump 	= 	CreateConVar("l4d_flyinfected_chance_tankjump", 	"20.0", 	"Chance after jump [0.0, 100.0]", CVAR_FLAGS);
	l4d_flyinfected_tankjump_apex   	= 	CreateConVar("l4d_flyinfected_tankjump_apex", 		"25.0", 	"Chance if dropped from a height [0.0, 100.0]", CVAR_FLAGS);
	l4d_flyinfected_speed           	= 	CreateConVar("l4d_flyinfected_speed", 				"300.0",	"Fly speed", CVAR_FLAGS);	
 	l4d_flyinfected_maxtime         	= 	CreateConVar("l4d_flyinfected_maxtime", 			"10.0", 	"Maximum time", CVAR_FLAGS);
	l4d_flyinfected_remove_ragdoll  	= 	CreateConVar("l4d_flyinfected_remove_ragdoll", 		"1", 		"Remove body instantly after the death? [0 - No, 1 - Yes]", CVAR_FLAGS);
	l4d_flyinfected_shove_on_fly		=	CreateConVar("l4d_flyinfected_shove_on_fly", 		"1", 		"Drop a tank on-the-fly with a shove? [0 - No, 1 - Yes]", CVAR_FLAGS);
	l4d_flyinfected_shove_turn_around	=	CreateConVar("l4d_flyinfected_shove_turn_around", 	"1", 		"Turn around tank on shove (work globally)? [0 - No, 1 - Yes]", CVAR_FLAGS);
	l4d_flyinfected_chance 				= 	CreateConVar("l4d_flyinfected_chance", 				"100", 		"% chance the archon tank appear", CVAR_FLAGS);
	l4d_flyinfected_number 				= 	CreateConVar("l4d_flyinfected_number", 				"1", 		"When this number of tanks appeared simultaneously, convert last tank to archon", CVAR_FLAGS);
	l4d_flyinfected_allow_easy 			= 	CreateConVar("l4d_flyinfected_allow_easy", 			"1", 		"Allow archon tank on game difficulty: Easy? (0 - No, 1 - Yes)", CVAR_FLAGS);
	l4d_flyinfected_allow_normal		= 	CreateConVar("l4d_flyinfected_allow_normal", 		"1", 		"Allow archon tank on game difficulty: Normal? (0 - No, 1 - Yes)", CVAR_FLAGS);
	l4d_flyinfected_allow_hard 			= 	CreateConVar("l4d_flyinfected_allow_hard", 			"1", 		"Allow archon tank on game difficulty: Hard? (0 - No, 1 - Yes)", CVAR_FLAGS);
	l4d_flyinfected_allow_expert 		= 	CreateConVar("l4d_flyinfected_allow_expert", 		"1", 		"Allow archon tank on game difficulty: Expert? (0 - No, 1 - Yes)", CVAR_FLAGS);
	
	AutoExecConfig(true, "l4d_fly_infected"); 
 
	HookEvent("round_start",    RoundStart,			EventHookMode_PostNoCopy);
	HookEvent("round_end",      RoundStart,			EventHookMode_PostNoCopy);
	HookEvent("finale_win",     RoundStart,			EventHookMode_PostNoCopy);
	HookEvent("mission_lost",   RoundStart,			EventHookMode_PostNoCopy);
	HookEvent("map_transition", RoundStart,			EventHookMode_PostNoCopy);	
 
	HookEvent("ability_use",      ability_use,      EventHookMode_Post);
	HookEvent("weapon_fire",      weapon_fire,      EventHookMode_Post);
	HookEvent("player_jump",      player_jump,      EventHookMode_Post);
	HookEvent("player_jump_apex", player_jump_apex, EventHookMode_Post);
	HookEvent("player_shoved", 	  player_shoved, 	EventHookMode_Post);
	HookEvent("tank_spawn",       tank_spawn,  		EventHookMode_Post);
	//HookEvent("player_spawn",     player_spawn,  	EventHookMode_Post);
	
	HookEvent("player_hurt",    player_hurt, 		EventHookMode_Pre);
	HookEvent("player_death",   player_death,		EventHookMode_Pre);
	
	g_iVelocity = FindSendPropInfo("CBasePlayer", "m_vecVelocity[0]");
	
	g_ConVarDifficulty = FindConVar("z_difficulty");
	g_ConVarDifficulty.AddChangeHook(ConVarDiffChanged);
	
	GetDifficulty();
	
	if (g_bLateload)
		ResetAll();
}

public void ConVarDiffChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	GetDifficulty();
}

void GetDifficulty()
{
	g_bEasy = false;
	g_bNormal = false;
	g_bHard = false;
	g_bExpert = false;

	static char sDif[32];
	g_ConVarDifficulty.GetString(sDif, sizeof(sDif));
	if (StrEqual(sDif, "Easy", false)) {
		g_bEasy = true;
	}
	else if (StrEqual(sDif, "Normal", false)) {
		g_bNormal = true;
	}
	else if (StrEqual(sDif, "Hard", false)) {
		g_bHard = true;
	}
	else if (StrEqual(sDif, "Impossible", false)) {
		g_bExpert = true;
	}
}

bool IsAllowed()
{
	if( g_bEasy && l4d_flyinfected_allow_easy.IntValue )
	{
		return true;
	}
	if( g_bNormal && l4d_flyinfected_allow_normal.IntValue )
	{
		return true;
	}
	if( g_bHard && l4d_flyinfected_allow_hard.IntValue )
	{
		return true;
	}
	if( g_bExpert && l4d_flyinfected_allow_expert.IntValue )
	{
		return true;
	}
	return false;
}

public void tank_spawn(Event event, const char [] name, bool dontBroadcast)
{
	if( GetTankCount() != l4d_flyinfected_number.IntValue || !IsAllowed() || GetRandomInt( 1, 100 ) > l4d_flyinfected_chance.IntValue )
	{
		return;
	}
	
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (client && IsClientInGame(client))
	{
		ClientState[client] = State_None; // activate tank to handle by fly functions
		CreateTimer(1.1, Timer_SetColor, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
		SetTankLight(client);
	}
}
 
public void RoundStart(Event event, const char [] name, bool dontBroadcast)
{
	ResetAll();
}

void ResetAll()
{
	for(int i = 1; i <= MaxClients; i++)
	{
		ClientState[i]=State_NotHandle;
		FireTime[i]=0.0;
		RemoveJetPack(i);
		//Clone[i]=0;
		SDKUnhook(i, SDKHook_PreThink,  PreThink); 
		SDKUnhook(i, SDKHook_StartTouch , FlyTouch);
		KillTankLights(i);
	}
}

stock int GetTankCount() {
	static int i, count;
	count = 0;
	for (i = 1; i <= MaxClients; i++)
		if (IsClientInGame(i) && GetClientTeam(i) == 3 && IsTank(i) )
			count++;
	return count;
}

public void player_jump_apex(Event event, const char [] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));	
	
	if(client && ClientState[client]==State_None && GetClientTeam(client) == 3 && IsTank(client) )
	{ 	
		if(GetRandomFloat(0.0, 100.0) < l4d_flyinfected_tankjump_apex.FloatValue)
		{ 
			ClientState[client] = State_Start;
			{
				CreateTimer(1.0, StartTimer, client, TIMER_FLAG_NO_MAPCHANGE);
			}
		}
	}
}

public void weapon_fire(Event event, const char [] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(client && ClientState[client] == State_None && GetClientTeam(client)==3 && IsTank(client))
	{   
		if(GetRandomFloat(0.0, 100.0) < l4d_flyinfected_chance_tankclaw.FloatValue)
		{ 
			ClientState[client]=State_Start;
			{
				CreateTimer(1.0, StartTimer, client, TIMER_FLAG_NO_MAPCHANGE); 
			}
		}
	}
}

/*
public void player_spawn(Event event, const char [] name, bool dontBroadcast)
{
 	int client = GetClientOfUserId(event.GetInt("userid"));
	if(client && IsClientInGame(client))
	{
		SetEntProp(client, Prop_Data, "m_CollisionGroup", 17);
	}
}
*/

public void player_hurt(Event event, const char [] name, bool dontBroadcast)
{
 	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	if(attacker && ClientState[attacker] == State_Fly)
	{
		char weapon[32];	
		event.GetString("weapon", weapon, sizeof(weapon));
	 	if(StrEqual(weapon, "tank_claw", false))
		{
			StopFly(attacker);
		}
	}
}

public void player_shoved(Event event, const char [] name, bool dontBroadcast)
{
 	int victim = GetClientOfUserId(event.GetInt("userid"));
	int client = GetClientOfUserId(event.GetInt("attacker"));
	
	if(client && victim) {
		if (ClientState[victim] == State_Fly)
		{
			if( l4d_flyinfected_shove_on_fly.IntValue != 0 )
			{
				StopFly(victim);
				CreateTimer(0.1, Timer_Shove, client * 100 + victim, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
				PushCommonInfected(victim, client, 300.0);
			}
		}
		if (IsFakeClient(victim))
		{
			if( l4d_flyinfected_shove_turn_around.IntValue != 0 )
			{
				ChangeAngle(client, victim);
			}
		}
	}
}

public Action Timer_Shove(Handle hTimer, int Pack)
{
	static int times = 0;
	times++;
	
	if (times % 10 == 0) {
		times = 0;
		return Plugin_Stop;
	}
	
	int client = Pack / 100;
	int victim = Pack % 100;
	
	if (IsClientInGame(client) && IsClientInGame(victim)) {
		PushTank(client, victim, 75.0);
	}
	else {
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

void GetVectorOrigins(float vecClientPos[3], float vecTargetPos[3], float ang[3])
{
	static float v[3];
	SubtractVectors(vecTargetPos, vecClientPos, v);
	NormalizeVector(v, v);
	GetVectorAngles(v, ang);
}

void ChangeAngle(int client, int target)
{
	float angle[3], vecOrigin[3], vecTarget[3];
	GetClientAbsOrigin(target, vecOrigin);
	GetClientAbsOrigin(client, vecTarget);
	GetVectorOrigins(vecTarget, vecOrigin, angle);
	TeleportEntity(target, NULL_VECTOR, angle, NULL_VECTOR);
}

// smooth teleport in eye view direction (with collision)
//
stock void PushCommonInfected(int client, int target, float distance, float jump_power = 251.0)
{
	static float angle[3], dir[3], current[3], resulting[3];
	
	static int iVelocity = 0;
	if (iVelocity == 0)
		iVelocity = FindSendPropInfo("CBasePlayer", "m_vecVelocity[0]");
	
	GetClientEyeAngles(client, angle);
	
	/*
	float vecOrigin[3], vecTarget[3];
	
	GetClientAbsOrigin(target, vecOrigin);
	GetClientAbsOrigin(client, vecTarget);
	GetVectorOrigins(vecTarget, vecOrigin, angle);
	*/
	
	// ---------------
	
	GetAngleVectors(angle, dir, NULL_VECTOR, NULL_VECTOR);
	NormalizeVector(dir, dir);
	ScaleVector(dir, distance);
	
	GetEntDataVector(target, iVelocity, current);
	resulting[0] = current[0] + dir[0];
	resulting[1] = current[1] + dir[1];
	resulting[2] = jump_power; // min. 251
	
	TeleportEntity(target, NULL_VECTOR, NULL_VECTOR, resulting);
}

stock void PushTank(int client, int target, float force = 75.0)
{
	static float FiringAngles[3], PushforceAngles[3];
	
	GetClientEyeAngles(client, FiringAngles);
	
	PushforceAngles[0] = Cosine(DegToRad(FiringAngles[1])) * force;
	PushforceAngles[1] = Sine(DegToRad(FiringAngles[1])) * force;
	PushforceAngles[2] = Sine(DegToRad(FiringAngles[0])) * force;
	
	float current[3];
	GetEntPropVector(target, Prop_Data, "m_vecVelocity", current);
	
	float resulting[3];
	resulting[0] = current[0] + PushforceAngles[0];
	resulting[1] = current[1] + PushforceAngles[1];
	resulting[2] = current[2] + PushforceAngles[2];
	
	TeleportEntity(target, NULL_VECTOR, NULL_VECTOR, resulting);
}

public void player_jump(Event event, const char [] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));	
	
	if(client && ClientState[client]==State_None && GetClientTeam(client) == 3 && IsTank(client) )
	{ 	
		if(GetRandomFloat(0.0, 100.0) < l4d_flyinfected_chance_tankjump.FloatValue)
		{ 
			ClientState[client] = State_Start;
			{
				CreateTimer(1.0, StartTimer, client, TIMER_FLAG_NO_MAPCHANGE);
			}
		}
	}
}

public void player_death(Event event, const char [] name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(event.GetInt("userid"));	
	
	if (victim && IsClientInGame(victim) && IsTank(victim)) {
		if (l4d_flyinfected_remove_ragdoll.BoolValue) {
			// note: tank_killed event is too late here to retrieve ragdoll entity!
			int ragdoll = GetEntPropEnt(victim, Prop_Send, "m_hRagdoll"); // CCSRagdoll
			if (ragdoll && IsValidEntity(ragdoll)) {
				AcceptEntityInput(ragdoll, "Kill");
			}
		}
		
		if(victim && ClientState[victim]==State_Fly)
		{
			StopFly(victim); 
		}
		ClientState[victim] = State_NotHandle;
		KillTankLights(victim);
		RemoveJetPack(victim);
	}
}

public void ability_use(Event event, const char [] name, bool dontBroadcast)
{	
	int client = GetClientOfUserId(event.GetInt("userid"));	
	if(ClientState[client] == State_None) 
	{
		char ability[32];	
		event.GetString("ability", ability, sizeof(ability));
		if(StrEqual(ability, "ability_throw", false))
		{	 
			if(GetRandomFloat(0.0, 100.0) < l4d_flyinfected_chance_throw.FloatValue)
			{ 
				ClientState[client]=State_Start;
				{
					CreateTimer(1.0, StartTimer, client, TIMER_FLAG_NO_MAPCHANGE);
				}
			}
		}
	}
}

public Action StartTimer(Handle timer, any client)
{ 
	if(client && ClientState[client] != State_Fly && ClientState[client] != State_NotHandle && IsClientInGame(client) && IsPlayerAlive(client) && IsTank(client))
	{ 
		StartFly(client); 	 
	}
	if(ClientState[client]!=State_Fly && ClientState[client] != State_NotHandle) ClientState[client]=State_None;
	return Plugin_Continue;
}

void StartFly(int client)
{
	if(ClientState[client]==State_Fly)
	{
		StopFly(client);
	}
	ClientState[client]=State_None;

	float pos[3], hitpos[3], ang[3], vec[3];
	ang[0]=-89.0;
	GetClientEyePosition(client, pos);
	Handle trace = TR_TraceRayFilterEx(pos, ang, MASK_ALL, RayType_Infinite, DontHitSelf, client);
	
	if(TR_DidHit(trace))
	{
		TR_GetEndPosition(hitpos, trace); 
		if(GetVectorDistance(hitpos, pos) < 100.0)
		{
			StopFly(client);
		}
	}
	delete trace;
	
	ClientState[client]=State_Fly;
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", pos);
	pos[2]+=5.0;
	GetClientEyeAngles(client,vec);
	GetAngleVectors(vec, vec, NULL_VECTOR, NULL_VECTOR);
	NormalizeVector(vec , vec);
	ScaleVector(vec, 55.0);
	vec[2]=30.0; 
	TeleportEntity(client, pos, NULL_VECTOR, vec);
	CopyVector(pos, LastPos[client]);
	CopyVector(vec, ClientVelocity[client]);
	
	LastTime[client]=GetEngineTime()-0.01;
	StartTime[client]=GetEngineTime();
	ScanTime[client]=GetEngineTime()-0.0;
	LastButton[client]=IN_JUMP;
	Enemy[client]=0;
	
	SDKUnhook(client, SDKHook_PreThink,  PreThink);
	SDKHook( client, SDKHook_PreThink,  PreThink);  
	SDKUnhook(client, SDKHook_StartTouch , FlyTouch);
	SDKHook(client, SDKHook_StartTouch , FlyTouch);
	
	//Clone[client]=0;
	RemoveJetPack(client);
	int jetpackb1=CreateJetPackB1(client);
	int jetpackb2=CreateJetPackB2(client);  
	JetPack[client][0]=jetpackb1;
	JetPack[client][1]=jetpackb2;
	
	Flame[client][0] = AttachFlame(client, jetpackb1 );
	Flame[client][0] = AttachFlame(client, jetpackb2 );
	SetEntityMoveType(client, MOVETYPE_FLY);  	
	SwitchTankLights(client, true);
}

void StopFly(int client)
{  
	if(ClientState[client]!=State_Fly)return;
	
	ClientState[client]=State_None;
	SDKUnhook(client, SDKHook_PreThink,  PreThink); 
	SDKUnhook(client, SDKHook_StartTouch , FlyTouch);
	
	//int clone=Clone[client];
	//Clone[client]=JetPack[client][0]=JetPack[client][1]=0;	
	
	if(client && IsClientInGame(client) && IsPlayerAlive(client) && IsTank(client))
	{
		SetEntityMoveType(client, MOVETYPE_WALK); 
		VisiblePlayer(client, true);
	}
	
	/*
	if(clone && IsValidEdict(clone) && IsValidEntity(clone) )
	{
		AcceptEntityInput(clone, "ClearParent");
		AcceptEntityInput(clone, "kill"); 
	}
	*/
	SwitchTankLights(client, false);
}

void RemoveJetPack(int client)
{
	static int i;
	for (i = 0; i <= 1; i++)
	{
		if(JetPack[client][i] && IsValidEntity(JetPack[client][i]) )
		{
			AcceptEntityInput(JetPack[client][i], "ClearParent");
			AcceptEntityInput(JetPack[client][i], "kill"); 
		}
		if(Flame[client][i] && IsValidEntity(Flame[client][i]) )
		{
			AcceptEntityInput(Flame[client][i], "kill"); 
		}
		JetPack[client][i]=0;
		Flame[client][i]=0;
	}
}

void VisiblePlayer(int client, bool visible = true)
{
	if(visible)
	{
		//SetEntityRenderMode(client, RENDER_NORMAL);
		//SetEntityRenderColor(client, 255, 255, 255, 255);
	}
	else
	{
		SetEntityRenderMode(client, RENDER_TRANSCOLOR);
		SetEntityRenderColor(client, 0, 0, 0, 0);
	} 
}

/*
int IsInfected(int client, int type)
{
	int class = GetEntProp(client, Prop_Send, "m_zombieClass");
	if(type==class)return true;
	else return false;
}
*/

stock bool IsTank(int client)
{
	static int class;
	if( client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 3 )
	{
		class = GetEntProp(client, Prop_Send, "m_zombieClass");
		if( class == (g_bLeft4Dead2 ? 8 : 5 ))
			return true;
	}
	return false;
}
 
public void FlyTouch(int ent)
{
	StopFly(ent); 
}

public void PreThink(int client)
{
	if(client && IsClientInGame(client) && IsPlayerAlive(client))
	{ 
		float time=GetEngineTime( );
		float intervual=time-LastTime[client]; 
		int button=GetClientButtons(client);  
		TraceFly(client, button, time, intervual );  
		LastTime[client]=time; 
		LastButton[client]=button;	 
	}
	else
	{
		SDKUnhook(client, SDKHook_PreThink,  PreThink);
	}
}

void TraceFly(int ent, int button, float time, float duration)
{
	if(time-StartTime[ent] > l4d_flyinfected_maxtime.FloatValue)
	{
		StopFly(ent);
		return;
	}
	
	float posmissile[3], velocitymissile[3];	
	
	GetClientAbsOrigin(ent, posmissile); 
	posmissile[2]+=30.0;
	GetEntDataVector(ent, g_iVelocity, velocitymissile);
	bool fake=IsFakeClient(ent);
	if(!fake && (button & IN_JUMP) && !(LastButton[ent] & IN_JUMP))
	{
		GetClientEyeAngles(ent, velocitymissile);
		GetAngleVectors(velocitymissile, velocitymissile, NULL_VECTOR, NULL_VECTOR);
		velocitymissile[2]=0.0;
		NormalizeVector(velocitymissile, velocitymissile);
		ScaleVector(velocitymissile, 310.0);
		velocitymissile[2]=150.0;
		TeleportEntity(ent, NULL_VECTOR,NULL_VECTOR, velocitymissile);
		StopFly(ent);
		return;
	}
	CopyVector(ClientVelocity[ent], velocitymissile);	
	if(GetVectorLength(velocitymissile)<10.0)return ;
	NormalizeVector(velocitymissile, velocitymissile);
 	
	int enemyteam = 2;
	int enemy=Enemy[ent];
	
	if(ScanTime[ent]+1.0<=time)
	{
		ScanTime[ent]=time;
		if(fake)enemy=GetEnemy(posmissile, velocitymissile, enemyteam);
		else 
		{
			float lookdir[3];
			GetClientEyeAngles(ent, lookdir);
			GetAngleVectors(lookdir, lookdir, NULL_VECTOR, NULL_VECTOR); 
			NormalizeVector(lookdir, lookdir);
			enemy=GetEnemy(posmissile, lookdir, enemyteam);
		}
	}
	if(enemy && IsClientInGame(enemy) && IsPlayerAlive(enemy))
	{
		Enemy[ent]=enemy;
	}
	else
	{
		enemy=0;
		Enemy[ent]=enemy;
	}
	
	float velocityenemy[3], vtrace[3], missionangle[3];
	
	vtrace[0]=vtrace[1]=vtrace[2]=0.0;	
	bool visible = false;
	float disenemy = 1000.0;
	
	if(enemy>0)	
	{
		float posenemy[3];
		GetClientEyePosition(enemy, posenemy);
		disenemy=GetVectorDistance(posmissile, posenemy);
		visible=IfTwoPosVisible(posmissile, posenemy, ent);	
		GetEntDataVector(enemy, g_iVelocity, velocityenemy);
		ScaleVector(velocityenemy, duration);
		AddVectors(posenemy, velocityenemy, posenemy);
		MakeVectorFromPoints(posmissile, posenemy, vtrace);
		
		/*
		if(enemy && IsClientInGame(enemy) && IsPlayerAlive(enemy))
		{
			PrintHintText(enemy, "Warning! flying tank, Distance: %d", RoundFloat(disenemy) );
			EmitSoundToClient(enemy, SOUNDMISSILELOCK);
		} 
		*/
	} 
	
	GetVectorAngles(velocitymissile, missionangle);
 
	float vleft[3], vright[3], vup[3], vdown[3], vfront[3], vv1[3], vv2[3], vv3[3], vv4[3], vv5[3], vv6[3], vv7[3], vv8[3];	
	
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
		int flag=FilterSelfAndSurvivor;
		int self=ent;
		float front=CalRay(posmissile, missionangle, 0.0, 0.0, vfront, self, flag);
		float down=CalRay(posmissile, missionangle, 90.0, 0.0, vdown, self, flag);
		float up=CalRay(posmissile, missionangle, -90.0, 0.0, vup, self);
		float left=CalRay(posmissile, missionangle, 0.0, 90.0, vleft, self, flag);
		float right=CalRay(posmissile, missionangle, 0.0, -90.0, vright, self, flag);
		float f1=CalRay(posmissile, missionangle, 30.0, 0.0, vv1, self, flag);
		float f2=CalRay(posmissile, missionangle, 30.0, 45.0, vv2, self, flag);
		float f3=CalRay(posmissile, missionangle, 0.0, 45.0, vv3, self, flag);
		float f4=CalRay(posmissile, missionangle, -30.0, 45.0, vv4, self, flag);
		float f5=CalRay(posmissile, missionangle, -30.0, 0.0, vv5, self, flag);
		float f6=CalRay(posmissile, missionangle, -30.0, -45.0, vv6, self, flag);	
		float f7=CalRay(posmissile, missionangle, 0.0, -45.0, vv7, self, flag);
		float f8=CalRay(posmissile, missionangle, 30.0, -45.0, vv8, self, flag);
		
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
		ScaleVector( vfront, t);
		t=-1.0*factor1*(base-up)/base;
		ScaleVector( vup, t);
		t=-1.0*factor1*(base-down)/base;
		ScaleVector( vdown, t);
		t=-1.0*factor1*(base-left)/base;
		ScaleVector( vleft, t);
		t=-1.0*factor1*(base-right)/base;
		ScaleVector( vright, t);
		t=-1.0*factor1*(base-f1)/f1;
		ScaleVector( vv1, t);
		t=-1.0*factor1*(base-f2)/f2;
		ScaleVector( vv2, t);
		t=-1.0*factor1*(base-f3)/f3;
		ScaleVector( vv3, t);
		t=-1.0*factor1*(base-f4)/f4;
		ScaleVector( vv4, t);
		t=-1.0*factor1*(base-f5)/f5;
		ScaleVector( vv5, t);
		t=-1.0*factor1*(base-f6)/f6;
		ScaleVector( vv6, t);
		t=-1.0*factor1*(base-f7)/f7;
		ScaleVector( vv7, t);
		t=-1.0*factor1*(base-f8)/f8;
		ScaleVector( vv8, t);
	 	
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
	float a = GetAngle(vfront, velocitymissile);
	if(a != a)
    {
        //PrintToServer("'a' is NaN!");
        return;
    }
	float amax = 3.14159*duration*2.0;
	if(a > amax) a = amax; 
	ScaleVector(vfront, a); 
	
	float newvelocitymissile[3];
	AddVectors(velocitymissile, vfront, newvelocitymissile);
	float speed=l4d_flyinfected_speed.FloatValue;
	if(speed<60.0)speed=60.0;
	NormalizeVector(newvelocitymissile, newvelocitymissile);
	ScaleVector(newvelocitymissile, speed); 
	TeleportEntity(ent, NULL_VECTOR,  NULL_VECTOR ,newvelocitymissile); 
	CopyVector(newvelocitymissile, ClientVelocity[ent]);
}

int GetEnemy(float pos[3], float vec[3], int enemyteam)
{
	float min=4.0;
	float pos2[3];
	float t;
	int s=0;
	
	for(int client = 1; client <= MaxClients; client++)
	{
		if(IsClientInGame(client) && GetClientTeam(client) == enemyteam && IsPlayerAlive(client))
		{
			GetClientEyeAngles(client, pos2);
			GetClientEyePosition(client, pos2);
			MakeVectorFromPoints(pos, pos2, pos2);
			t = GetAngle(vec, pos2);
			if(t<=min)
			{
				min=t;
				s=client;
			}
		}
	}
	return s;
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
bool IfTwoPosVisible(float pos1[3], float pos2[3], int self)
{
	bool r = true;
	Handle trace;
	trace=TR_TraceRayFilterEx(pos2, pos1, MASK_SOLID, RayType_EndPoint, DontHitSelfAndSurvivor,self);
	if(TR_DidHit(trace))
	{
		r=false;
	}
 	delete trace;
	return r;
}
float CalRay(float posmissile[3], float angle[3], float offset1, float offset2, float force[3], int ent, int flag=FilterSelf) 
{
	float ang[3];
	CopyVector(angle, ang);
	ang[0]+=offset1;
	ang[1]+=offset2;
	GetAngleVectors(ang, force, NULL_VECTOR,NULL_VECTOR);
	float dis=GetRayDistance(posmissile, ang, ent, flag) ; 
	return dis;
}

float GetAngle(float x1[3], float x2[3])
{
	return ArcCosine(GetVectorDotProduct(x1, x2)/(GetVectorLength(x1)*GetVectorLength(x2)));
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
		char edictname[28];
		if(IsValidEntity(entity) && IsValidEdict(entity) && GetEdictClassname(entity, edictname, 28))
		{
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
		char edictname[128];
		if(IsValidEntity(entity) && IsValidEdict(entity) && GetEdictClassname(entity, edictname, 128))
		{
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
float GetRayDistance(float pos[3], float angle[3], int self, int flag)
{
	float hitpos[3];
	GetRayHitPos(pos, angle, hitpos, self, flag);
	return GetVectorDistance( pos,  hitpos);
}

int GetRayHitPos(float pos[3], float angle[3], float hitpos[3], int self, int flag)
{
	Handle trace;
	int hit=0;
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
		hit=TR_GetEntityIndex( trace);
	}
	delete trace;
	return hit;
}

/*
public void OnMapStart()
{
	PrecacheSound(SOUNDMISSILELOCK, true);	
}
*/

int CreateJetPackB1(int client)
{
	float pos[3], ang[3];
	GetClientEyePosition(client, pos);
	GetClientAbsAngles(client, ang);
	int jetpack=CreateEntityByName("prop_dynamic_override"); 
	DispatchKeyValue(jetpack, "model", "models/props_equipment/oxygentank01.mdl");  
	DispatchSpawn(jetpack); 
	SetEntProp(jetpack, Prop_Data, "m_takedamage", 0, 1);  
	SetEntityMoveType(jetpack, MOVETYPE_NOCLIP);    
	SetEntProp(jetpack, Prop_Data, "m_CollisionGroup", 2); 
	if(GetClientTeam(client)==2)AttachJetPack(jetpack, client, 0); 	
	else AttachJetPack(jetpack, client, 1); 	
	float ang3[3];
	SetVector(ang3, 0.0, 0.0, 1.0); 
	GetVectorAngles(ang3, ang3); 
	CopyVector(ang,ang3);
	if( GetClientTeam(client)==2)
	{
		ang3[2]+=270.0; 
		ang3[1]-=10.0; 
		SetVector(pos,  0.0,  -5.0,  4.0);
	}
	else
	{
		ang3[2]+=90.0; 
		SetVector(pos,  0.0,  30.0,  -8.0);
	}
	DispatchKeyValueVector(jetpack, "origin", pos);  
	DispatchKeyValueVector(jetpack, "Angles", ang3); 
	TeleportEntity(jetpack, pos, NULL_VECTOR, ang3); 	
 	
	return 	jetpack;
}

int CreateJetPackB2(int client)
{
	float pos[3], ang[3];
	GetClientEyePosition(client, pos);
	GetClientAbsAngles(client, ang);
	int jetpack=CreateEntityByName("prop_dynamic_override"); 
	DispatchKeyValue(jetpack, "model", "models/props_equipment/oxygentank01.mdl");  
	DispatchSpawn(jetpack); 
	SetEntProp(jetpack, Prop_Data, "m_takedamage", 0, 1); 	 
	SetEntityMoveType(jetpack, MOVETYPE_NOCLIP);    
	SetEntProp(jetpack, Prop_Data, "m_CollisionGroup", 2); 
	if(GetClientTeam(client)==2)AttachJetPack(jetpack, client, 0); 	
	else AttachJetPack(jetpack, client, 2); 
	
	float ang3[3];
	SetVector(ang3, 0.0, 0.0, 1.0);
	GetVectorAngles(ang3, ang3); 
	CopyVector(ang,ang3);
	if( GetClientTeam(client)==2)
	{
		ang3[2]+=270.0; 
		ang3[1]-=10.0; 
		SetVector(pos,  0.0,  -5.0,  -4.0);
	}
	else
	{
		ang3[2]+=90.0; 
		SetVector(pos,  0.0,  30.0,  8.0);
	} 
	DispatchKeyValueVector(jetpack, "origin", pos);  
	DispatchKeyValueVector(jetpack, "Angles", ang3); 
	TeleportEntity(jetpack, pos, NULL_VECTOR, ang3); 	 
	
	return 	jetpack;
}

int AttachFlame(int client, int ent)
{
	char flame_name[128];
	client=client+0; // shut up compiler
	Format(flame_name, sizeof(flame_name), "target%d", ent);
	int flame = CreateEntityByName("env_steam");
	DispatchKeyValue( ent,"targetname", flame_name);
	DispatchKeyValue(flame,"parentname", flame_name);
	DispatchKeyValue(flame,"SpawnFlags", "1");
	DispatchKeyValue(flame,"Type", "0");
 
	DispatchKeyValue(flame,"InitialState", "1");
	DispatchKeyValue(flame,"Spreadspeed", "1");
	DispatchKeyValue(flame,"Speed", "250");
	DispatchKeyValue(flame,"Startsize", "6");
	DispatchKeyValue(flame,"EndSize", "8");
	DispatchKeyValue(flame,"Rate", "555");
	DispatchKeyValue(flame,"RenderColor", "10 52 99"); 
	DispatchKeyValue(flame,"JetLength", "40"); 
	DispatchKeyValue(flame,"RenderAmt", "180");
	
	DispatchSpawn(flame);	 
	SetVariantString(flame_name);
	AcceptEntityInput(flame, "SetParent", flame, flame, 0);
	
	float origin[3];
	SetVector(origin,  -2.0, 0.0,  26.0);
	float ang[3];
	SetVector(ang, 0.0, 0.0, 1.0); 
	GetVectorAngles(ang, ang); 
	TeleportEntity(flame, origin, ang,NULL_VECTOR);	
	AcceptEntityInput(flame, "TurnOn"); 
	return flame;
}

void AttachJetPack(int ent, int owner, int position)
{
	if(owner > 0 && ent > 0)
	{
		if(owner < MaxClients)
		{
			char sTemp[16];
			Format(sTemp, sizeof(sTemp), "target%d", owner);
			DispatchKeyValue(owner, "targetname", sTemp);
			SetVariantString(sTemp);
			AcceptEntityInput(ent, "SetParent", ent, ent, 0);
			if(position==0)SetVariantString("medkit"); // survivor as a tank
			if(position==1)SetVariantString("lfoot");  
			if(position==2)SetVariantString("rfoot"); 
			AcceptEntityInput(ent, "SetParentAttachment");
		}
	}
}

public Action Timer_SetColor(Handle timer, int UserId)
{
	int client = GetClientOfUserId(UserId);
	
	if (client && IsClientInGame(client)) {
		SetEntityRenderColor(client, 0, 180, 255, 255); // cyan
		StartFly(client);
	}
	return Plugin_Continue;
}

void SetTankLight(int tank)
{
	static int aColor[3] = {0, 180, 255};
	
	g_iLight[0][tank] = vLightProp(tank, "relbow", view_as<float>({0,0,0}), view_as<float>({45.0, 70.0, 0.0}), aColor);
	g_iLight[1][tank] = vLightProp(tank, "relbow", view_as<float>({0,0,0}), view_as<float>({45.0, 90.0, 0.0}), aColor);
	g_iLight[2][tank] = vLightProp(tank, "relbow", view_as<float>({0,0,0}), view_as<float>({45.0, 120.0, 0.0}), aColor);
	
	g_iLight[3][tank] = vLightProp(tank, "lelbow", view_as<float>({0,0,0}), view_as<float>({-90.0, 0.0, 0.0}), aColor);
	g_iLight[4][tank] = vLightProp(tank, "lelbow", view_as<float>({0,0,0}), view_as<float>({-70.0, 0.0, 0.0}), aColor);
	g_iLight[5][tank] = vLightProp(tank, "lelbow", view_as<float>({0,0,0}), view_as<float>({-50.0, 0.0, 0.0}), aColor);
}

stock void SetEntityKillTimer(int ent, float time)
{
	char sRemove[64];
	Format(sRemove, sizeof(sRemove), "OnUser1 !self:Kill::%f:1", time);
	SetVariantString(sRemove);
	AcceptEntityInput(ent, "AddOutput");
	AcceptEntityInput(ent, "FireUser1");
}

int vLightProp(int tank, char[] sPoint, float origin[3], float angles[3], int color[3])
{
	int iLight = CreateEntityByName("beam_spotlight");
	if (iLight != -1) {
		//DispatchKeyValueVector(iLight, "origin", origin);
		//DispatchKeyValueVector(iLight, "angles", angles);
		SetEntityRenderColor(iLight, color[0], color[1], color[2], 255);
		DispatchKeyValue(iLight, "spotlightwidth", "10"); // 10
		DispatchKeyValue(iLight, "spotlightlength", "150"); // 120
		DispatchKeyValue(iLight, "spawnflags", "3");
		DispatchKeyValue(iLight, "maxspeed", "100");
		DispatchKeyValue(iLight, "HDRColorScale", "1.0"); // 0.6
		DispatchKeyValue(iLight, "fadescale", "1");
		DispatchKeyValue(iLight, "fademindist", "-1");
		//DispatchKeyValue(iLight, "rendermode", "1");
		
		DispatchSpawn(iLight);
		SetVariantString("!activator"); 
		AcceptEntityInput(iLight, "SetParent", tank);
		SetVariantString(sPoint);
		AcceptEntityInput(iLight, "SetParentAttachment");
		
		//TeleportEntity(iLight, NULL_VECTOR, angles, NULL_VECTOR); // origin
		TeleportEntity(iLight, origin, angles, NULL_VECTOR);
		ActivateEntity(iLight);
		
		AcceptEntityInput(iLight, "Enable");
		AcceptEntityInput(iLight, "DisableCollision");
		
		//SetEntPropEnt(iLight, Prop_Send, "m_hOwnerEntity", tank);
		//SetEntPropFloat(iLight, Prop_Send, "m_flHDRColorScale", 3.0);
		//SetEntityKillTimer(iLight, 10.0);
		
		return iLight;
	}
	return -1;
}

void KillTankLights(int tank)
{
	static int i;
	for (i = 0; i < sizeof(g_iLight); i++) {
		if (g_iLight[i][tank] > 0 && IsValidEntity(g_iLight[i][tank])) {
			AcceptEntityInput(g_iLight[i][tank], "Kill");
			g_iLight[i][tank] = -1;
		}
	}
}

void SwitchTankLights(int tank, bool bSwitchOn)
{
	for (int i = 0; i < sizeof(g_iLight); i++) {
		if (IsValidEntity(g_iLight[i][tank])) {
			AcceptEntityInput(g_iLight[i][tank], bSwitchOn ? "LightOn" : "LightOff");
		}
	}
}