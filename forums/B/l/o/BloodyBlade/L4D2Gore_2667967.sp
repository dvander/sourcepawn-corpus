/*
** Title: Left 4 Dead 2 Gore
** Author: Joe 'DiscoBBQ' Maley
*/
#pragma newdecls required
#include <sourcemod>
#include <sdktools>

#define MAX_PLAYERS	33
#define PARTICLE_COUNT	18

static bool playerIncapped[MAX_PLAYERS];

static Handle cfg;
static int bloodCfg[5];
static char cfgPath[128];

static char particleList[PARTICLE_COUNT][64] =
{
	"boomer_explode_d",
	"blood_chainsaw_constant_b",
	"blood_chainsaw_constant_tp",
	"blood_chainsaw_constant_fp",
	"blood_impact_arterial_spray",
	"blood_impact_arterial_spray_5",
	"blood_impact_arterial_spray_drippy",
	"gore_entrails",
	"gore_wound_abdomen_through",
	"gore_wound_abdomen_through_2",
	"gore_wound_arterial_spray_2",
	"gore_wound_back",
	"gore_wound_belly_left",
	"gore_wound_brain",
	"gore_wound_fullbody_1",
	"gore_wound_fullbody_2",
	"gore_wound_fullbody_3",
	"gore_wound_fullbody_4"
};

void WriteParticle(int ent, char[] particleName, bool incapped = false)
{		
	int particle;
	char targetName[64];
	particle = CreateEntityByName("info_particle_system");
	if (IsValidEdict(particle))
	{
		float pos[3];
		GetEntPropVector(ent, Prop_Send, "m_vecOrigin", pos);
		pos[0] += GetRandomFloat(-10.0, 10.0);
		pos[1] += GetRandomFloat(-10.0, 10.0);

		if (!incapped)
			pos[2] += GetRandomFloat(15.0, 65.0);
		else 
			pos[2] += GetRandomFloat(0.0, 15.0);
		
		TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);

		Format(targetName, sizeof(targetName), "Entity%d", ent);

		DispatchKeyValue(ent, "targetname", targetName);
		GetEntPropString(ent, Prop_Data, "m_iName", targetName, sizeof(targetName));
		DispatchKeyValue(particle, "targetname", "L4D2Particle");
		DispatchKeyValue(particle, "parentname", targetName);
		DispatchKeyValue(particle, "effect_name", particleName);

		DispatchSpawn(particle);
		
		SetVariantString(targetName);
		AcceptEntityInput(particle, "SetParent", particle, particle);
		
		ActivateEntity(particle);
		AcceptEntityInput(particle, "start");

		if (incapped)
			CreateTimer(GetRandomFloat(1.0, 2.0), DeleteParticle, particle);
		else
		{
			if (StrContains(particleName, "arterial", false) != -1)
				CreateTimer(GetRandomFloat(0.6, 1.00), DeleteParticle, particle);
			else
				CreateTimer(GetRandomFloat(0.3, 0.5), DeleteParticle, particle);
		}
	}
}

public Action DeleteParticle(Handle timer, any particle)
{
	if (IsValidEntity(particle) && particle != 0)
	{
		char className[64];
		GetEdictClassname(particle, className, sizeof(className));
		if (StrEqual(className, "info_particle_system", false))
			RemoveEdict(particle);
	}
}

public void EventDamageInfected(Event event, const char[] eventName, bool broadcast)
{
	int ent;	
	ent = GetEventInt(event, "entityid");
	if (IsValidEntity(ent) && ent != 0)
	{
		float roll;
		for (int i = 0; i < PARTICLE_COUNT; i++)
		{	
			roll = GetRandomFloat(0.0, 100.0);
			if (roll <= 0.15 * bloodCfg[0]) WriteParticle(ent, particleList[i]);
		}
	}
}

public void EventShoveEntity(Event event, const char[] eventName, bool broadcast)
{
	int ent;
	char className[64];
	ent = GetEventInt(event, "entityid");
	GetEdictClassname(ent, className, sizeof(className));
	if(StrContains(className, "infected", false) != -1 || StrContains(className, "player", false) != -1)
	{
		float roll;
		roll = GetRandomFloat(0.0, 100.0);
		if (roll <= 0.2 * bloodCfg[3]) WriteParticle(ent, "gore_wound_fullbody_2");
	
		roll = GetRandomFloat(0.0, 100.0);
		if (roll <= 0.5 * bloodCfg[3]) WriteParticle(ent, "gore_wound_brain");
	
		roll = GetRandomFloat(0.0, 100.0);
		if (roll <= 0.2 * bloodCfg[3]) WriteParticle(ent, "gore_wound_belly_left");
	}
}

public void EventDamagePlayer(Event event, const char[] eventName, bool broadcast)
{
	int client;
	client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IsValidEntity(client) && client != 0)
	{
		float roll;
		for (int i = 1; i < PARTICLE_COUNT; i++)
		{
			roll = GetRandomFloat(0.0, 100.0);
			if (roll <= 0.15 * bloodCfg[1] && !playerIncapped[client]) WriteParticle(client, particleList[i]);
		}
	}
}

public void EventIncapPlayer(Event event, const char[] eventName, bool broadcast)
{
	int client;
	client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IsValidEntity(client) && client != 0)
		playerIncapped[client] = true;
}

public void EventRevivePlayer(Event event, const char[] eventName, bool broadcast)
{
	int client;
	client = GetClientOfUserId(GetEventInt(event, "subject"));
	if (IsValidEntity(client) && client != 0)
		playerIncapped[client] = false;
}

public void EventRoundEnd(Event event, const char[] name, bool broadcast)
{
	for (int i = 1; i <= GetMaxClients(); i++)
		playerIncapped[i] = false;
}

public void OnGameFrame()
{
	for (int i = 1; i <= GetMaxClients(); i++)
	{
		float roll;
		if (playerIncapped[i] && IsClientInGame(i))
		{
			roll = GetRandomFloat(0.0, 100.0);
			if (roll <= 0.05 * bloodCfg[2]) WriteParticle(i, "blood_impact_arterial_spray", true);
			
			roll = GetRandomFloat(0.0, 100.0);
			if (roll <= 0.05 * bloodCfg[2]) WriteParticle(i, "blood_impact_arterial_spray_5", true);
			
			roll = GetRandomFloat(0.0, 100.0);
			if (roll <= 0.05 * bloodCfg[2]) WriteParticle(i, "blood_impact_arterial_spray_drippy", true);
		}
		else if (IsClientInGame(i))
		{
			int health;
			health = GetClientHealth(i);
			if (health <= bloodCfg[4] && IsPlayerAlive(i) && !playerIncapped[i])
			{
				roll = GetRandomFloat(1.0, (float(health) * 0.15 * float(bloodCfg[1])));
				int roundedRoll = RoundFloat(roll);
				if (roundedRoll == 2)
					WriteParticle(i, "blood_impact_arterial_spray_drippy");

				if (roundedRoll == 3)
					WriteParticle(i, "blood_impact_arterial_spray_5");

				if (roundedRoll == 4)
					WriteParticle(i, "blood_impact_arterial_spray");
			}
		}
	}
}

int LoadInt(Handle vault, const char key[32], const char save_key[255], int default_value)
{
	int variable;
	KvJumpToKey(vault, key, false);
	variable = KvGetNum(vault, save_key, default_value);
	KvRewind(vault);

	return variable;
}

void ForcePrecache(char[] particleName)
{
	int particle;
	particle = CreateEntityByName("info_particle_system");
	if (IsValidEdict(particle) && particle != 0)
	{
		DispatchKeyValue(particle, "effect_name", particleName);

		DispatchSpawn(particle);
		ActivateEntity(particle);
		AcceptEntityInput(particle, "start");
		
		CreateTimer(1.0, DeleteParticle, particle, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public void OnMapStart()
{
	bloodCfg[0] = LoadInt(cfg, "Infected Damage", "Gore Modifier", 100);
	bloodCfg[1] = LoadInt(cfg, "Human Player Damage", "Gore Modifier", 100);
	bloodCfg[2] = LoadInt(cfg, "Human Player Incap", "Gore Modifier", 100);
	bloodCfg[3] = LoadInt(cfg, "Melee", "Gore Modifier", 100);\
	bloodCfg[4] = LoadInt(cfg, "Periodic Bleeding", "Health Required", 0);
	
	for (int i = 0; i < PARTICLE_COUNT; i++)
		ForcePrecache(particleList[i]);
}

public Plugin myinfo = 
{
	name = "L4D2 Gore",
	author = "DiscoBBQ",
	description = "Adds blood and gore",
	version = "1.1",
	url = "jmaley@clemson.edu"
};

public void OnPluginStart()
{
	PrintToServer("[SM] L4D2 Gore v1.1 by Joe 'DiscoBBQ' Maley loaded successfully!");

	HookEvent("infected_hurt", EventDamageInfected);
	HookEvent("entity_shoved", EventShoveEntity);
	
	HookEvent("player_hurt", EventDamagePlayer);
	HookEvent("player_death", EventRevivePlayer);
	HookEvent("revive_success", EventRevivePlayer);
	HookEvent("player_incapacitated_start", EventIncapPlayer);
	
	HookEvent("round_end_message", EventRoundEnd);
	HookEvent("round_start_pre_entity", EventRoundEnd);
	HookEvent("round_start_post_nav", EventRoundEnd);

	BuildPath(Path_SM, cfgPath, sizeof(cfgPath), "data/gore_config.txt");
	
	cfg = CreateKeyValues("cfg");
	if (!FileToKeyValues(cfg, cfgPath))
		PrintToServer("[SM] ERROR: Missing file or incorrectly formated, '%s'", cfgPath);

	CreateConVar("l4d2gore_version", "1.1", "Base L4D2Gore Version", FCVAR_SPONLY|FCVAR_UNLOGGED|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
}