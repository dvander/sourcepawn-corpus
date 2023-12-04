#pragma semicolon 1
#pragma newdecls required
#define PLUGIN_VERSION "1.0"

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>

//Sounds
#define NUKE_SOUND "animation/overpass_jets.wav"
#define EXPLOSION_SOUND "ambient/explosions/explode_1.wav"
#define EXPLOSION_DEBRIS "animation/plantation_exlposion.wav"
#define FIRE_PARTICLE "gas_explosion_ground_fire"
#define EXPLOSION_PARTICLE "FluidExplosion_fps"

//Fade Effect
#define FFADE_IN            0x0001
#define FFADE_OUT           0x0002
#define FFADE_MODULATE      0x0004
#define FFADE_STAYOUT       0x0008
#define FFADE_PURGE         0x0010

//Explosion Mod
Handle 	g_hExplosionTimer;
Handle 	g_hStrike;
float 	g_fEnd;

//Timer
Handle g_hSpawningTimer;

//Corruption Mods
bool g_bRiotSpawning;
bool g_bCedaSpawning;
bool g_bClownSpawning;
bool g_bMudSpawning;
bool g_bJimmySpawning;
bool g_bWitchSpawning;
bool g_bTankSpawning;
bool g_bNukeMod;

public Plugin myinfo =
{
	name = "L4D2 Corruption",
	author = "alasfourom",
	description = "Corruption Mod",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=339644"
};

public void OnPluginStart()
{
	HookEvent("round_end", Event_RoundEnd, EventHookMode_PostNoCopy);
	HookEvent("player_left_start_area", Event_LeftStartArea, EventHookMode_PostNoCopy);
	HookEvent("player_entered_checkpoint", Event_EnteredCheckPoint);
}

/* =============================================================================================================== *
 *														OnMapStart			   									   *
 *================================================================================================================ */

public void OnMapStart()
{
	PrecacheModels();
	GetRandomCorruptiveMod();
}

/* =============================================================================================================== *
 *													PrecacheCommonInfected										   *
 *================================================================================================================ */

void PrecacheModels()
{
	PrecacheSound(NUKE_SOUND);
	PrecacheSound(EXPLOSION_SOUND);
	PrecacheSound(EXPLOSION_DEBRIS);
	
	PrecacheParticle("gas_explosion_ground_fire");
	PrecacheParticle("FluidExplosion_fps");

	delete g_hExplosionTimer;
	delete g_hStrike;
	
	PrecacheModel("models/infected/common_male_riot.mdl", true);
	g_bRiotSpawning = false;
	
	PrecacheModel("models/infected/common_male_ceda.mdl", true);
	g_bCedaSpawning = false;
	
	PrecacheModel("models/infected/common_male_clown.mdl", true);
	g_bClownSpawning = false;
	
	PrecacheModel("models/infected/common_male_mud.mdl", true);
	g_bMudSpawning = false;
	
	PrecacheModel("models/infected/common_male_jimmy.mdl", true);
	g_bJimmySpawning = false;
	
	g_bWitchSpawning = false;
	g_bTankSpawning = false;
	g_bNukeMod = false;
}

/* =============================================================================================================== *
 *															Events												   *
 *================================================================================================================ */

void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	if (g_bWitchSpawning || g_bTankSpawning) delete g_hSpawningTimer;
}

void Event_LeftStartArea(Event event, const char[] name, bool dontBroadcast)
{
	if(g_bWitchSpawning)
	{
		PrintToChatAll("\x04[Corruption] \x01Every 30 seconds, a witch will be spawned");
		g_hSpawningTimer = CreateTimer(30.0, Timer_WitchSpawn, _, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);  
	}
	else if(g_bTankSpawning)
	{
		PrintToChatAll("\x04[Corruption] \x01Tank run mod activated");
		g_hSpawningTimer = CreateTimer(60.0, Timer_TankSpawn, _, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);  
	}
	else if (g_bNukeMod)
	{
		g_fEnd = GetEngineTime() + 300.0;
		g_hExplosionTimer = CreateTimer(300.0 - 120.0, Timer_StartCountDown);
		PrintToChatAll("\x04[Corruption] \x01Nuke Countdown Started: \x035 Minutes");
	}
	else if(g_bRiotSpawning) PrintToChatAll("\x04[Corruption] \x01Riot Mod Activated");
	else if(g_bCedaSpawning) PrintToChatAll("\x04[Corruption] \x01Ceda Mod Activated");
	else if(g_bClownSpawning) PrintToChatAll("\x04[Corruption] \x01Clown Mod Activated");
	else if(g_bMudSpawning) PrintToChatAll("\x04[Corruption] \x01Mud Mod Activated");
	else if(g_bJimmySpawning) PrintToChatAll("\x04[Corruption] \x01Jimmy Mod Activated");
}

public void Event_EnteredCheckPoint(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (!client || !IsClientInGame(client) || GetClientTeam(client) != 2 || !IsPlayerAlive(client) || !g_bNukeMod) return;

	delete g_hExplosionTimer;
	delete g_hStrike;
}

/* =============================================================================================================== *
 *													PrecacheCommonInfected										   *
 *================================================================================================================ */

void GetRandomCorruptiveMod()
{
	switch (GetRandomInt(1,12))
	{
		case 1: g_bRiotSpawning = true;
		case 2: g_bCedaSpawning = true;
		case 3: g_bClownSpawning = true;
		case 4: g_bMudSpawning = true;
		case 5: g_bJimmySpawning = true;
		case 6: g_bWitchSpawning = true;
		case 7: g_bTankSpawning = true;
		case 8: g_bNukeMod = true;
	}
}

Action Timer_WitchSpawn(Handle timer)
{
	if(g_bWitchSpawning)
	{
		WitchSpawn();
		return Plugin_Continue;
	}
	return Plugin_Stop;
}

Action Timer_TankSpawn(Handle timer)
{
	if(g_bTankSpawning)
	{
		TankSpawn();
		return Plugin_Continue;
	}
	return Plugin_Stop;
}

int FindRandomPlayer()
{
	for (int client = 1; client <= MaxClients; client++)
		if (IsClientInGame(client)) return client;
	
	return 0;
}

void WitchSpawn()
{
	int CmdFlags = GetCommandFlags("z_spawn_old");
	SetCommandFlags("z_spawn_old", CmdFlags & ~FCVAR_CHEAT);
	FakeClientCommand(FindRandomPlayer(), "z_spawn_old witch auto");
	SetCommandFlags("z_spawn_old", CmdFlags);
}

void TankSpawn()
{
	int CmdFlags = GetCommandFlags("z_spawn_old");
	SetCommandFlags("z_spawn_old", CmdFlags & ~FCVAR_CHEAT);
	FakeClientCommand(FindRandomPlayer(), "z_spawn_old tank auto");
	SetCommandFlags("z_spawn_old", CmdFlags);
}

/* =============================================================================================================== *
 *												Method To Spawn Hordes			   								   *
 *================================================================================================================ */

public void OnEntityCreated(int entity, const char[] classname)
{
	if (!StrEqual(classname, "infected", false)) return;
	
	if(g_bRiotSpawning) SetEntityModel(entity, "models/infected/common_male_riot.mdl");
	else if(g_bCedaSpawning) SetEntityModel(entity, "models/infected/common_male_ceda.mdl");
	else if(g_bClownSpawning) SetEntityModel(entity, "models/infected/common_male_clown.mdl");
	else if(g_bMudSpawning) SetEntityModel(entity, "models/infected/common_male_mud.mdl");
	else if(g_bJimmySpawning) SetEntityModel(entity, "models/infected/common_male_jimmy.mdl");
}

/* =============================================================================================================== *
 *													From My Nuke Plugin			   								   *
 *================================================================================================================ */

public Action Timer_StartCountDown(Handle timer)
{
	g_hExplosionTimer = CreateTimer(1.0, Timer_CountDown, _, TIMER_REPEAT);
	TriggerTimer(g_hExplosionTimer);
	return Plugin_Stop;
}

public Action Timer_CountDown(Handle timer, int client)
{
	float time = g_fEnd - GetEngineTime();
	if(time >= 0.0)
	{
		PrintHintTextToAll("Nuke Timer: %d", RoundToNearest(time));
		return Plugin_Continue;
	}

	CreateTimer(0.1, Timer_FadePlayers, _, TIMER_FLAG_NO_MAPCHANGE);
	
	EmitSoundToAll(NUKE_SOUND);
	CreateTimer(2.5, Timer_Incap, _, TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(6.0, Timer_SlayPlayers, _, TIMER_FLAG_NO_MAPCHANGE);

	g_hStrike = CreateTimer(2.0, Timer_Strike, _, TIMER_REPEAT);
	CreateTimer(6.0, Timer_StrikeTimeout, _, TIMER_FLAG_NO_MAPCHANGE);
	
	g_hExplosionTimer = null;
	return Plugin_Stop;
}

public Action Timer_FadePlayers(Handle timer)
{
	CreateTimer(0.1, Timer_FadeOut, _, TIMER_FLAG_NO_MAPCHANGE);
	return Plugin_Stop;
}

public Action Timer_FadeOut(Handle timer)
{
	CreateFade(FFADE_OUT);
	CreateTimer(2.5, Timer_FadeIn, _, TIMER_FLAG_NO_MAPCHANGE);
	return Plugin_Stop;
}

public Action Timer_FadeIn(Handle timer)
{
	CreateFade(FFADE_IN);
	return Plugin_Stop;
}

void CreateFade(int type)
{
	Handle hFadeClient = StartMessageAll("Fade");
	BfWriteShort(hFadeClient, 800);
	BfWriteShort(hFadeClient, 800);
	BfWriteShort(hFadeClient, (FFADE_PURGE|type|FFADE_STAYOUT));
	BfWriteByte(hFadeClient, 255);
	BfWriteByte(hFadeClient, 255);
	BfWriteByte(hFadeClient, 255);
	BfWriteByte(hFadeClient, 255);
	EndMessage();
}

public Action Timer_Incap(Handle timer)
{
	for(int i = 1; i <= MaxClients; i++) if(IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
	{
		SetEntityHealth(i, 1);
		SDKHooks_TakeDamage(i, i, i, 100.0);
	}
	return Plugin_Stop;
}

public Action Timer_SlayPlayers(Handle timer)
{
	for(int i = 1; i <= MaxClients; i++) if(IsClientInGame(i) && IsPlayerAlive(i)) ForcePlayerSuicide(i);
	return Plugin_Stop;
}

public Action Timer_Strike(Handle timer)
{
	float radius = 1.0, pos[3];
	for(int i = 1; i <= MaxClients; i++) if(IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
	{
		GetClientAbsOrigin(i, pos);
		pos[0] += GetRandomFloat(radius*-1, radius);
		pos[1] += GetRandomFloat(radius*-1, radius);
		CreateExplosion(pos);
	}
	return Plugin_Continue;
}

public Action Timer_StrikeTimeout(Handle timer)
{
	delete g_hExplosionTimer;
	return Plugin_Stop;
}

void CreateExplosion(float pos[3], const float duration = 6.0)
{
	static char buffer[32];

	int ent = CreateEntityByName("info_particle_system");
	if(ent != -1)
	{
		DispatchKeyValue(ent, "effect_name", FIRE_PARTICLE);
		TeleportEntity(ent, pos, NULL_VECTOR, NULL_VECTOR);
		DispatchSpawn(ent);
		ActivateEntity(ent);

		AcceptEntityInput(ent, "Start");
		FormatEx(buffer, sizeof(buffer), "OnUser1 !self:Stop::%f:1", duration);
		SetVariantString(buffer);
		AcceptEntityInput(ent, "AddOutput");
		AcceptEntityInput(ent, "FireUser1");
	}
	FormatEx(buffer, sizeof(buffer), "OnUser1 !self:Kill::%f:1", duration+1.5);

	if((ent = CreateEntityByName("info_particle_system")) != -1)
	{
		DispatchKeyValue(ent, "effect_name", EXPLOSION_PARTICLE);
		TeleportEntity(ent, pos, NULL_VECTOR, NULL_VECTOR);
		DispatchSpawn(ent);
		ActivateEntity(ent);

		AcceptEntityInput(ent, "Start");
		SetVariantString(buffer);
		AcceptEntityInput(ent, "AddOutput");
		AcceptEntityInput(ent, "FireUser1");
	}
	if((ent = CreateEntityByName("env_explosion")) != -1)
	{
		DispatchKeyValue(ent, "fireballsprite", "sprites/muzzleflash4.vmt");
		DispatchKeyValue(ent, "iMagnitude", "1");
		DispatchKeyValue(ent, "iRadiusOverride", "1");
		DispatchKeyValue(ent, "spawnflags", "828");
		TeleportEntity(ent, pos, NULL_VECTOR, NULL_VECTOR);
		DispatchSpawn(ent);

		AcceptEntityInput(ent, "Explode");
		SetVariantString(buffer);
		AcceptEntityInput(ent, "AddOutput");
		AcceptEntityInput(ent, "FireUser1");
	}
	if((ent = CreateEntityByName("env_physexplosion")) != -1)
	{
		DispatchKeyValue(ent, "radius", "1");
		DispatchKeyValue(ent, "magnitude", "1");
		TeleportEntity(ent, pos, NULL_VECTOR, NULL_VECTOR);
		DispatchSpawn(ent);

		AcceptEntityInput(ent, "Explode");
		SetVariantString(buffer);
		AcceptEntityInput(ent, "AddOutput");
		AcceptEntityInput(ent, "FireUser1");
	}

	EmitAmbientSound(EXPLOSION_SOUND, pos);
	EmitAmbientSound(EXPLOSION_DEBRIS, pos);

	static const float power = 1.0, flMxDistance = 1.0;
	float orig[3], vec[3], result[3];

	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
		{
			GetEntPropVector(i, Prop_Data, "m_vecOrigin", orig);
			if(GetVectorDistance(pos, orig) <= flMxDistance)
			{
				MakeVectorFromPoints(pos, orig, vec);
				GetVectorAngles(vec, result);

				GetEntPropVector(i, Prop_Data, "m_vecVelocity", vec);

				result[0] = Cosine(DegToRad(result[1])) * power + vec[0];
				result[1] = Sine(DegToRad(result[1])) * power + vec[1];
				result[2] = power;

				TeleportEntity(i, orig, NULL_VECTOR, result);
			}
		}
	}
}

void PrecacheParticle(const char[] sEffectName)
{
	static int table = INVALID_STRING_TABLE;
	if ( table == INVALID_STRING_TABLE )
	{
		table = FindStringTable("ParticleEffectNames");
	}
	if ( FindStringIndex(table, sEffectName) == INVALID_STRING_INDEX )
	{
		bool save = LockStringTables(false);
		AddToStringTable(table, sEffectName);
		LockStringTables(save);
	}
}