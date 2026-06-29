/*======================================================================================
	Plugin Info:

*	Name	:	[L4D(2)] Tank Jump Earthquake
*	Author	:	Moan
*	Descrp	:	Allows the Tank Jump And KnockBack Player.
*	Link	:	https://forums.alliedmods.net/showthread.php?p=2829549#post2829549
*	Plugins	:	https://sourcemod.net/plugins.php?title=Earthquake&search=1&sortby=author&order=0

========================================================================================
	Change Log:

	- See forum thread: https://forums.alliedmods.net/showthread.php?p=2829549#post2829549

========================================================================================
	Thanks:

	This plugin was made using source code from the following plugins.
	If I have used your code and not credited you, please let me know.

*	idea: Moon
*	Lily-Kaya helped, Kaz (for effect)
*	Thank Silvers for outline
*	[L4D & L4D2] Left 4 DHooks Direct (Silvers): I learned from his tutorial and my friend's. (https://forums.alliedmods.net/showthread.php?t=321696)
*	l4d_meteor_hunter (Spirit, Harry) : Original source code (https://github.com/fbef0102/L4D1_2-Plugins/blob/master/l4d_meteor_hunter/scripting/l4d_meteor_hunter.sp)
*	[L4D2] LAST BOSS (ztar) : Original source code (https://forums.alliedmods.net/showthread.php?t=129013)

========================================================================================

*	I still have many shortcomings, I hope forum will take care of me in the future.
*	And finally, thanks to the forum. I learned a lot from forum.

===================================================================================================*/

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <left4dhooks>

// === Constants and Definitions ===

#define SOUND_EXPLODE    "animation/APC_Idle_Loop.wav"
#define SOUND_QUAKE      "player/tank/hit/pound_victim_2.wav"

#define SOUND_GROWL_1 "player/tank/voice/growl/tank_climb_01.wav"
#define SOUND_GROWL_2 "player/tank/voice/growl/tank_climb_02.wav"
#define SOUND_GROWL_3 "player/tank/voice/growl/tank_climb_03.wav"
#define SOUND_GROWL_4 "player/tank/voice/growl/tank_climb_04.wav"
#define SOUND_GROWL_5 "player/tank/voice/growl/tank_climb_05.wav"

#define MODEL_CONCRETE_CHUNK "models/props_debris/concrete_chunk01a.mdl"

#define ENTITY_GASCAN    "models/props_junk/gascan001a.mdl"
#define ENTITY_PROPANE   "models/props_junk/propanecanister001a.mdl"
#define SOUND_BOMBARD    "animation/van_inside_hit_wall.wav"

#define EXPLOSION_PARTICLE1 "gas_explosion_initialburst_smoke"
#define EXPLOSION_PARTICLE2 "gas_explosion_chunks_02"
#define EXPLOSION_PARTICLE3 "aircraft_destroy_fastFireTrail"
#define SPRITE_LASERBEAM "sprites/laserbeam.vmt"
#define SPRITE_GLOW "sprites/glow01.vmt"

#define TEAM_INFECTED    3

// === ConVars (Configurable Variables) ===

ConVar g_tank_jumpdamage, g_tank_jumpheight, g_tank_jumpinterval, g_timescale_value, g_timescale_acceleration, g_timescale_radius, g_timescale_duration, g_tank_rabies_upforce, g_tank_rabies_flingforce;

// === Globals and Handles ===

bool L4D2Version, bLeft4DeadTwo;
Handle g_TankTimers[MAXPLAYERS + 1];
int g_iVelocity = -1, g_iBossBeamSprite = -1, g_iBossHaloSprite = -1;
float L4D_Z_MULT = 1.6;
float m_tank_jumpdamage, m_tank_rabies_upforce, m_tank_rabies_flingforce, m_tank_jumpheight, m_tank_jumpinterval, m_timescale_duration, m_timescale_value, m_timescale_acceleration, m_timescale_radius;

// === Plugin Information ===

public Plugin myinfo = 
{
	name = "[L4D(2)] Tank Jump Earthquake", 
	author = "Moon", 
	description = "Allows the Tank Jump And KnockBack Player.", 
	version = "1.2.5", 
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();
	if (test == Engine_Left4Dead2) {
		bLeft4DeadTwo = true;
	} else if (test != Engine_Left4Dead) {
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 1 & 2.");
		return APLRes_SilentFailure;
	}
	L4D2Version = (test == Engine_Left4Dead2);
	return APLRes_Success;
}

// === Initialization Functions ===

public void OnPluginStart()
{
	g_tank_rabies_upforce = CreateConVar("g_tank_rabies_upforce", "250.0", "Upward force of Tank's knockback");
	g_tank_rabies_flingforce = CreateConVar("g_tank_rabies_flingforce", "600.0", "Fling force away from Tank in knockback");
	
	g_timescale_value = CreateConVar("g_timescale_value", "1.0", "The desired slow-motion timescale (0.1 to 1.0)");
	g_timescale_acceleration = CreateConVar("g_timescale_acceleration", "1.0", "Acceleration for the slow-motion effect");
	g_timescale_duration = CreateConVar("g_timescale_duration", "3.0", "Duration of the slow-motion effect in seconds");
	g_timescale_radius = CreateConVar("g_timescale_radius", "1000.0", "Radius of the slow-motion effect in units");
	
	g_tank_jumpheight = CreateConVar("g_tank_jumpheight", "900.0", "Jump height of the tank");
	g_tank_jumpinterval = CreateConVar("g_tank_jumpinterval", "35.0", "Interval between the tank's jumps");
	g_tank_jumpdamage = CreateConVar("g_tank_jumpdamage", "20.0", "Dame from tank jump for player (should be less than 100)");
	
	// Hook events
	HookEvent("tank_spawn", Event_TankSpawn);
	HookEvent("player_death", Event_Player_Death);
	HookEvent("round_end", Event_RoundEnd);
	
	// Retrieve velocity offset for teleporting entities
	if ((g_iVelocity = FindSendPropInfo("CBasePlayer", "m_vecVelocity[0]")) == -1)
		LogError("Could not find offset for CBasePlayer::m_vecVelocity[0]");
	
	
	// Execute configuration file and set ConVar change hooks
	AutoExecConfig(true, "l4d2_tank_jump_earthquake");
	
	g_timescale_value.AddChangeHook(ConVarChanged_Cvars);
	g_timescale_acceleration.AddChangeHook(ConVarChanged_Cvars);
	g_tank_rabies_upforce.AddChangeHook(ConVarChanged_Cvars);
	g_tank_rabies_flingforce.AddChangeHook(ConVarChanged_Cvars);
	g_timescale_duration.AddChangeHook(ConVarChanged_Cvars);
	g_timescale_radius.AddChangeHook(ConVarChanged_Cvars);
	g_tank_jumpheight.AddChangeHook(ConVarChanged_Cvars);
	g_tank_jumpinterval.AddChangeHook(ConVarChanged_Cvars);
	g_tank_jumpdamage.AddChangeHook(ConVarChanged_Cvars);
}

// === Utility Functions ===

public void OnConfigsExecuted()
{
	IsAllowed();
}

void ConVarChanged_Cvars(Handle convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

void IsAllowed()
{
	GetCvars();
}

// Retrieves and updates ConVar values into variables

void GetCvars()
{
	m_timescale_value = g_timescale_value.FloatValue;
	m_timescale_acceleration = g_timescale_acceleration.FloatValue;
	m_tank_rabies_upforce = g_tank_rabies_upforce.FloatValue;
	m_tank_rabies_flingforce = g_tank_rabies_flingforce.FloatValue;
	m_timescale_duration = g_timescale_duration.FloatValue;
	m_timescale_radius = g_timescale_radius.FloatValue;
	m_tank_jumpheight = g_tank_jumpheight.FloatValue;
	m_tank_jumpinterval = g_tank_jumpinterval.FloatValue;
	m_tank_jumpdamage = g_tank_jumpdamage.FloatValue;
}

// === Event Handling ===

void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	OnMapEnd();
}

public void OnMapEnd()
{
	ClearAllTankTimers();
}

public void OnMapStart()
{
	PrecacheParticle(EXPLOSION_PARTICLE1);
	PrecacheParticle(EXPLOSION_PARTICLE2);
	PrecacheParticle(EXPLOSION_PARTICLE3);
	
	PrecacheModel(MODEL_CONCRETE_CHUNK, true);
	g_iBossBeamSprite = PrecacheModel(SPRITE_LASERBEAM, true);
	g_iBossHaloSprite = PrecacheModel(SPRITE_GLOW, true);
	
	PrecacheSound(SOUND_BOMBARD, true);
	PrecacheSound(SOUND_EXPLODE, true);
	PrecacheSound(SOUND_GROWL_1, true);
	PrecacheSound(SOUND_GROWL_2, true);
	PrecacheSound(SOUND_GROWL_3, true);
	PrecacheSound(SOUND_GROWL_4, true);
	PrecacheSound(SOUND_GROWL_5, true);
}

// Tank spawn event

public Action Event_TankSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int user = GetEventInt(event, "userid");
	int client = GetClientOfUserId(user);
	if (IsValidEntity(client) && IsClientInGame(client) && IsTank(client))
	{
		if (g_TankTimers[client] != INVALID_HANDLE)
		{
			CloseHandle(g_TankTimers[client]);
		}
		
		g_TankTimers[client] = CreateTimer(m_tank_jumpinterval, JumpingTimer, user, TIMER_REPEAT);
	}
	return Plugin_Continue;
}

// Player death event

public Action Event_Player_Death(Event event, const char[] name, bool dontBroadcast)
{
	int user = GetEventInt(event, "userid");
	int client = GetClientOfUserId(user);
	if (client <= 0 || !IsValidClient(client))
		return Plugin_Continue;
	
	if (IsTank(client))
	{
		delete g_TankTimers[client];
	}
	return Plugin_Continue;
}

// === Core Tank Ability Functions ===

// Function to make Tank jump

public Action JumpingTimer(Handle timer, int user)
{
	int client = GetClientOfUserId(user);
	
	// Validate the client is still in the game
	if (client <= 0 || !IsValidClient(client) || !IsClientInGame(client))
	{
		return Plugin_Stop;
	}
	
	// Add jump velocity and effect to the client
	AddVelocity(client, m_tank_jumpheight);
	SpawnEffect(client, EXPLOSION_PARTICLE3);
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i) && GetClientTeam(i) == 2)
		{
			// Emit random growl sound to nearby clients
			switch (GetRandomInt(1, 5))
			{
				case 1:EmitSoundToClient(i, SOUND_GROWL_1);
				case 2:EmitSoundToClient(i, SOUND_GROWL_2);
				case 3:EmitSoundToClient(i, SOUND_GROWL_3);
				case 4:EmitSoundToClient(i, SOUND_GROWL_4);
				case 5:EmitSoundToClient(i, SOUND_GROWL_5);
			}
		}
	}
	
	// Create repeated check timer to monitor landing
	CreateTimer(0.1, BotLandCheckTimer, user, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	
	return Plugin_Continue;
}

// Adds upward velocity to make Tank jump

public void AddVelocity(int client, float zSpeed)
{
	if (g_iVelocity == -1)return;
	
	float vecVelocity[3];
	GetEntDataVector(client, g_iVelocity, vecVelocity);
	vecVelocity[2] += zSpeed;
	
	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vecVelocity);
}

// Checks for player landing and applies slow-motion, damage effects and knock back players

public Action BotLandCheckTimer(Handle timer, int user)
{
	int client = GetClientOfUserId(user);
	float tankOrigin[3];
	float timescaleRadiusSq = m_timescale_radius * m_timescale_radius;
	float outerDamage = m_tank_jumpdamage;
	
	if (client <= 0 || !IsValidClient(client) || !IsClientInGame(client))
	{
		return Plugin_Stop;
	}
	
	if (IsClientOnGround(client))
	{
		GetClientAbsOrigin(client, tankOrigin);
		
		//CreateWaveEffect(tankOrigin);
		CreateMeteorRocks(tankOrigin, client);
		CreateSlowMotion(tankOrigin);
		
		// Call ApplyAreaDamage
		ApplyAreaDamage(tankOrigin, client, timescaleRadiusSq, outerDamage);
		
		return Plugin_Stop;
	}
	
	return Plugin_Continue;
}

// Fling a specific player away from the Tank

void ApplyAreaDamage(float tankOrigin[3], int attacker, float radiusSq, float damage)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || GetClientTeam(i) != 2) // Check victims in the Survivor team
			continue;
		
		float victimOrigin[3];
		GetClientAbsOrigin(i, victimOrigin);
		
		float dx = tankOrigin[0] - victimOrigin[0];
		float dy = tankOrigin[1] - victimOrigin[1];
		float dz = tankOrigin[2] - victimOrigin[2];
		float distanceSq = dx * dx + dy * dy + dz * dz;
		
		tankOrigin[2] += 20.0; // Push the wave up a bit to be clear
		TE_SetupBeamRingPoint(tankOrigin, 10.0, 2000.0, g_iBossBeamSprite, g_iBossHaloSprite, 0, 50, 1.0, 88.0, 3.0, { 255, 255, 255, 50 }, 1000, 0);
		TE_SendToAll();
		
		if (distanceSq <= radiusSq) // Only effective if within range
		{
			// Deal damage
			SDKHooks_TakeDamage(i, attacker, attacker, damage, DMG_CLUB);
			
			// Shake screen
			ScreenShake(i, 60.0);
			
			// Play sound
			EmitSoundToClient(i, SOUND_QUAKE);
			
			// Knockback
			float flingDirection[3];
			MakeVectorFromPoints(tankOrigin, victimOrigin, flingDirection);
			NormalizeVector(flingDirection, flingDirection);
			ScaleVector(flingDirection, m_tank_rabies_flingforce);
			flingDirection[2] += m_tank_rabies_upforce;
			
			if (L4D2Version == false)
			{
				flingDirection[2] *= L4D_Z_MULT;
				TeleportEntity(i, NULL_VECTOR, NULL_VECTOR, flingDirection);
			}
			else
			{
				L4D2_CTerrorPlayer_Fling(i, attacker, flingDirection);
			}
		}
	}
}

// === Rock and Particle Effect Functions ===

// Creates a single rock entity at the specified position

void CreateRock(float Tpos[3])
{
	// Limit entities to avoid overload
	int rock = -1;
	rock = CreateEntityByName("prop_dynamic");
	if (rock == -1)
		return;
	
	// Set up models for rock and spawn
	SetEntityModel(rock, MODEL_CONCRETE_CHUNK);
	DispatchSpawn(rock);
	
	float ang[3];
	ang[0] = GetRandomFloat(0.0, 360.0);
	ang[1] = GetRandomFloat(0.0, 360.0);
	ang[2] = GetRandomFloat(0.0, 360.0);
	
	TeleportEntity(rock, Tpos, ang, NULL_VECTOR);
	
	// Delete rock afer 5s
	CreateTimer(5.0, TimerDeleteRock, EntIndexToEntRef(rock), TIMER_FLAG_NO_MAPCHANGE);
}

// === Area Effect and Slow-Motion Functions ===

// Creates a series of meteor rocks for visual impact around the Tank's position

public void CreateMeteorRocks(float tankOrigin[3], int client)
{
	for (int i = 0; i < 2; i++)
	{
		float randomOffset[3];
		
		randomOffset[0] = tankOrigin[0] + GetRandomFloat(-100.0, 100.0);
		randomOffset[1] = tankOrigin[1] + GetRandomFloat(-100.0, 100.0);
		randomOffset[2] = tankOrigin[2];
		
		CreateRock(randomOffset);
		CreateParticles(tankOrigin);
		EmitSoundToAll(SOUND_EXPLODE, client);
	}
}

// Applies slow-motion effect in a radius around the tank

public void CreateSlowMotion(float origin[3])
{
	int iTimescale = CreateEntityByName("func_timescale");
	
	if (iTimescale != -1)
	{
		//float radius = m_timescale_radius;
		DispatchKeyValueFloat(iTimescale, "desiredTimescale", m_timescale_value);
		DispatchKeyValueFloat(iTimescale, "acceleration", m_timescale_acceleration);
		DispatchKeyValueFloat(iTimescale, "minBlendRate", 1.0);
		DispatchKeyValueFloat(iTimescale, "blendDeltaMultiplier", 2.0);
		DispatchKeyValueVector(iTimescale, "origin", origin);
		//DispatchKeyValueFloat(iTimescale, "radius", radius);
		DispatchSpawn(iTimescale);
		AcceptEntityInput(iTimescale, "Start");
		
		CreateTimer(m_timescale_duration, TimerResetTimescale, EntIndexToEntRef(iTimescale), TIMER_FLAG_NO_MAPCHANGE);
	}
}

// Spawns explosion and debris particle effects at the specified position

void CreateParticles(float pos[3])
{
	// First explosion particle
	int exParticle = CreateEntityByName("info_particle_system");
	if (IsValidEntity(exParticle))
	{
		DispatchKeyValue(exParticle, "effect_name", EXPLOSION_PARTICLE1);
		DispatchSpawn(exParticle);
		ActivateEntity(exParticle);
		TeleportEntity(exParticle, pos, NULL_VECTOR, NULL_VECTOR);
		AcceptEntityInput(exParticle, "Start");
		
		// Delete particle after 3s
		CreateTimer(3.0, TimerDeleteRock, EntIndexToEntRef(exParticle), TIMER_FLAG_NO_MAPCHANGE);
	}
	
	// Second explosion particle
	int exParticle2 = CreateEntityByName("info_particle_system");
	if (IsValidEntity(exParticle2))
	{
		DispatchKeyValue(exParticle2, "effect_name", EXPLOSION_PARTICLE2);
		DispatchSpawn(exParticle2);
		ActivateEntity(exParticle2);
		TeleportEntity(exParticle2, pos, NULL_VECTOR, NULL_VECTOR);
		AcceptEntityInput(exParticle2, "Start");
		
		CreateTimer(3.0, TimerDeleteRock, EntIndexToEntRef(exParticle2), TIMER_FLAG_NO_MAPCHANGE);
	}
	
	// Third explosion particle
	int exParticle3 = CreateEntityByName("info_particle_system");
	if (IsValidEntity(exParticle3))
	{
		DispatchKeyValue(exParticle3, "effect_name", EXPLOSION_PARTICLE3);
		DispatchSpawn(exParticle3);
		ActivateEntity(exParticle3);
		TeleportEntity(exParticle3, pos, NULL_VECTOR, NULL_VECTOR);
		AcceptEntityInput(exParticle3, "Start");
		
		CreateTimer(3.0, TimerDeleteRock, EntIndexToEntRef(exParticle3), TIMER_FLAG_NO_MAPCHANGE);
	}
}

// Create PrecacheParticle

void PrecacheParticle(const char[] sEffectName)
{
	static int table = INVALID_STRING_TABLE;
	
	if (table == INVALID_STRING_TABLE)
	{
		table = FindStringTable("ParticleEffectNames");
	}
	
	int index = FindStringIndex(table, sEffectName);
	if (index == INVALID_STRING_INDEX)
	{
		bool save = LockStringTables(false);
		AddToStringTable(table, sEffectName);
		LockStringTables(save);
		index = FindStringIndex(table, sEffectName);
	}
}

// Skill and Shake

public void ScreenShake(int target, float intensity)
{
	Handle msg;
	msg = StartMessageOne("Shake", target);
	
	BfWriteByte(msg, 0);
	BfWriteFloat(msg, intensity);
	BfWriteFloat(msg, 10.0);
	BfWriteFloat(msg, 3.0);
	EndMessage();
}

// Spawns a visual particle effect at the client's location

void SpawnEffect(int client, char[] sParticleName)
{
	float pos[3];
	GetClientEyePosition(client, pos);
	int iEntity = CreateEntityByName("info_particle_system", -1);
	if (iEntity != -1)
	{
		DispatchKeyValue(iEntity, "effect_name", sParticleName);
		DispatchKeyValueVector(iEntity, "origin", pos);
		DispatchSpawn(iEntity);
		
		SetVariantString("!activator");
		AcceptEntityInput(iEntity, "SetParent", client);
		
		ActivateEntity(iEntity);
		AcceptEntityInput(iEntity, "Start");
		
		SetVariantString("OnUser1 !self:kill::5.0:1");
		AcceptEntityInput(iEntity, "AddOutput");
		AcceptEntityInput(iEntity, "FireUser1");
	}
}

// === Cleanup and Utility ===

// Resets the slow-motion effect after duration

public Action TimerResetTimescale(Handle timer, int entRef)
{
	int iTimescale = EntRefToEntIndex(entRef);
	if (iTimescale != INVALID_ENT_REFERENCE && IsValidEntity(iTimescale))
	{
		DispatchKeyValueFloat(iTimescale, "desiredTimescale", 1.0);
		DispatchKeyValueFloat(iTimescale, "acceleration", 2.0);
		AcceptEntityInput(iTimescale, "Start");
		
		AcceptEntityInput(iTimescale, "Stop");
	}
	return Plugin_Continue;
}

// Deletes a rock entity

public Action TimerDeleteRock(Handle hTimer, int ref)
{
	if (ref && EntRefToEntIndex(ref) != INVALID_ENT_REFERENCE)
	{
		AcceptEntityInput(ref, "kill");
	}
	
	return Plugin_Continue;
}

// Deletes particle effects after a delay

public Action DeleteParticles(Handle timer, int particle)
{
	if (IsValidEntity(particle))
	{
		char classname[64];
		GetEdictClassname(particle, classname, sizeof(classname));
		if (StrEqual(classname, "info_particle_system", false))
			RemoveEdict(particle);
	}
	return Plugin_Handled;
}

// Safely clears all Tank timers to prevent invalid handle errors

public void ClearAllTankTimers()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidHandle(g_TankTimers[i]))
		{
			CloseHandle(g_TankTimers[i]);
			g_TankTimers[i] = INVALID_HANDLE;
		}
	}
}

// Checks if the given client index is valid

stock bool IsValidClient(int client)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client);
}

// Checks if a client is on the ground

stock bool IsClientOnGround(int client)
{
	return IsValidClient(client) && GetEntPropEnt(client, Prop_Send, "m_hGroundEntity") != -1;
}

/**
 * @note Validates if the current client is valid.
 *
 * @param client		The client index.
 * @return              False if the client is not the Tank, true otherwise.
 */
stock bool IsTank(int client)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 3)
		if (GetEntProp(client, Prop_Send, "m_zombieClass") == (bLeft4DeadTwo ? 8 : 5))
		return true;
	
	return false;
}