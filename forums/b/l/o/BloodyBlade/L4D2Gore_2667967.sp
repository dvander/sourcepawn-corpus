/*
** Title: Left 4 Dead 2 Gore
** Author: Joe 'DiscoBBQ' Maley
*/
#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>

#define PARTICLE_COUNT	18

ConVar hGorePluginOn;
static bool playerIncapped[MAXPLAYERS + 1] = {false, ...}, bHooked = false;
static KeyValues cfg;
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

public Plugin myinfo = 
{
	name = "L4D2 Gore",
	author = "DiscoBBQ(edit. by BloodyBlade)",
	description = "Adds blood and gore",
	version = "1.1",
	url = "jmaley@clemson.edu"
};

public void OnPluginStart()
{
	CreateConVar("l4d2gore_version", "1.1", "Base L4D2Gore Version", FCVAR_NOTIFY|FCVAR_SPONLY|FCVAR_UNLOGGED|FCVAR_DONTRECORD);
	hGorePluginOn = CreateConVar("l4d2gore_on", "1.0", "Plugin On/Off", FCVAR_NOTIFY);
	hGorePluginOn.AddChangeHook(ConVarPluginOnChanged);
	AutoExecConfig(true, "l4d2gore");

	PrintToServer("[SM] L4D2 Gore v1.1 by Joe 'DiscoBBQ' Maley loaded successfully!");

	BuildPath(Path_SM, cfgPath, sizeof(cfgPath), "data/gore_config.txt");

	cfg = new KeyValues("cfg");
	if (!FileToKeyValues(cfg, cfgPath))
	{
		PrintToServer("[SM] ERROR: Missing file or incorrectly formated, '%s'", cfgPath);
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
	{
		ForcePrecache(particleList[i]);
	}
}

public void OnConfigsExecuted()
{
	IsAllowed();
}

void ConVarPluginOnChanged(ConVar cvar, char[] OldValue, char[] NewValue)
{
	IsAllowed();
}

void IsAllowed()
{
	bool bPluginOn = hGorePluginOn.BoolValue;
	if(bPluginOn && !bHooked)
	{
		bHooked = true;
		HookEvent("infected_hurt", EventDamageInfected);
		HookEvent("entity_shoved", EventShoveEntity);
		HookEvent("player_hurt", EventDamagePlayer);
		HookEvent("player_death", EventRevivePlayer);
		HookEvent("revive_success", EventRevivePlayer);
		HookEvent("player_incapacitated_start", EventIncapPlayer);
		HookEvent("round_end_message", EventRoundEnd);
		HookEvent("round_start_pre_entity", EventRoundEnd);
		HookEvent("round_start_post_nav", EventRoundEnd);
	}
	else if(!bPluginOn && bHooked)
	{
		bHooked = false;
		UnhookEvent("infected_hurt", EventDamageInfected);
		UnhookEvent("entity_shoved", EventShoveEntity);
		UnhookEvent("player_hurt", EventDamagePlayer);
		UnhookEvent("player_death", EventRevivePlayer);
		UnhookEvent("revive_success", EventRevivePlayer);
		UnhookEvent("player_incapacitated_start", EventIncapPlayer);
		UnhookEvent("round_end_message", EventRoundEnd);
		UnhookEvent("round_start_pre_entity", EventRoundEnd);
		UnhookEvent("round_start_post_nav", EventRoundEnd);
	}
}

void EventDamageInfected(Event event, const char[] eventName, bool broadcast)
{
	int ent = event.GetInt("entityid");
	if (IsValidEntity(ent) && ent != 0)
	{
		for (int i = 0; i < PARTICLE_COUNT; i++)
		{	
			float roll = GetRandomFloat(0.0, 100.0);
			if (roll <= 0.15 * bloodCfg[0])
			{
			    WriteParticle(ent, particleList[i]);
			}
		}
	}
}

void EventShoveEntity(Event event, const char[] eventName, bool broadcast)
{
	char className[64];
	int ent = event.GetInt("entityid");
	GetEdictClassname(ent, className, sizeof(className));
	if(StrContains(className, "infected", false) != -1 || StrContains(className, "player", false) != -1)
	{
		float roll;
		roll = GetRandomFloat(0.0, 100.0);
		if (roll <= 0.2 * bloodCfg[3])
		{
			WriteParticle(ent, "gore_wound_fullbody_2");
		}
		roll = GetRandomFloat(0.0, 100.0);
		if (roll <= 0.5 * bloodCfg[3])
		{
			WriteParticle(ent, "gore_wound_brain");
		}
		roll = GetRandomFloat(0.0, 100.0);
		if (roll <= 0.2 * bloodCfg[3])
		{
			WriteParticle(ent, "gore_wound_belly_left");
		}
	}
}

void EventDamagePlayer(Event event, const char[] eventName, bool broadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (IsValidEntity(client) && client != 0)
	{
		float roll;
		for (int i = 1; i < PARTICLE_COUNT; i++)
		{
			roll = GetRandomFloat(0.0, 100.0);
			if (roll <= 0.15 * bloodCfg[1] && !playerIncapped[client])
			{
				WriteParticle(client, particleList[i]);
			}
		}
	}
}

void EventIncapPlayer(Event event, const char[] eventName, bool broadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (IsValidEntity(client) && client != 0)
	{
		playerIncapped[client] = true;
	}
}

void EventRevivePlayer(Event event, const char[] eventName, bool broadcast)
{
	int client = GetClientOfUserId(event.GetInt("subject"));
	if (IsValidEntity(client) && client != 0)
	{
		playerIncapped[client] = false;
	}
}

void EventRoundEnd(Event event, const char[] name, bool broadcast)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		playerIncapped[i] = false;
	}
}

public void OnGameFrame()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) != 1 && !(GetEntProp(i, Prop_Send, "m_isGhost", 1) == 1))
		{
			float roll;
			if (playerIncapped[i])
			{
				roll = GetRandomFloat(0.0, 100.0);
				if (roll <= 0.05 * bloodCfg[2])
				{
					WriteParticle(i, "blood_impact_arterial_spray", true);
				}
				roll = GetRandomFloat(0.0, 100.0);
				if (roll <= 0.05 * bloodCfg[2])
				{
					WriteParticle(i, "blood_impact_arterial_spray_5", true);
				}
				roll = GetRandomFloat(0.0, 100.0);
				if (roll <= 0.05 * bloodCfg[2])
				{
					WriteParticle(i, "blood_impact_arterial_spray_drippy", true);
				}
			}
			else
			{
				int health = GetClientHealth(i);
				if (health <= bloodCfg[4] && IsPlayerAlive(i))
				{
					roll = GetRandomFloat(1.0, (float(health) * 0.15 * float(bloodCfg[1])));
					int roundedRoll = RoundFloat(roll);
					if (roundedRoll == 2) WriteParticle(i, "blood_impact_arterial_spray_drippy");
					if (roundedRoll == 3) WriteParticle(i, "blood_impact_arterial_spray_5");
					if (roundedRoll == 4) WriteParticle(i, "blood_impact_arterial_spray");
				}
			}
		}
	}
}

void WriteParticle(int ent, char[] particleName, bool incapped = false)
{
	char targetName[64];
	int particle = CreateEntityByName("info_particle_system");
	if (IsValidEdict(particle))
	{
		float pos[3];
		GetEntPropVector(ent, Prop_Send, "m_vecOrigin", pos);
		pos[0] += GetRandomFloat(-10.0, 10.0);
		pos[1] += GetRandomFloat(-10.0, 10.0);

		if (!incapped)
		{
			pos[2] += GetRandomFloat(15.0, 65.0);
		}
		else
		{
			pos[2] += GetRandomFloat(0.0, 15.0);
		}

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
		{
			CreateTimer(GetRandomFloat(1.0, 2.0), DeleteParticle, particle);
		}
		else
		{
			if (StrContains(particleName, "arterial", false) != -1)
			{
				CreateTimer(GetRandomFloat(0.6, 1.00), DeleteParticle, particle);
			}
			else
			{
				CreateTimer(GetRandomFloat(0.3, 0.5), DeleteParticle, particle);
			}
		}
	}
}

Action DeleteParticle(Handle timer, any particle)
{
	if (IsValidEntity(particle) && particle != 0)
	{
		char className[64];
		GetEdictClassname(particle, className, sizeof(className));
		if (StrEqual(className, "info_particle_system", false))
		{
			RemoveEdict(particle);
		}
	}
	return Plugin_Stop;
}

int LoadInt(KeyValues vault, const char key[32], const char save_key[255], int default_value)
{
	vault.JumpToKey(key, false);
	int variable = vault.GetNum(save_key, default_value);
	vault.Rewind();
	return variable;
}

void ForcePrecache(char[] particleName)
{
	int particle = CreateEntityByName("info_particle_system");
	if (IsValidEdict(particle) && particle != 0)
	{
		DispatchKeyValue(particle, "effect_name", particleName);
		DispatchSpawn(particle);
		ActivateEntity(particle);
		AcceptEntityInput(particle, "start");
		CreateTimer(1.0, DeleteParticle, particle, TIMER_FLAG_NO_MAPCHANGE);
	}
}
