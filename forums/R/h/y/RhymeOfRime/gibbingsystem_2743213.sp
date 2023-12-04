// New:
// gib spawn volume respects npc size, eg. kid, crawler

// TO-DO: 
// - ran rotation & ran torque
// - gibs corresponds to damage type, burn to crisp, poison into slime etc
#pragma semicolon 1
#define DEBUG 1

#include <sourcemod>
#include <sdktools>

#define GIB_CLASS_NAME "prop_gib_merz"
new Handle:sv_gibsys_num_gibs_rib = INVALID_HANDLE;
new Handle:sv_gibsys_maxhealth_ratio = INVALID_HANDLE;
new Handle:sv_gibsys_mindamage_threshold = INVALID_HANDLE;
new Handle:sv_gibsys_gib_speed = INVALID_HANDLE;
new Handle:sv_gibsys_model_rib = INVALID_HANDLE;
new Handle:sv_gibsys_model_skull = INVALID_HANDLE;
new Handle:sv_gibsys_model_pelvis = INVALID_HANDLE;
new Handle:sv_gibsys_model_spine = INVALID_HANDLE;
new Handle:sv_gibsys_particle_splat = INVALID_HANDLE;
new Handle:sv_gibsys_particle_gib = INVALID_HANDLE;
new Handle:sv_gibsys_no_particle = INVALID_HANDLE;

const MAX_GIBS = 100;
int gibPool[MAX_GIBS];
int gibPool_pt;

int latestSpawnTime = 0;
int latestGibCount = 0;

public Plugin myinfo = 
{
	name = "Gibbing System",
	author = "RhymeOfRime",
	description = "Gib zombies & players upon death by extra-fatal damage.",
	version = "4.00",
	url = "rhymeofrime.site.nfoservers.com"
};

public void OnPluginStart()
{
	PrintToServer("\n======== [SM GibSys] Starting plugin ========");
	
	// ConVars
	sv_gibsys_num_gibs_rib = CreateConVar("sv_gibsys_num_gibs_rib", "3", "Number of ribs to spawn on death (max gibs will be constrained by MAX_GIBS, check the code)");
	sv_gibsys_maxhealth_ratio = CreateConVar("sv_gibsys_maxhealth_ratio", "0.0", "Gibbing criteria 1: Additional damage (pass 0hp) must exceed this portion of maxhealth. Eg. 0.8 means 80% of maxhealth");
	sv_gibsys_mindamage_threshold = CreateConVar("sv_gibsys_mindamage_threshold", "-800.0", "Gibbing criteria 2: Health must be less than this level (Constant for all character). Eg. -800 means character will gib having health below -800hp");
	sv_gibsys_gib_speed = CreateConVar("sv_gibsys_gib_speed", "100", "Min speed in which gib flies. Eg. 100 means character gibs flies in 100 units/second when health drops just barely meet gibbing criteria, faster if higher damage");
	sv_gibsys_no_particle = CreateConVar("sv_gibsys_no_particle", "0", "Bloodless gib? [0/1]");
	
	// Customization
	sv_gibsys_model_rib = CreateConVar("sv_gibsys_model_rib", "models/gibs/hgibs_rib.mdl", "Model path");
	sv_gibsys_model_skull = CreateConVar("sv_gibsys_model_skull", "models/gibs/hgibs.mdl", "Model path");
	sv_gibsys_model_pelvis = CreateConVar("sv_gibsys_model_pelvis", "models/gibs/hgibs_scapula.mdl", "Model path");
	sv_gibsys_model_spine = CreateConVar("sv_gibsys_model_spine", "models/gibs/hgibs_spine.mdl", "Model path");
	sv_gibsys_particle_splat = CreateConVar("sv_gibsys_particle_splat", "headshot_burst_splat_2", "Model path");
	sv_gibsys_particle_gib = CreateConVar("sv_gibsys_particle_gib", "headshot_blood_splats", "Model path");
	
	// chat command
	RegAdminCmd("sm_gibsys_printGibPoolIndex", Command_debugGibPool, ADMFLAG_ROOT, "(Debug) Print gib pool indices in console");
	RegAdminCmd("sm_gibsys_test", Command_test, ADMFLAG_ROOT, "(Debug) test effect");
	RegConsoleCmd("sm_gibme", Command_gibme, "Gib explode myself (Only when not infected)");

	// Hooks certain events to be referenced later on.
	HookEvent("npc_killed", OnNPCKilled);
	HookEvent("player_death", OnPlayerKilled);
	
	HookEvent("nmrih_reset_map", OnResetMap);
	
	PrintToServer("======== [SM GibSys] Initialization completed ========\n ");
}

public Action:Command_test(client, args)
{
	int clientEntID = client==0?1:client;
	float position[3], angles[3];
	GetClientAbsOrigin(clientEntID, position);
	//GetClientEyeAngles(clientEntID, angles);
	int smoke = PrecacheModel("particle/smokesprites_0009.vmt", true);
	TE_SetupSmoke(position, smoke, 100, 2);
	TE_SendToAll();
	
	//
	
	
	return Plugin_Handled;
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
	char path_pelvis[256];
	GetConVarString(sv_gibsys_model_pelvis, path_pelvis, 256);
	PrecacheModel(path_pelvis);
	
	char path_spine[256];
	GetConVarString(sv_gibsys_model_spine, path_spine, 256);
	PrecacheModel(path_spine);
	
	char path_skull[256];
	GetConVarString(sv_gibsys_model_skull, path_skull, 256);
	PrecacheModel(path_skull);
	
	char path_rib[256];
	GetConVarString(sv_gibsys_model_rib, path_rib, 256);
	PrecacheModel(path_rib);

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
	
	// Emit blood

	// hide ragdoll
	if(isNPC)
	{
		SetEntityRenderMode(entID, 10);
	}
	else
	{
		int ragdollID = GetEntPropEnt(entID, Prop_Send, "m_hRagdoll");
		if(ragdollID > 0 && IsValidEdict(ragdollID))
		{
			AcceptEntityInput(ragdollID, "Kill");
		}
	}
	

	
	// 
	float vecMax[3], vecMin[3];
	GetEntPropVector(entID, Prop_Data, "m_vecMaxs", vecMax);
	GetEntPropVector(entID, Prop_Data, "m_vecMins", vecMin);
	float widthX = vecMax[0] - vecMin[0];
	float widthY = vecMax[1] - vecMin[1];
	float height = vecMax[2] - vecMin[2];
	
	// get zombie position
	float zombiePosition[3];
	GetEntPropVector(entID, Prop_Send, "m_vecOrigin", zombiePosition);
	
	// spawn pelvis
	float pelvisPosition[3];
	pelvisPosition[0] = zombiePosition[0];
	pelvisPosition[1] = zombiePosition[1];
	pelvisPosition[2] = zombiePosition[2] + height*0.32;
	char path_pelvis[256];
	GetConVarString(sv_gibsys_model_pelvis, path_pelvis, 256);
	PrecacheModel(path_pelvis);
	spawnGib(path_pelvis, 2, pelvisPosition, widthX/2.0, widthY/2.0, 0.0, gibSpeed);
	
	// spawn spine
	float spinePosition[3];
	spinePosition[0] = zombiePosition[0];
	spinePosition[1] = zombiePosition[1];
	spinePosition[2] = zombiePosition[2] + height*0.53;
	//zombiePosition[2] += 15;
	char path_spine[256];
	GetConVarString(sv_gibsys_model_spine, path_spine, 256);
	PrecacheModel(path_spine);
	spawnGib(path_spine, 1, spinePosition, widthX/2.0, widthY/2.0, 0.0, gibSpeed);
	
	// spawn main blood particle
	// particle name: nmrih_suicide_grenade
	char particle_splat[256];
	GetConVarString(sv_gibsys_particle_splat, particle_splat, 256);
	spawnParticle(particle_splat, NULL_VECTOR, spinePosition, 10.0);
	
	// spawn ribs
	float ribPosition[3];
	ribPosition[0] = zombiePosition[0];
	ribPosition[1] = zombiePosition[1];
	ribPosition[2] = zombiePosition[2] + height*0.62;
	//zombiePosition[2] += 15;
	char path_rib[256];
	GetConVarString(sv_gibsys_model_rib, path_rib, 256);
	PrecacheModel(path_rib);
	spawnGib(path_rib, GetConVarInt(sv_gibsys_num_gibs_rib), ribPosition, widthX/2.0, widthY/2.0, height/2.0, gibSpeed);

	// spawn head
	float headPosition[3];
	headPosition[0] = zombiePosition[0];
	headPosition[1] = zombiePosition[1];
	headPosition[2] = zombiePosition[2] + height*0.84;
	//zombiePosition[2] += 8;
	char path_skull[256];
	GetConVarString(sv_gibsys_model_skull, path_skull, 256);
	PrecacheModel(path_skull);
	spawnGib(path_skull, 1, headPosition, widthX/2.0, widthY/2.0, 0.0, gibSpeed);
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
	if(GetConVarInt(sv_gibsys_no_particle) == 1)
	{
		return;
	}
	
	new particle = CreateEntityByName("info_particle_system");
	
	// set particle effect
	DispatchKeyValue(particle, "effect_name", particleName);
	
	if(DispatchSpawn(particle))
	{	
		ActivateEntity(particle);
		TeleportEntity(particle, position, angles, NULL_VECTOR);
		AcceptEntityInput(particle, "start");
		CreateTimer(duration, Timer_RemoveParticle, EntIndexToEntRef(particle)); // Thanks Dysphie
	}
}
public void spawnGib(const String:model[], int number_gibs, const Float:spawnCenterPosition[3], float varX, float varY, float varZ, float gibSpeed)
{	
	if(!FileExists(model, true))
	{
		return;
	}
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
		int gib_entIdx = CreateEntityByName("prop_physics_override");

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
				DispatchKeyValue(gib_entIdx,"classname", GIB_CLASS_NAME);
				
				// Only collide with world geometry
				SetEntProp(gib_entIdx, Prop_Send, "m_CollisionGroup", 1);
			
				// Set position & velocity & attach trail
				float pos[3], vel[3], ang[3], angVel[3];
				pos[0] = spawnCenterPosition[0] + GetRandomFloat(varX / 2.0, varX / 2.0);
				pos[1] = spawnCenterPosition[1] + GetRandomFloat(varY / 2.0, varY / 2.0);
				pos[2] = spawnCenterPosition[2] + GetRandomFloat(varZ / 2.0, varZ / 2.0);

				vel[0] = GetRandomFloat(-gibSpeed, gibSpeed);
				vel[1] = GetRandomFloat(-gibSpeed, gibSpeed);
				vel[2] = GetRandomFloat(-gibSpeed, gibSpeed * 2.0);
				
				ang[0] = GetRandomFloat(-180.0, 180.0);
				ang[1] = GetRandomFloat(-180.0, 180.0);
				ang[2] = GetRandomFloat(-180.0, 180.0);
				
				//float angVelSpeed = gibSpeed * 18000.0/1000.0;
				//angVel[0] = GetRandomFloat(-angVelSpeed, angVelSpeed);
				//angVel[1] = GetRandomFloat(-angVelSpeed, angVelSpeed);
				//angVel[2] = GetRandomFloat(-angVelSpeed, angVelSpeed);
				
				TeleportEntity(gib_entIdx, pos, ang, vel);
				//SetEntPropVector(gib_entIdx, Prop_Data, "m_vecAngVelocity", angVel);
				if(GetConVarInt(sv_gibsys_no_particle) != 1)
				{
					char particle_gib[256];
					GetConVarString(sv_gibsys_particle_gib, particle_gib, 256);
					int particle = AttachParticle(gib_entIdx, particle_gib);
					CreateTimer(10.0, Timer_RemoveParticle, EntIndexToEntRef(particle));
				}
				
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
	
					if(IsValidEntity(oldGibID) && strcmp(oldGibClassName, GIB_CLASS_NAME) == 0)
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

public Action:Timer_RemoveParticle(Handle:Timer, any:entref)
{
	// Thanks Dysphie
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

int AttachParticle(ent, String:particleType[])
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
		
		return particle;
	}
	
	return -1;
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