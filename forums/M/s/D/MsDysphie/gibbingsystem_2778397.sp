// TO-DO: 
// - ran rotation & ran torque
// - gib spawn volume respects npc size, eg. kid, crawler
// - gibs corresponds to damage type, burn to crisp, poison into slime etc
#pragma semicolon 1
#define DEBUG 1

#include <sourcemod>
#include <sdktools>

new Handle:sv_gibsys_num_gibs_rib = INVALID_HANDLE;
new Handle:sv_gibsys_maxhealth_ratio = INVALID_HANDLE;
new Handle:sv_gibsys_mindamage_threshold = INVALID_HANDLE;
new Handle:sv_gibsys_gib_speed = INVALID_HANDLE;

const MAX_GIBS = 30;
int gibPool[MAX_GIBS];
int gibPool_pt;

int latestSpawnTime = 0;
int latestGibCount = 0;

public Plugin myinfo = 
{
	name = "Gibbing System",
	author = "RhymeOfRime",
	description = "Gib zombies & players upon death by extra-fatal damage.",
	version = "2.00",
	url = "rhymeofrime.site.nfoservers.com"
};

public void OnPluginStart()
{
	PrintToServer("\n======== [SM GibSys] Starting plugin ========");
	
	// ConVars
	sv_gibsys_num_gibs_rib = CreateConVar("sv_gibsys_num_gibs_rib", "3", "Number of ribs to spawn on death (max gibs will be constrained by MAX_GIBS, check the code)");
	sv_gibsys_maxhealth_ratio = CreateConVar("sv_gibsys_maxhealth_ratio", "0.8", "Gibbing criteria 1: Additional damage (pass 0hp) must exceed this portion of maxhealth. Eg. 0.8 means 80% of maxhealth");
	sv_gibsys_mindamage_threshold = CreateConVar("sv_gibsys_mindamage_threshold", "-800.0", "Gibbing criteria 2: Health must be less than this level (Constant for all character). Eg. -800 means character will gib having health below -800hp");
	sv_gibsys_gib_speed = CreateConVar("sv_gibsys_gib_speed", "100", "Min speed in which gib flies. Eg. 100 means character gibs flies in 100 units/second when health drops just barely meet gibbing criteria, faster if higher damage");
	
	// chat command
	RegAdminCmd("sm_gibsys_printGibPoolIndex", Command_debugGibPool, ADMFLAG_ROOT, "(Debug) Print gib pool indices in console");
	RegConsoleCmd("sm_gibme", Command_gibme, "Gib explode myself (Only when not infected)");

	// Hooks certain events to be referenced later on.
	HookEvent("npc_killed", OnNPCKilled);
	HookEvent("player_death", OnPlayerKilled);
	
	HookEvent("nmrih_reset_map", OnResetMap);
	
	PrintToServer("======== [SM GibSys] Initialization completed ========\n ");
}

// TO-DO not working
public Action:Command_gibme(client, args)
{		
	if (IsClientInGame(client) && IsPlayerAlive(client))
	{
		if(!IsClientInfected(client))
		{
			//PrintToChatAll("gib");
			ForcePlayerSuicide(client);
			GibPerson(client, 500.0, false);
		}
		else
		{
			PrintToChat(client,"You were infected and cannot self-gib");
		}
	}
	
	return Plugin_Handled;
}

public Action:Command_debugGibPool(client, args)
{
	// debug gib pool
	for (int i=0;i<MAX_GIBS;i++)
    {
		char debugStr[64];
		Format(debugStr, sizeof(debugStr), " [SM Debug GibSys] Gib table index: %i, entity index: %i", i, gibPool[i]);
		//PrintToChatAll(debugStr);
		PrintToConsole(client, debugStr);
    }
	
	return Plugin_Handled;
}


public OnMapStart()
{
	PrecacheModel("models/gibs/hgibs_scapula.mdl");
	PrecacheModel("models/gibs/hgibs_spine.mdl");
	PrecacheModel("models/gibs/hgibs.mdl");
	PrecacheModel("models/gibs/hgibs_rib.mdl");
	PrecacheSound("physics/flesh/flesh_bloody_break.wav", true);
	
	clearPool();
}

public Action:OnResetMap(Handle:event, const String:name[], bool:dontBroadcast)
{
	clearPool();
	return Plugin_Continue;
}
public OnMapEnd()
{
	clearPool();
}
public void clearPool()
{
	PrintToServer(" [SM GibSys] Gib pool cleared");
	// Clean gib references
	gibPool_pt = 0;
	for (int i=0;i<MAX_GIBS;i++)
    {
        gibPool[i] = -1;
    }
}


public void GibPerson(int entID, float gibSpeed, bool isNPC)
{
	EmitSoundToAll("physics/flesh/flesh_bloody_break.wav", entID, _, _, _, 1.0);
		
	// hide ragdoll
	if(isNPC)
	{
		SetEntityRenderMode(entID, RENDER_NONE);
	}
	else
	{
		int ragdollID = GetEntPropEnt(entID, Prop_Send, "m_hRagdoll");
		if(ragdollID > 0 && IsValidEdict(ragdollID))
		{
			AcceptEntityInput(ragdollID, "Kill");
		}
	}
	
	// get zombie position
	float zombiePosition[3];
	GetEntPropVector(entID, Prop_Send, "m_vecOrigin", zombiePosition);
	
	// spawn pelvis
	zombiePosition[2] += 30;
	spawnGib("models/gibs/hgibs_scapula.mdl", 2, zombiePosition, 10.0, gibSpeed);
	
	// spawn spine
	zombiePosition[2] += 15;
	spawnGib("models/gibs/hgibs_spine.mdl", 1, zombiePosition, 10.0, gibSpeed);
	
	// spawn main blood particle
	// particle name: nmrih_suicide_grenade
	spawnParticle("headshot_burst_splat_2", NULL_VECTOR, zombiePosition, 10.0);
	
	// spawn ribs
	zombiePosition[2] += 15;
	spawnGib("models/gibs/hgibs_rib.mdl", GetConVarInt(sv_gibsys_num_gibs_rib), zombiePosition, 32.0, gibSpeed);

	// spawn head
	zombiePosition[2] += 8;
	spawnGib("models/gibs/hgibs.mdl", 1, zombiePosition, 0.0, gibSpeed);
}


public Action:OnPlayerKilled(Handle:event, const String:name[], bool:dontBroadcast)
{
	int playerID = GetClientOfUserId(GetEventInt(event, "userid"));
	int postDeathHealth = GetEntProp(playerID, Prop_Data, "m_iHealth");
	int maxHealth = GetEntProp(playerID, Prop_Data, "m_iMaxHealth", 1);
	float gibHPThreshold = GetConVarFloat(sv_gibsys_mindamage_threshold);
	float gibSpeed = GetConVarFloat(sv_gibsys_gib_speed) * (postDeathHealth / gibHPThreshold);
	//PrintToChatAll("id: %i, health:  %i", playerID, postDeathHealth);
	if(!IsClientInfected(playerID) && postDeathHealth < GetConVarFloat(sv_gibsys_maxhealth_ratio) * -maxHealth && postDeathHealth < gibHPThreshold)
	{
		GibPerson(playerID, gibSpeed, false);
	}

	return Plugin_Continue;
}

public Action:OnNPCKilled(Handle:event, const String:name[], bool:dontBroadcast)
{	
	int zombieID = GetEventInt(event, "entidx");
	int postDeathHealth = GetEntProp(zombieID, Prop_Data, "m_iHealth");
	int maxHealth = GetEntProp(zombieID, Prop_Data, "m_iMaxHealth", 1);
	float gibHPThreshold = GetConVarFloat(sv_gibsys_mindamage_threshold);
	float gibSpeed = GetConVarFloat(sv_gibsys_gib_speed) * (postDeathHealth / gibHPThreshold);
	
	if(postDeathHealth < GetConVarFloat(sv_gibsys_maxhealth_ratio) * -maxHealth && postDeathHealth < gibHPThreshold)
	{
		GibPerson(zombieID, gibSpeed, true);
	}
	
	return Plugin_Continue;
}
public void spawnParticle(const String:particleName[], const Float:angles[3], const Float:position[3], float duration)
{
	new particle = CreateEntityByName("info_particle_system");
	
	// set particle effect
	DispatchKeyValue(particle, "effect_name", particleName);
	
	if(DispatchSpawn(particle))
	{	
		ActivateEntity(particle);
		TeleportEntity(particle, position, angles, NULL_VECTOR);
		AcceptEntityInput(particle, "start");
		CreateTimer(duration, Timer_RemoveParticle, EntIndexToEntRef(particle));
	}
}
public void spawnGib(const String:model[], int number_gibs, const Float:spawnCenterPosition[3], float variance, float gibSpeed)
{	
	// Budget Clamp by frame
	int currTime = GetTime();
	if(currTime != latestSpawnTime) 
	{
		latestSpawnTime = currTime;
		latestGibCount = 0;
	}
	int remainingBudget = MAX_GIBS - latestGibCount; 
	remainingBudget = 0 > remainingBudget ? 0:remainingBudget;
	int gibCountToSpawn = number_gibs < remainingBudget ? number_gibs:remainingBudget;
	latestGibCount += gibCountToSpawn;
	
	// Spawn gibs
	for (new i = 0; i < gibCountToSpawn; i++)
	{
		int gib_entIdx = CreateEntityByName("prop_physics");

		// Set entity name
		char gibName[32];
		Format(gibName, sizeof(gibName), "gsmerzParticle%i", gib_entIdx);
		DispatchKeyValue(gib_entIdx, "targetname", gibName);

		// Set model
		DispatchKeyValue(gib_entIdx, "model", model);
		DispatchKeyValue(gib_entIdx, "spawnflags", "512");// no pickup
		
		if(DispatchSpawn(gib_entIdx))
		{
			if(IsValidEntity(gib_entIdx))
			{
				// Only collide with world geometry
				SetEntProp(gib_entIdx, Prop_Send, "m_CollisionGroup", 1);
			
				// Set position & velocity & attach trail
				float pos[3], vel[3];
				pos[0] = spawnCenterPosition[0] + GetRandomFloat(variance / 2.0, variance / 2.0);
				pos[1] = spawnCenterPosition[1] + GetRandomFloat(variance / 2.0, variance / 2.0);
				pos[2] = spawnCenterPosition[2] + GetRandomFloat(variance / 2.0, variance / 2.0);

				vel[0] = GetRandomFloat(-gibSpeed, gibSpeed);
				vel[1] = GetRandomFloat(-gibSpeed, gibSpeed);
				vel[2] = GetRandomFloat(-gibSpeed, gibSpeed * 2.0);
				
				TeleportEntity(gib_entIdx, pos, NULL_VECTOR, vel);
				AttachParticle(gib_entIdx, "headshot_blood_splats");
				
				// Pool gibs
				if(gibPool_pt >= MAX_GIBS)// Warp index
				{
					gibPool_pt = 0;
				}
				if(gibPool[gibPool_pt] != -1)// Despawn outdated gib
				{
					int oldGibID = gibPool[gibPool_pt];
					
					char oldGibClassName[32];
					GetEdictClassname(oldGibID, oldGibClassName, 32);
	
					char oldGibModelName[128];
					GetEntPropString(oldGibID, Prop_Data, "m_ModelName", oldGibModelName, 128);
	
					if(IsValidEntity(oldGibID) && strcmp(oldGibClassName, "prop_physics") == 0)
					{
						AcceptEntityInput(oldGibID, "kill");
					}
				}
				gibPool[gibPool_pt] = gib_entIdx;
				gibPool_pt++;
			}
			else
			{
				PrintToServer("Could not create gib.");
			}
		}
	}
}

public Action:Timer_RemoveParticle(Handle:Timer, int entref)
{
	int ent = EntRefToEntIndex(entref);
	if (ent == -1) {
		return Plugin_Continue;
	}

	char className[32];
	GetEntityClassname(ent, className, 32);

	if(IsValidEntity(ent) && strcmp(className, "info_particle_system") == 0)
	{
		AcceptEntityInput(ent, "kill");
	}
	
	return Plugin_Handled;
}

AttachParticle(ent, String:particleType[])
{
	new particle = CreateEntityByName("info_particle_system");
	
	new String:tName[128], String:pName[128];
	if (IsValidEdict(particle))
	{
		new Float:pos[3];
		GetEntPropVector(ent, Prop_Send, "m_vecOrigin", pos);
		
		
		TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);
		
		
		Format(tName, sizeof(tName), "target%i", ent);
		DispatchKeyValue(ent, "targetname", tName);
		
		Format(pName, sizeof(pName), "particle%i", ent);
		DispatchKeyValue(particle, "targetname", pName);
		
		DispatchKeyValue(particle, "parentname", tName);
		DispatchKeyValue(particle, "effect_name", particleType);
		DispatchSpawn(particle);
		
		SetVariantString(tName);
		AcceptEntityInput(particle, "SetParent", particle, particle, 0);
		
		ActivateEntity(particle);
		AcceptEntityInput(particle, "start");
	}
}

public bool IsClientInfected(Client)
{
	if(GetEntPropFloat(Client, Prop_Send, "m_flInfectionTime") > 0 && GetEntPropFloat(Client, Prop_Send, "m_flInfectionDeathTime") > 0) 
	{
		return true;
	}
	else {
		return false;
	}
}