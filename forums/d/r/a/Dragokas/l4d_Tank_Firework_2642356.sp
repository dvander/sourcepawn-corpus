#define PLUGIN_VERSION		"1.0"

/*
========================================================================================
	Change Log:

	1.0 (07-Mar-2019)
	- First commit

========================================================================================*/

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

#define DEBUG 0

char g_sEffect[][64] = {
		"embers_small_01", // should repeat
		"mini_fireworks", // should repeat
		"gas_explosion_chunks_01",
		"explosion_huge_b",
		"aircraft_destroy_sparksR1",
		"aircraft_destroy_sp_nose2_bak",
		"aircraft_destroy_sp_nose1_bak",
		"gas_explosion_main_fallback"
		//"blood_impact_red_01_smalldroplets_shotgun"
	};

ArrayList aRealRandom;
	
bool g_bLeft4Dead2;

public Plugin myinfo = 
{
	name = "Tank Firework",
	author = "Alex Dragokas",
	description = "Creates firework when tank dies",
	version = PLUGIN_VERSION,
	url = "https://github.com/dragokas/"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();
	if (test == Engine_Left4Dead2) {
		g_bLeft4Dead2 = true;		
	}
	else if (test != Engine_Left4Dead) {
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 1 & 2.");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

public void OnPluginStart()
{
	CreateConVar("sm_firework_version", PLUGIN_VERSION, "Plugin version", FCVAR_DONTRECORD);
	
	HookEvent("player_death", 			Event_PlayerDeath, 		EventHookMode_Pre);
	
	aRealRandom = new ArrayList(ByteCountToCells(4));
	
	RegAdminCmd("sm_firework", 		Cmd_Firework,	ADMFLAG_ROOT, 	"Create firework on self or aim target");
}

public Action Cmd_Firework(int client, int args)
{
	int aim = GetClientAimTarget(client, false);
	
	if (aim <= 0)
		aim = client;
	
	SpawnFirework(aim);
	
	return Plugin_Handled;
}

public void Event_PlayerDeath(Event hEvent, const char[] name, bool DontBroadcast)
{
	int client = GetClientOfUserId(hEvent.GetInt("userid"));
	
	if (client && IsClientInGame(client)) {
		if (IsTank(client)) {
			SpawnFirework(client);
		}
	}
}

void SpawnFirework(int client)
{
	if (aRealRandom.Length == 0)
		for (int i = 0; i < sizeof(g_sEffect); i++)
			aRealRandom.Push(i);
	
	int idx = GetRandomInt(0, aRealRandom.Length - 1);
	int rand = aRealRandom.Get(idx);
	aRealRandom.Erase(idx);
	
	#if DEBUG
		PrintToChatAll("Selected effect number: %i", rand);
	#endif
	
	if (rand < 4) {
		SpawnEffectRepeat(client, rand);
	}
	else {
		SpawnEffect(client, g_sEffect[rand]);
	}
}

void SpawnEffectRepeat(int client, int iIdxEffect)
{
	const EFFECTS_COUNT = 7;

	DataPack dp = new DataPack();
	float pos[3];
	GetEyeOrigin(client, pos);
	dp.WriteCell(iIdxEffect);
	dp.WriteFloat(pos[0]);
	dp.WriteFloat(pos[1]);
	dp.WriteFloat(pos[2]);
	
	#if DEBUG
		PrintToChatAll("Spawn multiple effects of: %s", g_sEffect[iIdxEffect]);
	#endif
	
	for (int i = 0; i < EFFECTS_COUNT; i++)
		CreateTimer(0.1 + i, Timer_SpawnEffect, dp, TIMER_FLAG_NO_MAPCHANGE | (view_as<int>(i == EFFECTS_COUNT - 1) * TIMER_HNDL_CLOSE)); // true == 1
}

public Action Timer_SpawnEffect(Handle timer, DataPack dp)
{
	int iIdxEffect;
	float pos[3];
	
	dp.Reset();
	iIdxEffect = dp.ReadCell();
	pos[0] = dp.ReadFloat();
	pos[1] = dp.ReadFloat();
	pos[2] = dp.ReadFloat();
	SpawnEffect(0, g_sEffect[iIdxEffect], pos, 4.0);
}

public void OnMapStart()
{
	PrecacheEffect("ParticleEffect");
	PrecacheGeneric("particles/blood_fx.pcf", true);
	PrecacheGeneric("particles/environment_fx.pcf", true);
	PrecacheGeneric("particles/fire_01.pcf", true);
	PrecacheGeneric("particles/steamworks.pcf", true);
	for (int i = 0; i < sizeof(g_sEffect); i++)
		PrecacheParticleEffect(g_sEffect[i]);
}

stock void PrecacheEffect(const char[] sEffectName) // thanks to Dr. Api
{
    static int table = INVALID_STRING_TABLE;
    
    if (table == INVALID_STRING_TABLE)
    {
        table = FindStringTable("EffectDispatch");
    }
    bool save = LockStringTables(false);
    AddToStringTable(table, sEffectName);
    LockStringTables(save);
}

stock void PrecacheParticleEffect(const char[] sEffectName) // thanks to Dr. Api
{
    static int table = INVALID_STRING_TABLE;
    
    if (table == INVALID_STRING_TABLE)
    {
        table = FindStringTable("ParticleEffectNames");
    }
    bool save = LockStringTables(false);
    AddToStringTable(table, sEffectName);
    LockStringTables(save);
}  

bool GetEyeOrigin(int client, float vecEyeOrigin[3])
{
	char sClass[32];
	
	GetEntityClassname(client, sClass, sizeof(sClass));
	
	if (StrEqual(sClass, "player", false)) {
		GetClientEyePosition(client, vecEyeOrigin);
	}
	else {
		if (HasEntProp(client, Prop_Data, "m_vecOrigin")) {
			GetEntPropVector(client, Prop_Data, "m_vecOrigin", vecEyeOrigin);
		}
		else {
			PrintToChatAll("Entity %i has no m_vecOrigin property.", client);
			return false;
		}
	}
	return true;
}

void SpawnEffect(int client, char[] sParticleName, float pos[3] = {0.0, 0.0, 0.0}, float delay = 7.0)
{
	if (client != 0)
		if (!GetEyeOrigin(client, pos))
			return;
	
	int iEntity = CreateEntityByName("info_particle_system", -1);
	if (iEntity != -1)
	{
		#if DEBUG
			PrintToChatAll("\x03[Firework] Spawning effect \x04%s\x03 on: \x05%i", sParticleName, client);
		#endif
		
		pos[0] += GetRandomFloat(-10.0, 10.0);
		pos[1] += GetRandomFloat(-10.0, 10.0);
		pos[2] += 80 + GetRandomFloat(0.0, 40.0);
		
		float vAng[3];
		//vAng[1] = 90.0;
		
		DispatchKeyValue(iEntity, "effect_name", sParticleName);
		DispatchKeyValueVector(iEntity, "origin", pos);
		DispatchKeyValueVector(iEntity, "angles", vAng);
		DispatchSpawn(iEntity);
		/*
		SetVariantString("!activator");
		AcceptEntityInput(iEntity, "SetParent", client);
		SetVariantString("!activator");
		AcceptEntityInput(iEntity, "SetParentAttachment", client);
		*/
		ActivateEntity(iEntity);
		AcceptEntityInput(iEntity, "Start");
		char sKillCmd[64];
		Format(sKillCmd, sizeof(sKillCmd), "OnUser1 !self:kill::%.1f:1", delay);
		SetVariantString(sKillCmd);
		AcceptEntityInput(iEntity, "AddOutput");
		AcceptEntityInput(iEntity, "FireUser1");
	}
}

stock bool IsTank(int client)
{
	if( client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 3 )
	{
		int class = GetEntProp(client, Prop_Send, "m_zombieClass");
		if( class == (g_bLeft4Dead2 ? 8 : 5 ))
			return true;
	}
	return false;
}