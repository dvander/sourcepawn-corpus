#pragma newdecls required
#pragma semicolon 1

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
//#include <sdktools_functions>

#define SOUND_THROWN_MISSILE 		"player/tank/attack/thrown_missile_loop_1.wav"

int g_iVelocity ;
ConVar l4d_tank_throw_si;
ConVar l4d_tank_throw_hunter 	;
ConVar l4d_tank_throw_smoker 	;
ConVar l4d_tank_throw_boomer 	;
ConVar l4d_tank_throw_charger 	;
ConVar l4d_tank_throw_spitter	;
ConVar l4d_tank_throw_jockey		;
ConVar l4d_tank_throw_tank		;
ConVar l4d_tank_throw_self;
ConVar l4d_tank_throw_tankhealth;
int rock[MAXPLAYERS+1];
int tank=0;
int L4D2Version;
public Plugin myinfo = 
{
	name = "tank's throw special infected",
	author = "Pan Xiaohai",
	description = "tank's throw special infected",
	version = "1.2",
	url = "<- URL ->"
}
/* Fork by Dragokas
	
	1.1
	 - Removed rock thrown sound (it's looping)
	 
	1.2
	 - Converted to a new syntax and methodmaps
	 - Fixed case when tank throw another tank
	 - Simplified code a little bit
*/

bool gamestart=false;
float throw_all[8];
float g_fTankThrowForce;

public void OnPluginStart()
{
	l4d_tank_throw_si = CreateConVar("l4d_tank_throw_si", "30.0", "tank throws special infected [0.0, 100.0]", FCVAR_NOTIFY);
	
	l4d_tank_throw_hunter 	= CreateConVar("l4d_tank_throw_hunter", "10.0", 	"weight of hunter[0.0, 100.0]", FCVAR_NOTIFY);
	l4d_tank_throw_smoker 	= CreateConVar("l4d_tank_throw_smoker", "5.0", 	"[0.0, 10.0]", FCVAR_NOTIFY);
	l4d_tank_throw_boomer 	= CreateConVar("l4d_tank_throw_boomer", "5.0", 	"[0.0, 10.0]", FCVAR_NOTIFY);
	l4d_tank_throw_charger 	= CreateConVar("l4d_tank_throw_charger", "10.0", 	"[0.0, 10.0]", FCVAR_NOTIFY);
	l4d_tank_throw_spitter	= CreateConVar("l4d_tank_throw_spitter", "5.0", 	"[0.0, 10.0]", FCVAR_NOTIFY);
	l4d_tank_throw_jockey	= CreateConVar("l4d_tank_throw_jockey", "10.0",  	"[0.0, 10.0]", FCVAR_NOTIFY);
	l4d_tank_throw_tank	=	  CreateConVar("l4d_tank_throw_tank", "2.0",  	"[0.0, 10.0]", FCVAR_NOTIFY);
	l4d_tank_throw_self	= 	  CreateConVar("l4d_tank_throw_self", "10.0",  	"[0.0, 10.0]", FCVAR_NOTIFY);	
	l4d_tank_throw_tankhealth=CreateConVar("l4d_tank_throw_witch", "10.0",  	"not true", FCVAR_NOTIFY);
	l4d_tank_throw_tankhealth=CreateConVar("l4d_tank_throw_tankhealth", "1000",  	"", FCVAR_NOTIFY);		
	
	HookEvent("round_end", RoundEnd);
	HookEvent("finale_win", RoundEnd);
	HookEvent("mission_lost", RoundEnd);
	HookEvent("map_transition", RoundEnd);
	HookEvent("tank_spawn", RoundStart);
	HookEvent("ability_use", ability_use);
	
	AutoExecConfig(true, "l4d_tankhelper");
	g_iVelocity = FindSendPropInfo("CBasePlayer", "m_vecVelocity[0]");
	
	char GameName[16];
 
	GetGameFolderName(GameName, sizeof(GameName));
	if (StrEqual(GameName, "left4dead2", false))
	{
		L4D2Version=true;
	}	
	else
	{
		L4D2Version=false;
	}

	l4d_tank_throw_si.AddChangeHook(ConVarChange);	
	l4d_tank_throw_hunter.AddChangeHook(ConVarChange);	
	l4d_tank_throw_smoker.AddChangeHook(ConVarChange);	
	l4d_tank_throw_boomer.AddChangeHook(ConVarChange);	
	l4d_tank_throw_charger.AddChangeHook(ConVarChange);	
	l4d_tank_throw_spitter.AddChangeHook(ConVarChange);	
	l4d_tank_throw_jockey.AddChangeHook(ConVarChange);	
	l4d_tank_throw_tank.AddChangeHook(ConVarChange);
	GetConVar();
	gamestart=true;
	
	AddNormalSoundHook(view_as<NormalSHook>(OnNormalSoundPlay));
}

public void OnAllPluginsLoaded()
{
	g_fTankThrowForce = FindConVar("z_tank_throw_force").FloatValue;
}

public Action OnNormalSoundPlay(int clients[MAXPLAYERS], int &numClients,
		char sample[PLATFORM_MAX_PATH], int &entity, int &channel, float &volume, int &level,
		int &pitch, int &flags, char soundEntry[PLATFORM_MAX_PATH], int &seed)
{
	if (StrEqual(sample, SOUND_THROWN_MISSILE, false)) {
		numClients = 0;
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

public void OnMapStart()
{ 
	if(L4D2Version)
	{ 
		PrecacheParticle("electrical_arc_01_system");
	}
}
public void ConVarChange(Handle convar, const char[] oldValue, const char[] newValue)
{
	GetConVar();

}
void GetConVar()
{
	
	throw_all[0]=l4d_tank_throw_hunter .FloatValue;
	throw_all[1]=throw_all[0]+l4d_tank_throw_smoker .FloatValue;
	throw_all[2]=throw_all[1]+l4d_tank_throw_boomer .FloatValue;
	throw_all[3]=throw_all[2]+l4d_tank_throw_tank .FloatValue;	
	throw_all[4]=throw_all[3]+l4d_tank_throw_self .FloatValue;
	throw_all[5]=throw_all[4]+l4d_tank_throw_charger .FloatValue;
	throw_all[6]=throw_all[5]+l4d_tank_throw_spitter .FloatValue;
	throw_all[7]=throw_all[6]+l4d_tank_throw_jockey .FloatValue;
 
}
public Action RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	gamestart=true;
	tank=0;
}
public Action RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	gamestart=false;
}
public Action ability_use(Event event, const char[] name, bool dontBroadcast)
{
	char s[32];
	event.GetString("ability", s, 32);
	if(StrEqual(s, "ability_throw", true))
	{	
		tank = GetClientOfUserId(event.GetInt("userid"));
	}

}
public void OnEntityCreated(int entity, const char[] classname)
{
	if(!gamestart)return;
	if(tank>0 && IsValidEdict(entity) && StrEqual(classname, "tank_rock", true) && GetEntProp(entity, Prop_Send, "m_iTeamNum")>=0)
	{
		rock[tank]=entity;
		if( GetRandomFloat(0.0, 100.0)<l4d_tank_throw_si.FloatValue)CreateTimer(0.01, TraceRock, tank, TIMER_REPEAT);
		tank=0;
	}
}
public Action TraceRock(Handle timer, int thetank)
{
	static float velocity[3], pos[3];
	static int ent, si;
	ent = rock[thetank];
	if(gamestart && IsValidEdict(ent))
	{		
		GetEntDataVector(ent, g_iVelocity, velocity);
		float v=GetVectorLength(velocity);
		if(v>500.0)
		{
			GetEntPropVector(ent, Prop_Send, "m_vecOrigin", pos);
			if(StuckCheck(ent, pos))
			{
				si=CreateSI(thetank);
				if(si>0)
				{

					RemoveEdict(ent);
					NormalizeVector(velocity, velocity);
					ScaleVector(velocity, g_fTankThrowForce*1.4);
					
					if (IsClientInGame(si)) {
						TeleportEntity(si, pos, NULL_VECTOR, velocity);	
					}
					
					if(L4D2Version)
					{
						ShowParticle(pos, "electrical_arc_01_system", 3.0);		
					}
				}
				
			}
			return Plugin_Stop;
		}
		 
	}
	else
	{
		return Plugin_Stop;
	}
	return Plugin_Continue;
}
bool StuckCheck(int ent, float pos[3])
{
	float vAngles[3];
	float vOrigin[3];
	vAngles[2]=1.0;
	GetVectorAngles(vAngles, vAngles);
	Handle trace = TR_TraceRayFilterEx(pos, vAngles, MASK_SOLID, RayType_Infinite, TraceRayDontHitSelf,ent);

	if(TR_DidHit(trace))
	{
		TR_GetEndPosition(vOrigin, trace);
	 	float dis=GetVectorDistance(vOrigin, pos);
		if(dis>100.0)return true;
	}
	return false;
}

int CreateSI(int thetank)
{
	int selected;
	bool istank=false;
	float r=GetRandomFloat(0.0, throw_all[4]);
	if(L4D2Version)r=GetRandomFloat(0.0, throw_all[7]);
	
	if(r<throw_all[0])
	{
		CheatCommand(thetank, "z_spawn", "hunter"); 
	}
	else if(r<throw_all[1])
	{
		CheatCommand(thetank, "z_spawn", "smoker"); 
	}
	else if(r<throw_all[2])
	{
		CheatCommand(thetank, "z_spawn", "boomer"); 
	}
	else if(r<throw_all[3])
	{
		CheatCommand(thetank, "z_spawn", "tank"); 
		istank=true;
	}
	else if(r<throw_all[4])
	{
		selected=thetank; 
	}
	else if(r<throw_all[5])
	{
		CheatCommand(thetank, "z_spawn", "charger"); 
	}
	else if(r<throw_all[6])
	{
		CheatCommand(thetank, "z_spawn", "spitter"); 
	}
	else if(r<throw_all[7])
	{
		CheatCommand(thetank, "z_spawn", "jockey"); 
	}
	
	if(selected==0)
	{
		int andidate[MAXPLAYERS+1];
		int index=0;
		for(int i = 1; i <= MaxClients; i++)
		{	
			if(IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i)==3 && !IsTank(i))
			{
				andidate[index++]=i;
			}
		}
		if(index>0)
		{
			selected=andidate[GetRandomInt(0, index-1)];
		}
		
	}
	
	if(selected>0 && istank)
	{
		SetEntityHealth(selected, l4d_tank_throw_tankhealth.IntValue);
	}
 
 	return selected;
	
}

stock bool IsTank(int client)
{
	if( client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 3 )
	{
		int class = GetEntProp(client, Prop_Send, "m_zombieClass");
		if( class == (L4D2Version ? 8 : 5 ))
			return true;
	}
	return false;
}
 
stock void CheatCommand(int client, char[] command, char[] arguments = "")
{
	int userFlags = GetUserFlagBits(client);
	SetUserFlagBits(client, ADMFLAG_ROOT);
	int flags = GetCommandFlags(command);
	SetCommandFlags(command, flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "%s %s", command, arguments);
	SetCommandFlags(command, flags);
	SetUserFlagBits(client, userFlags);
}

public void ShowParticle(float pos[3], char[] particlename, float time)
{
 int particle = CreateEntityByName("info_particle_system");
 if (IsValidEdict(particle))
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
 
public void PrecacheParticle(char[] particlename)
{
 int particle = CreateEntityByName("info_particle_system");
 if (IsValidEdict(particle))
 {
		DispatchKeyValue(particle, "effect_name", particlename);
		DispatchKeyValue(particle, "targetname", "particle");
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
public bool TraceRayDontHitSelf(int entity, int mask, any data)
{
	if(entity == data) 
	{
		return false; 
	}
	return true;
}
 
