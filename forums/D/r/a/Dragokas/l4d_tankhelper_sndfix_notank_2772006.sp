#pragma newdecls required
#pragma semicolon 1

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>

#define MODEL_HUNTER "models/infected/hunter.mdl"
#define MODEL_BOOMER "models/infected/boomer.mdl"
#define MODEL_SMOKER "models/infected/smoker.mdl"
#define MODEL_WITCH "models/infected/witch.mdl"
#define MODEL_TANK "models/infected/hulk.mdl"
#define MODEL_CHARGER "models/infected/charger.mdl"
#define MODEL_SPITTER "models/infected/spitter.mdl"
#define MODEL_JOCKEY "models/infected/jockey.mdl"

#define SOUND_THROWN_MISSILE "player/tank/attack/thrown_missile_loop_1.wav"

enum
{
	SI_TYPE_HUNTER,
	SI_TYPE_SMOKER,
	SI_TYPE_BOOMER,
	SI_TYPE_TANK,
	SI_TYPE_SELF,
	SI_TYPE_WITCH,
	SI_TYPE_CHARGER,
	SI_TYPE_SPITTER,
	SI_TYPE_JOCKEY
}

const int CLASS_CNT = 9;

ConVar l4d_tank_throw_si;
ConVar l4d_tank_throw_hunter;
ConVar l4d_tank_throw_smoker;
ConVar l4d_tank_throw_boomer;
ConVar l4d_tank_throw_charger;
ConVar l4d_tank_throw_spitter;
ConVar l4d_tank_throw_jockey;
ConVar l4d_tank_throw_witch;
ConVar l4d_tank_throw_tank;
ConVar l4d_tank_throw_self;
ConVar l4d_tank_throw_tankhealth;
ConVar l4d_tank_throw_min;
ConVar l4d_tank_throw_max;

int CLASS_GAME_CNT;
int L4D2Version;
int g_iVelocity;

int tank;
float g_fTankThrowForce;

int rock[MAXPLAYERS+1];
int fakesi[2048];
int g_iSiOfRock[2048];
int g_iSiOfTank[MAXPLAYERS+1];
int g_iRockTimerCnt;
int g_iTrackSiCnt[CLASS_CNT];
float throw_all[CLASS_CNT];
char g_sModel[CLASS_CNT][PLATFORM_MAX_PATH];
char g_sAnim[CLASS_CNT][32];
char g_sClass[CLASS_CNT][32];

bool gamestart;
bool g_bLateload;

public Plugin myinfo = 
{
	name = "tank's throw special infected",
	author = "Pan Xiaohai",
	description = "tank's throw special infected",
	version = "1.4",
	url = "<- URL ->"
}

/* Fork by Dragokas
	
	1.1
	 - Removed rock thrown sound (it's looping)
	 
	1.2
	 - Converted to a new syntax and methodmaps
	 - Fixed case when tank throw another tank
	 - Simplified code a little bit
	 
	1.3
	 - Temporarily removed ability to throw tank
	 
	1.4 (09-Nov-2019)
	 - Changed the way particles are precached
	 - Changed the method of spawning infected
	 - Tank rock model is now completely replaced, infected is visible just once the tank begins to lift up the "rock" from the ground
	 - Changed the method of removing tank rock, so sound hook fix is not need anymore.
	 - more safe checks
	 - Added ability to throw more than 1 infected at once, new ConVars "l4d_tank_throw_count_min" and "l4d_tank_throw_count_max" (not acceptable for tanks / witches)
	 - Added ability to throw the with, new ConVar "l4d_tank_throw_witch".
	 
*/

public APLRes AskPluginLoad2(Handle myself, bool late, char [] error, int err_max) 
{
	EngineVersion test = GetEngineVersion();
	if (test == Engine_Left4Dead2) {
		L4D2Version = true;
	}
	g_bLateload = late;
	return APLRes_Success;
}

public void OnPluginStart()
{
	l4d_tank_throw_si = CreateConVar("l4d_tank_throw_si", "30.0", "tank throws special infected [0.0, 100.0]", FCVAR_NOTIFY);
	
	l4d_tank_throw_min 	= CreateConVar("l4d_tank_throw_count_min", "2", 	"minimum si to throw at once", FCVAR_NOTIFY);
	l4d_tank_throw_max 	= CreateConVar("l4d_tank_throw_count_max", "2", 	"maximum si to throw at once", FCVAR_NOTIFY);
	
	l4d_tank_throw_hunter 	= CreateConVar("l4d_tank_throw_hunter", "10.0", 	"weight of hunter[0.0, 10.0]", FCVAR_NOTIFY);
	l4d_tank_throw_smoker 	= CreateConVar("l4d_tank_throw_smoker", "5.0", 	"[0.0, 10.0]", FCVAR_NOTIFY);
	l4d_tank_throw_boomer 	= CreateConVar("l4d_tank_throw_boomer", "5.0", 	"[0.0, 10.0]", FCVAR_NOTIFY);
	l4d_tank_throw_charger 	= CreateConVar("l4d_tank_throw_charger", "10.0", 	"[0.0, 10.0]", FCVAR_NOTIFY);
	l4d_tank_throw_spitter	= CreateConVar("l4d_tank_throw_spitter", "5.0", 	"[0.0, 10.0]", FCVAR_NOTIFY);
	l4d_tank_throw_jockey	= CreateConVar("l4d_tank_throw_jockey", "10.0",  	"[0.0, 10.0]", FCVAR_NOTIFY);
	//l4d_tank_throw_tank		= CreateConVar("l4d_tank_throw_tank", "2.0",  	"[0.0, 10.0]", FCVAR_NOTIFY);
	l4d_tank_throw_tank		= CreateConVar("l4d_tank_throw_tank", "0.0",  	"[0.0, 10.0]", FCVAR_NOTIFY);
	l4d_tank_throw_self		= CreateConVar("l4d_tank_throw_self", "10.0",  	"[0.0, 10.0]", FCVAR_NOTIFY);	
	//l4d_tank_throw_witch	= CreateConVar("l4d_tank_throw_witch", "10.0",  	"[0.0, 10.0]", FCVAR_NOTIFY);
	l4d_tank_throw_witch	= CreateConVar("l4d_tank_throw_witch", "0.0",  	"[0.0, 10.0]", FCVAR_NOTIFY);
	l4d_tank_throw_tankhealth=CreateConVar("l4d_tank_throw_tankhealth", "1000",  	"", FCVAR_NOTIFY);		
	
	//AutoExecConfig(true, "l4d_tankhelper");
	
	HookEvent("round_end", RoundEnd);
	HookEvent("finale_win", RoundEnd);
	HookEvent("mission_lost", RoundEnd);
	HookEvent("map_transition", RoundEnd);
	HookEvent("tank_spawn", RoundStart);
	HookEvent("ability_use", ability_use);
	
	g_iVelocity = FindSendPropInfo("CBasePlayer", "m_vecVelocity[0]");
	
	CLASS_GAME_CNT = L4D2Version ? 8 : 5;
	
	g_sModel[0] = MODEL_HUNTER;
	g_sModel[1] = MODEL_SMOKER;
	g_sModel[2] = MODEL_BOOMER;
	g_sModel[3] = MODEL_TANK;
	g_sModel[4] = "";
	g_sModel[5] = MODEL_WITCH;
	g_sModel[6] = MODEL_CHARGER;
	g_sModel[7] = MODEL_SPITTER;
	g_sModel[8] = MODEL_JOCKEY;
	
	g_sAnim[0] = "Idle_Standing_01";
	g_sAnim[1] = "deathpose_crouch_left";
	g_sAnim[2] = "Crouch_Idle_Upper_KNIFE";
	g_sAnim[3] = "Shoved_Forward";
	g_sAnim[4] = "";
	g_sAnim[5] = "Idle_Sitting";
	g_sAnim[6] = "Crouch_Walk_Upper_KNIFE";
	g_sAnim[7] = "Crouch_Idle";
	g_sAnim[8] = "Crouch_Idle";
	
	g_sClass[0] = "hunter";
	g_sClass[1] = "smoker";
	g_sClass[2] = "boomer";
	g_sClass[3] = "tank";
	g_sClass[4] = "";
	g_sClass[5] = "witch";
	g_sClass[6] = "charger";
	g_sClass[7] = "spitter";
	g_sClass[8] = "jockey";
	
	l4d_tank_throw_si.AddChangeHook(ConVarChange);	
	l4d_tank_throw_hunter.AddChangeHook(ConVarChange);	
	l4d_tank_throw_smoker.AddChangeHook(ConVarChange);	
	l4d_tank_throw_boomer.AddChangeHook(ConVarChange);	
	l4d_tank_throw_witch.AddChangeHook(ConVarChange);
	l4d_tank_throw_charger.AddChangeHook(ConVarChange);	
	l4d_tank_throw_spitter.AddChangeHook(ConVarChange);	
	l4d_tank_throw_jockey.AddChangeHook(ConVarChange);	
	l4d_tank_throw_tank.AddChangeHook(ConVarChange);
	GetConVar();
	
	if ( g_bLateload )
		gamestart = true;
	
	RegConsoleCmd("sm_test", CmdTest);
}

public Action CmdTest(int client, int arg)
{

	float pos[3], ang[3];

	GetClientAbsOrigin( client, pos );
	pos[2] += 100.0;

	SpawnSI(0, pos, ang);

	return Plugin_Handled;
}

public void OnAllPluginsLoaded()
{
	g_fTankThrowForce = FindConVar("z_tank_throw_force").FloatValue;
}

public void OnMapStart()
{ 
	if( L4D2Version )
	{ 
		PrecacheParticleEffect("electrical_arc_01_system");
	}
}

public void ConVarChange(Handle convar, const char[] oldValue, const char[] newValue)
{
	GetConVar();
}

void GetConVar()
{
	throw_all[0]=l4d_tank_throw_hunter.FloatValue;
	throw_all[1]=throw_all[0]+l4d_tank_throw_smoker.FloatValue;
	throw_all[2]=throw_all[1]+l4d_tank_throw_boomer.FloatValue;
	throw_all[3]=throw_all[2]+l4d_tank_throw_tank.FloatValue;	
	throw_all[4]=throw_all[3]+l4d_tank_throw_self.FloatValue;
	throw_all[5]=throw_all[4]+l4d_tank_throw_witch.FloatValue;
	throw_all[6]=throw_all[5]+l4d_tank_throw_charger.FloatValue;
	throw_all[7]=throw_all[6]+l4d_tank_throw_spitter.FloatValue;
	throw_all[8]=throw_all[7]+l4d_tank_throw_jockey.FloatValue;
}

public Action RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	gamestart = true;
	tank = 0;
	g_iRockTimerCnt = 0;
	
	for (int i = 0; i < CLASS_CNT; i++)
	{
		g_iTrackSiCnt[i] = 0;
	}
}

public Action RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	gamestart = false;
}

public Action ability_use(Event event, const char[] name, bool dontBroadcast)
{
	static char s[32];
	event.GetString("ability", s, 32);
	if(strcmp(s, "ability_throw") == 0)
	{	
		tank = GetClientOfUserId(event.GetInt("userid"));
	}
}

float g_vel[3];
float g_pos[3];
int g_rock;
int g_SiEntOfRock[2048];

public void OnEntityCreated(int entity, const char[] classname)
{
	static int SiIdx, i, iRock;
	
	if ( !gamestart ) return;
	
	if (g_iRockTimerCnt)
	{
		//PrintToChatAll("created entity: %s", classname);
		
		for (i = 0; i < CLASS_CNT; i++)
		{
			if ( g_iTrackSiCnt[i] ) 
			{
				if ( strcmp(classname, g_sClass[i]) == 0 )
				{
					//PrintToChatAll("set vel on class: %s", g_sClass[i]);
					
					g_iTrackSiCnt[i]--;
					SDKHook(entity, SDKHook_SpawnPost, Infected_SpawnPost);
					return;
				}
			}
		}
	}
	
	iRock = entity;
	
	if( tank > 0 && IsValidEdict(iRock) && StrEqual(classname, "tank_rock", true) && GetEntProp(iRock, Prop_Send, "m_iTeamNum") >= 0 )
	{
		if( GetRandomFloat(0.0, 100.0) <= l4d_tank_throw_si.FloatValue)
		{
			SiIdx = GetSiRandomType();
			
			g_iSiOfTank[tank] = SiIdx;
			g_iSiOfRock[iRock] = SiIdx;
			
			rock[tank] = iRock;
			
			g_rock = iRock;
			
			if ( SiIdx != 4 )
				g_iRockTimerCnt++;
			
			CreateTimer(0.1, TraceRock, tank, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
			
			SDKHook(iRock, SDKHook_SpawnPost, Rock_SpawnPost);
			HookSingleEntityOutput(iRock, "OnKilled", OnRockDestroyed, true);
		}
		tank = 0;
	}
}

public void OnRockDestroyed(const char[] output, int caller, int activator, float delay)
{
	//PrintToChatAll("Rock desktroyed.");
	
	if (caller && IsValidEntity(caller))
	{
		float pos[3];
		int si = g_SiEntOfRock[caller];
		GetEntPropVector(caller, Prop_Send, "m_vecOrigin", pos);
		if (si > MaxClients && IsValidEntity(si))
		{
			AcceptEntityInput(si, "ClearParent");
			TeleportEntity(si, pos, NULL_VECTOR, NULL_VECTOR);
		}
	}
}

public void Infected_SpawnPost(int si)
{
	#define EF_BONEMERGE            (1 << 0)
	#define EF_NOSHADOW             (1 << 4)
	#define EF_BONEMERGE_FASTCULL   (1 << 7)
	#define EF_PARENT_ANIMATES      (1 << 9)

	//PrintToChatAll("teleporting: %i", si);
	
	// for witch
	if ( IsValidEntity(g_rock) )
	{
		//PrintToChatAll("parenting: %i", si);
		
		TeleportEntity(si, g_pos, NULL_VECTOR, g_vel);
		ParentToEntity(si, g_rock);
		//SetVariantString("ValveBiped.debris_bone"); 
		//AcceptEntityInput(si, "SetParentAttachment", 1);
		//SetEntProp(si, Prop_Send, "m_fEffects",               EF_BONEMERGE|EF_NOSHADOW|EF_PARENT_ANIMATES);
		g_SiEntOfRock[g_rock] = si;
	}
	
	// for other infected
	RequestFrame(OnNextFrame, EntIndexToEntRef(si));
}

public void OnNextFrame(int iEntRef)
{
	float pos[3], vel[3];
	
	int si = EntRefToEntIndex(iEntRef);
	
	if ( si && si != INVALID_ENT_REFERENCE && IsValidEntity(si) )
	{
		int spawner = GetEntPropEnt(si, Prop_Send, "m_hOwnerEntity");
		
		if ( spawner > 0 && IsValidEntity(spawner) )
		{
			GetEntPropVector(spawner, Prop_Send, "m_vecOrigin", pos);
			GetEntPropVector(spawner, Prop_Data, "m_vecAbsVelocity", vel);
			
			if ( IsTank(si) )
			{
				SetEntProp(si, Prop_Send, "m_iHealth", l4d_tank_throw_tankhealth.IntValue);
			}
			TeleportEntity(si, pos, NULL_VECTOR, NULL_VECTOR); //vel);
			
			//PrintToChatAll("Apply vel: %f %f %f", vel[0], vel[1], vel[2]);
		}
	}
}

public void Rock_SpawnPost(int iRock)
{
	// hide rock model and disable collision just in case it have time to reach the goal
	SetEntProp(iRock, Prop_Send, "m_CollisionGroup", 2);
	SetEntityRenderMode(iRock, RENDER_TRANSCOLOR);
	SetEntityRenderColor(iRock, 0, 0, 0, 0);
	
	if ( g_iSiOfRock[iRock] == 4 ) // throw self
	{
		fakesi[iRock] = -1;
	}
	else {
		// fake model to animate throw from the ground
		int fake = CreateEntityByName("prop_dynamic_override");
		if ( fake != -1 ) {
			DispatchKeyValue(fake, "spawnflags", "0");
			DispatchKeyValue(fake, "solid", "0");
			DispatchKeyValue(fake, "disablereceiveshadows", "1");
			DispatchKeyValue(fake, "model", g_sModel[g_iSiOfRock[iRock]] );
			DispatchKeyValue(fake, "DefaultAnim", g_sAnim[g_iSiOfRock[iRock]] );
			DispatchSpawn(fake);
			AcceptEntityInput(fake, "TurnOn");
			float pos[3];
			GetEntPropVector(iRock, Prop_Data, "m_vecOrigin", pos);
			TeleportEntity(fake, pos, view_as<float>({0.0, 0.0, 180.0}), NULL_VECTOR);
			ParentToEntity( fake, iRock );
			SetEntityKillTimer(fake, 5.0);
			fakesi[iRock] = EntIndexToEntRef(fake);
		}
	}
}

public Action TraceRock(Handle timer, int thetank)
{
	static float velocity[3], pos[3], v;
	static int iRock, count, iClass;
	int si;
	
	iRock = rock[thetank];
	iClass = g_iSiOfTank[thetank];
	
	if( gamestart && iRock && IsValidEntity(iRock) )
	{
		GetEntDataVector(iRock, g_iVelocity, velocity);
		v = GetVectorLength(velocity);

		if( v > 500.0 )
		{
			int fake = EntRefToEntIndex(fakesi[iRock]);
			if (fake && fake != INVALID_ENT_REFERENCE && IsValidEntity(fake))
				AcceptEntityInput(fake, "kill");
			
			GetEntPropVector(iRock, Prop_Send, "m_vecOrigin", pos);
			
			if( StuckCheck(iRock, pos) )
			{
				NormalizeVector(velocity, velocity);
				ScaleVector(velocity, g_fTankThrowForce * 1.4);
				
				//PrintToChatAll("type: %i", iClass);
				
				si = CreateSI(thetank, pos, velocity);
				
				//PrintToChatAll("si = %i", si);
				
				if (iClass == SI_TYPE_WITCH)
					SetEntitySolid(iRock, false);
				else {
					StopSound(iRock, SNDCHAN_BODY, SOUND_THROWN_MISSILE);
					AcceptEntityInput(iRock, "kill");
					//TeleportEntity(iRock, view_as<float>({0.0, 0.0, 0.0}), NULL_VECTOR, NULL_VECTOR); // safe removing the rock
				}
				
				// repeat throwing several times
				if ( iClass != SI_TYPE_SELF && 
					 iClass != SI_TYPE_WITCH &&
					 iClass != SI_TYPE_TANK )
				{
					count = GetRandomInt(l4d_tank_throw_min.IntValue, l4d_tank_throw_max.IntValue);
					
					if (count > 1)
					{
						for (int i = 1; i < count; i++)
						{
							SpawnSIRandomVel( iClass, pos, velocity);
						}
					}
					
					if(L4D2Version)
					{
						ShowParticle(pos, "electrical_arc_01_system", 3.0);		
					}
				}
			}
			if ( iClass != SI_TYPE_SELF ) CreateTimer(0.1, TraceRockStop, si > MaxClients ? thetank : 0);
			return Plugin_Stop;
		}
	}
	else {
		if ( iClass != SI_TYPE_SELF ) CreateTimer(0.1, TraceRockStop, 0);
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

// decreace tracks count to prevent OnEntityCreated track the wrong target
public Action TraceRockStop(Handle timer, int thetank)
{
	if ( thetank != 0 )
	{
		g_iTrackSiCnt[ g_iSiOfTank[thetank] ] --;
	}
	g_iRockTimerCnt--;
}

// randomize velocity for repeatable throwing
void SpawnSIRandomVel(int type, float pos[3], float velocity[3])
{
	velocity[0] += GetRandomFloat(-50.0, 50.0);
	velocity[1] += GetRandomFloat(-50.0, 50.0);
	velocity[2] += GetRandomFloat(-50.0, 50.0);
	
	SpawnSI( type, pos, velocity );
}

void Array_Copy(float src[3], float dst[3])
{
	for (int i = 0; i < 3; i++)
		dst[i] = src[i];
}

/*
	Spawns special infected
	@return: entity of spawner (this actually doesn't mean si is successfully spawned), -1 on failure
*/
int SpawnSI(int type, float pos[3], float velocity[3])
{
	Array_Copy(pos, g_pos);
	Array_Copy(velocity, g_vel);

	int spawner = CreateEntityByName("commentary_zombie_spawner");
	if ( spawner != -1 )
	{
		DispatchKeyValue(spawner, "targetname", "zombie_tank");
		TeleportEntity(spawner, pos, NULL_VECTOR, velocity); // save pos and vel
		DispatchSpawn(spawner);
		ActivateEntity(spawner);
		SetVariantString("OnSpawnedZombieDeath !self:Kill::1.0:1");
		AcceptEntityInput(spawner, "AddOutput");
		SetVariantString(g_sClass[type]);
		g_iTrackSiCnt[type]++;
		AcceptEntityInput(spawner, "SpawnZombie" );
	}
	return spawner;
}

// select type of si to throw
int GetSiRandomType()
{
	int selected;
	float r = GetRandomFloat(0.0, throw_all[CLASS_GAME_CNT]);

	for (int i = 0; i <= CLASS_GAME_CNT; i++)
	{
		if ( r < throw_all[i] )
		{
			selected = i;
			break;
		}
	}
	return selected;
}

/*
	@return:
		-1 on failure
		> MaxClients for "commentary_zombie_spawner" entity, when spawning is success
		1 ... MaxClients for already spawned infected selected from the world if spawning failed
*/
int CreateSI(int thetank, float pos[3], float velocity[3])
{
	int selected = -1;
	int iClass = g_iSiOfTank[thetank];
	
	if ( iClass == SI_TYPE_SELF )
	{
		if (IsClientInGame(thetank))
		{
			selected = thetank;
			TeleportEntity(selected, pos, NULL_VECTOR, velocity);
		}
	}
	else {
		selected = SpawnSI( iClass, pos, velocity );
	}
	
	if( selected == -1 )
	{
		//PrintToChatAll("Can't create");
		
		int candidate[MAXPLAYERS+1];
		int index=0;
		for(int i = 1; i <= MaxClients; i++)
		{
			if( IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == 3 && !IsTank(i) )
			{
				candidate[index++] = i;
				break;
			}
		}
		if( index > 0 )
		{
			//selected=candidate[GetRandomInt(0, index-1)];
			selected = candidate[0];
			TeleportEntity(selected, pos, NULL_VECTOR, velocity);
		}
	}
 	return selected;
}

bool StuckCheck(int ent, float pos[3])
{
	float vAngles[3];
	float vOrigin[3];
	vAngles[2] = 1.0;
	GetVectorAngles(vAngles, vAngles);
	Handle trace = TR_TraceRayFilterEx(pos, vAngles, MASK_SOLID, RayType_Infinite, TraceRayDontHitSelf,ent);
	if ( trace != INVALID_HANDLE )
	{
		if( TR_DidHit(trace) )
		{
			TR_GetEndPosition(vOrigin, trace);
			float dis=GetVectorDistance(vOrigin, pos);
			if( dis > 100.0 ) {
				CloseHandle(trace);
				return true;	
			}
		}
		CloseHandle(trace);
	}
	return false;
}

stock bool IsTank(int client)
{
	if( client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 3 )
	{
		int class = GetEntProp(client, Prop_Send, "m_zombieClass");
		if( class == (L4D2Version ? 8 : 5) )
			return true;
	}
	return false;
}
 
public void ShowParticle(float pos[3], char[] particlename, float time)
{
	int particle = CreateEntityByName("info_particle_system");
	if ( particle != -1 )
	{
		TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);
		DispatchKeyValue(particle, "effect_name", particlename);
		DispatchKeyValue(particle, "targetname", "particle");
		DispatchSpawn(particle);
		ActivateEntity(particle);
		AcceptEntityInput(particle, "start");
		CreateTimer(time, DeleteParticles, particle, TIMER_FLAG_NO_MAPCHANGE);
	} 
}

stock void PrecacheParticleEffect(const char[] sEffectName) // thanks to Dr. Api
{
    static int table = INVALID_STRING_TABLE;
    
    if ( table == INVALID_STRING_TABLE )
    {
        table = FindStringTable("ParticleEffectNames");
    }
    bool save = LockStringTables(false);
    AddToStringTable(table, sEffectName);
    LockStringTables(save);
}

public Action DeleteParticles(Handle timer, int particle)
{
	if (particle && IsValidEntity(particle))
	{
		char classname[64];
		GetEdictClassname(particle, classname, sizeof(classname));
		if (StrEqual(classname, "info_particle_system", false))
		{
			AcceptEntityInput(particle, "stop");
			AcceptEntityInput(particle, "kill");
			//RemoveEdict(particle);
		}
	}
}
public bool TraceRayDontHitSelf(int entity, int mask, int data)
{
	if( entity == data )
	{
		return false; 
	}
	return true;
}
 
void SetEntityKillTimer(int ent, float time)
{
	char sRemove[64];
	Format(sRemove, sizeof(sRemove), "OnUser1 !self:Kill::%f:1", time);
	SetVariantString(sRemove);
	AcceptEntityInput(ent, "AddOutput");
	AcceptEntityInput(ent, "FireUser1");
}

bool ParentToEntity( int ent, int target )
{
	/*
	char buf[32];
	FormatEx(buf, sizeof(buf), "Ent%i", target);
	DispatchKeyValue(target, "targetname", buf);
	//SetVariantEntity( target );
	SetVariantString(buf);
	*/
	SetVariantString("!activator"); 
	return AcceptEntityInput( ent, "SetParent", target);
}

stock void SetEntitySolid(int entity, bool doSolid)
{
	#define FSOLID_NOT_SOLID 	0x0004
	#define SOLID_NONE 			0
	#define SOLID_VPHYSICS		6
	
	int m_nSolidType	= GetEntProp(entity, Prop_Data, "m_nSolidType", 1);
	int m_usSolidFlags	= GetEntProp(entity, Prop_Data, "m_usSolidFlags", 2);
	
	//int m_colGroup = GetEntProp(entity, Prop_Send, "m_CollisionGroup");
	//PrintToChatAll("collision: %i, SolidType: %i, SolidFlags: %i",m_colGroup, m_nSolidType, m_usSolidFlags);
	
	if ( doSolid ) {
		if (m_nSolidType == 0)
			SetEntProp(entity, Prop_Send,	"m_nSolidType",		SOLID_VPHYSICS,	1);
			
		if (m_usSolidFlags & FSOLID_NOT_SOLID)
			SetEntProp(entity, Prop_Send,	"m_usSolidFlags", 	m_usSolidFlags & ~FSOLID_NOT_SOLID,	2);
		
		SetEntProp(entity, Prop_Send, "m_CollisionGroup", 0);
	}
	else {
		
		SetEntProp(entity, Prop_Send, "m_CollisionGroup", 2);
		
		if (m_nSolidType != 0)
			SetEntProp(entity, Prop_Send,	"m_nSolidType",		SOLID_NONE,	1);
			
		if (m_usSolidFlags & FSOLID_NOT_SOLID == 0)
			SetEntProp(entity, Prop_Send,	"m_usSolidFlags", 	m_usSolidFlags | FSOLID_NOT_SOLID,	2);
	}
}
