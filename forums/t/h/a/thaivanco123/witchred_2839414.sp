#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <left4dhooks>

#define SPRITE_BEAM    "materials/sprites/laserbeam.vmt"
#define SPRITE_HALO    "materials/sun/overlay.vmt"
#define MAXPARTICLES 9
#define MAX_ENTITIES 2048

int g_iBeamCol[MAXPLAYERS + 1][4];
float g_fBrandPos[MAXPLAYERS + 1][3];

Handle g_hIceDamageTimer[MAXPLAYERS + 1];
Handle g_hAcidSpillDamageTimer[MAXPLAYERS + 1];
Handle g_hAcidDamageCheckTimer[MAXPLAYERS + 1];

ConVar g_hCvarIceTimeout, g_hCvarAcidSpillTimeout, g_hCvarAcidDamage;
ConVar g_hCvarVomitWitchHealth, g_hCvarBlackWitchHealth, g_hCvarIceWitchHealth;
ConVar g_hCvarFireWitchHealth, g_hCvarGreenWitchHealth;

float g_fIceTimeout, g_fAcidSpillTimeout;
int g_iAcidDamage, g_iVomitWitchHealth, g_iBlackWitchHealth;
int g_iIceWitchHealth, g_iFireWitchHealth, g_iGreenWitchHealth;

bool g_bAcidSpillEnable[MAXPLAYERS + 1];
bool g_bIsLeft4Dead2;
int g_iBeamSprite, g_iHaloSprite, g_iVisibility;

int g_iWitchType[MAX_ENTITIES];
int g_iAcidPuddleWitch[MAX_ENTITIES];

static char g_sParticleTable[MAXPARTICLES][] = 
{
	"policecar_tail_strobe_2b", 
	"aircraft_destroy_fastFireTrail", 
	"fire_small_01", 
	"apc_wheel_smoke1", 
	"boomer_leg_smoke", 
	"boomer_explode_D", 
	"vomit_jar_b", 
	"spitter_areaofdenial_base_refract", 
	"water_child_water5"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();
	switch (test)
	{
		case Engine_Left4Dead2:
		{
			g_bIsLeft4Dead2 = true;
		}
		case Engine_Left4Dead:
		{
			g_bIsLeft4Dead2 = false;
		}
		default:
		{
			strcopy(error, err_max, "Plugin only supports Left 4 Dead 1 & 2.");
			return APLRes_SilentFailure;
		}
	}
	return APLRes_Success;
}

public void OnPluginStart()
{
	g_hCvarIceTimeout = CreateConVar("Ice_Timeout", "30", "Freezing damage duration", FCVAR_NONE, true, 0.0, false, 0.0);
	g_hCvarAcidSpillTimeout = CreateConVar("AcidSpill_Timeout", "1", "Venom damage duration", FCVAR_NONE, true, 0.0, false, 0.0);
	g_hCvarAcidDamage = CreateConVar("AcidSpill_Damage", "5", "Damage per second from acid spill", FCVAR_NONE, true, 0.0, true, 100.0);
	g_hCvarGreenWitchHealth = CreateConVar("GreenWitch_hp", "2000", "Toxic witch's blood volume", FCVAR_NONE, true, 1.0, true, 10000.0);
	g_hCvarFireWitchHealth = CreateConVar("FireWitch_hp", "3000", "Flame witch's blood", FCVAR_NONE, true, 1.0, true, 10000.0);
	g_hCvarIceWitchHealth = CreateConVar("IceWitch_hp", "3000", "Frozen witch's blood", FCVAR_NONE, true, 1.0, true, 10000.0);
	g_hCvarBlackWitchHealth = CreateConVar("BlackWitch_hp", "3000", "Dark witch's blood", FCVAR_NONE, true, 1.0, true, 10000.0);
	g_hCvarVomitWitchHealth = CreateConVar("VomitWitch_hp", "3000", "Bile witch's blood volume", FCVAR_NONE, true, 1.0, true, 10000.0);

	g_hCvarIceTimeout.AddChangeHook(OnCvarChanged);
	g_hCvarAcidSpillTimeout.AddChangeHook(OnCvarChanged);
	g_hCvarAcidDamage.AddChangeHook(OnCvarChanged);
	g_hCvarVomitWitchHealth.AddChangeHook(OnCvarChanged);
	g_hCvarBlackWitchHealth.AddChangeHook(OnCvarChanged);
	g_hCvarIceWitchHealth.AddChangeHook(OnCvarChanged);
	g_hCvarFireWitchHealth.AddChangeHook(OnCvarChanged);
	g_hCvarGreenWitchHealth.AddChangeHook(OnCvarChanged);
	
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("witch_spawn", Event_WitchSpawn);
	HookEvent("witch_harasser_set", Event_WitchSet);
	HookEvent("round_start", Event_RoundStart);
	
	AutoExecConfig(true, "witch_red");
	
	GetCvars();
}

void OnCvarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

void GetCvars()
{
	g_fIceTimeout = g_hCvarIceTimeout.FloatValue;
	g_fAcidSpillTimeout = g_hCvarAcidSpillTimeout.FloatValue;
	g_iAcidDamage = g_hCvarAcidDamage.IntValue;
	g_iVomitWitchHealth = g_hCvarVomitWitchHealth.IntValue;
	g_iBlackWitchHealth = g_hCvarBlackWitchHealth.IntValue;
	g_iIceWitchHealth = g_hCvarIceWitchHealth.IntValue;
	g_iFireWitchHealth = g_hCvarFireWitchHealth.IntValue;
	g_iGreenWitchHealth = g_hCvarGreenWitchHealth.IntValue;
}

public void OnMapStart()
{
	int max = g_bIsLeft4Dead2 ? MAXPARTICLES : (MAXPARTICLES - 3);
	
	for (int i = 0; i < max; i++)
		Precache_Particle_System(g_sParticleTable[i]);
	
	g_iBeamSprite = PrecacheModel(SPRITE_BEAM);
	g_iHaloSprite = PrecacheModel(SPRITE_HALO);
	
	PrecacheSound("ambient/ambience/rainscapes/rain/debris_05.wav");
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if (classname[0] == 'i' && strcmp(classname, "insect_swarm") == 0)
	{
		SDKHook(entity, SDKHook_SpawnPost, OnInsectSwarmSpawnPost);
	}
}

void OnInsectSwarmSpawnPost(int entity)
{
	if (IsValidEntity(entity))
	{
		L4D2Direct_SetInfernoMaxFlames(entity, 2);
	}
}

Action Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (client && client <= MaxClients && GetClientTeam(client) == 2)
	{
		if (g_hAcidSpillDamageTimer[client])
		{
			delete g_hAcidSpillDamageTimer[client];
		}
		if (g_hAcidDamageCheckTimer[client])
		{
			delete g_hAcidDamageCheckTimer[client];
		}
	}
	return Plugin_Continue;
}

Action Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	for (int i = 0; i < MAX_ENTITIES; i++)
	{
		g_iWitchType[i] = 0;
		g_iAcidPuddleWitch[i] = 0;
	}
	return Plugin_Continue;
}

void ShowParticle(float pos[3], const char[] particlename, float time)
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
		CreateTimer(time, Timer_DeleteParticles, particle, TIMER_FLAG_NO_MAPCHANGE);
	}
}

void CreateParticle(int ent, const char[] particleType, float time)
{
	if (!IsValidWitch(ent))
		return;
	
	static char sTargetName[64];
	int particle = CreateEntityByName("info_particle_system");
	if (IsValidEntity(particle))
	{
		float pos[3];
		GetEntPropVector(ent, Prop_Send, "m_vecOrigin", pos);
		TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);
		GetEntPropString(ent, Prop_Data, "m_iName", sTargetName, sizeof(sTargetName));
		DispatchKeyValue(particle, "targetname", sTargetName);
		DispatchKeyValue(particle, "parentname", sTargetName);
		DispatchKeyValue(particle, "effect_name", particleType);
		DispatchSpawn(particle);
		SetVariantString(sTargetName);
		AcceptEntityInput(particle, "SetParent", particle, particle);
		ActivateEntity(particle);
		AcceptEntityInput(particle, "start");
		CreateTimer(time, Timer_DeleteParticles, particle, TIMER_FLAG_NO_MAPCHANGE);
	}
}

Action Timer_DeleteParticles(Handle timer, int particle)
{
	if (IsValidEntity(particle) && IsValidEdict(particle))
	{
		static char sClassname[64];
		GetEdictClassname(particle, sClassname, sizeof(sClassname));
		if (strcmp(sClassname, "info_particle_system") == 0)
		{
			AcceptEntityInput(particle, "stop");
			AcceptEntityInput(particle, "kill");
			RemoveEntity(particle);
		}
	}
	return Plugin_Continue;
}

Action Event_WitchSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int witchid = event.GetInt("witchid");
	CreateEffects(witchid, GetRandomInt(1, 5));
	
	return Plugin_Continue;
}

void CreateEffects(int witch, int witchType) 
{
	float fPos[3];
	GetEntPropVector(witch, Prop_Send, "m_vecOrigin", fPos);
	
	switch (witchType) 
	{
		case 1: // Green Witch
		{
			SetEntProp(witch, Prop_Data, "m_iMaxHealth", g_iGreenWitchHealth);
			SetEntProp(witch, Prop_Data, "m_iHealth", g_iGreenWitchHealth);
			CreateTimer(0.33, Timer_WitchGreen, witch, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
		}
		case 2: // Fire Witch
		{
			SetEntProp(witch, Prop_Data, "m_iMaxHealth", g_iFireWitchHealth);
			SetEntProp(witch, Prop_Data, "m_iHealth", g_iFireWitchHealth);
			CreateTimer(0.33, Timer_WhiteFire, witch, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
		}
		case 3: // Ice Witch
		{
			SetEntProp(witch, Prop_Data, "m_iMaxHealth", g_iIceWitchHealth);
			SetEntProp(witch, Prop_Data, "m_iHealth", g_iIceWitchHealth);
			CreateTimer(0.33, Timer_WitchBlue, witch, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
		}
		case 4: // Black Witch
		{
			SetEntProp(witch, Prop_Data, "m_iMaxHealth", g_iBlackWitchHealth);
			SetEntProp(witch, Prop_Data, "m_iHealth", g_iBlackWitchHealth);
			CreateTimer(0.33, Timer_WitchBlack, witch, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
		}
		case 5: // Vomit Witch
		{
			SetEntProp(witch, Prop_Data, "m_iMaxHealth", g_iVomitWitchHealth);
			SetEntProp(witch, Prop_Data, "m_iHealth", g_iVomitWitchHealth);
			CreateTimer(0.33, Timer_WitchVomit, witch, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
		}
	}
	g_iWitchType[witch] = witchType;
}

Action Event_WitchSet(Event event, const char[] name, bool dontBroadcast)
{
	int witch = event.GetInt("witchid");
	if (!IsValidWitch(witch))
		return Plugin_Continue;
	
	int target = GetClientOfUserId(event.GetInt("userid"));
	if (target <= 0 || !IsClientInGame(target) || GetClientTeam(target) != 2)
		return Plugin_Continue;
	
	int type = g_iWitchType[witch];
	switch (type)
	{
		case 1: // Green Witch
		{
			CreateTimer(g_fAcidSpillTimeout, Timer_AcidSpillOut, target, TIMER_FLAG_NO_MAPCHANGE);
			g_bAcidSpillEnable[target] = true;
			int packedData = (EntIndexToEntRef(witch) << 16) | target;
			g_hAcidSpillDamageTimer[target] = CreateTimer(1.0, Timer_AcidSpill, packedData, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
			g_hAcidDamageCheckTimer[target] = CreateTimer(1.0, Timer_CheckAcidDamage, target, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
		}
		case 2: // Fire Witch
		{
			CreateParticle(target, "aircraft_destroy_fastFireTrail", 10.0);
			IgniteEntity(target, 10.0);
			DealDamage(target, 30, witch, DMG_BURN, "");
		}
		case 3: // Ice Witch
		{
			CreateTimer(0.33, Timer_Freeze, target, TIMER_FLAG_NO_MAPCHANGE);
		}
		case 4: // Black Witch
		{
			CreateTimer(0.33, Timer_Fadeout, target, TIMER_FLAG_NO_MAPCHANGE);
			ScreenFade(target, 0, 255, 255, 192, 5000, 1);
		}
		case 5: // Vomit Witch
		{
			L4D_CTerrorPlayer_OnVomitedUpon(target, target);
		}
	}
	
	return Plugin_Continue;
}

Action Timer_Freeze(Handle timer, int client)
{
	if (IsPlayerAlive(client))
	{
		SetEntityRenderMode(client, RENDER_GLOW);
		SetEntityRenderColor(client, 0, 100, 170, 180);
		SetEntityMoveType(client, MOVETYPE_NONE);
		CreateTimer(5.0, Timer_UnFreeze, client, TIMER_FLAG_NO_MAPCHANGE);
		EmitSoundToAll("ambient/ambience/rainscapes/rain/debris_05.wav", client, 0, 75, 0, 1.0, 100, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
		ScreenFade(client, 0, 128, 255, 192, 5000, 1);
		CreateTimer(g_fIceTimeout, Timer_IceOut, client, TIMER_FLAG_NO_MAPCHANGE);
		g_hIceDamageTimer[client] = CreateTimer(7.0, Timer_IceWitch, client, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	}
	return Plugin_Continue;
}

Action Timer_AcidSpillOut(Handle timer, int client)
{
	if (g_hAcidSpillDamageTimer[client])
	{
		g_bAcidSpillEnable[client] = false;
		delete g_hAcidSpillDamageTimer[client];
	}
	if (g_hAcidDamageCheckTimer[client])
	{
		delete g_hAcidDamageCheckTimer[client];
	}
	return Plugin_Continue;
}

Action Timer_IceOut(Handle timer, int client)
{
	if (g_hIceDamageTimer[client])
	{
		delete g_hIceDamageTimer[client];
	}
	return Plugin_Continue;
}

Action Timer_AcidSpill(Handle timer, int packedData)
{
	int witchRef = packedData >> 16;
	int witch = EntRefToEntIndex(witchRef);
	int client = packedData & 0xFFFF;
	
	if (IsValidWitch(witch) && client > 0 && IsClientInGame(client) && IsPlayerAlive(client) && g_bAcidSpillEnable[client])
	{
		CreateAcidSpillCluster(witch, client);
	}
	return Plugin_Continue;
}

void CreateAcidSpillCluster(int attacker, int target)
{
	float vPos[3];
	GetEntPropVector(target, Prop_Data, "m_vecAbsOrigin", vPos);
	
	int spitter_projectile = L4D2_SpitterPrj(attacker, vPos, NULL_VECTOR);
	if (spitter_projectile > 0 && IsValidEntity(spitter_projectile))
	{
		g_iAcidPuddleWitch[spitter_projectile] = EntIndexToEntRef(attacker);
		L4D_DetonateProjectile(spitter_projectile);
	}
}

Action Timer_CheckAcidDamage(Handle timer, int client)
{
	if (!IsClientInGame(client) || !IsPlayerAlive(client) || !g_bAcidSpillEnable[client])
	{
		if (g_hAcidDamageCheckTimer[client])
		{
			delete g_hAcidDamageCheckTimer[client];
		}
		return Plugin_Continue;
	}

	float clientPos[3];
	GetClientAbsOrigin(client, clientPos);

	for (int entity = MaxClients + 1; entity < MAX_ENTITIES; entity++)
	{
		if (!IsValidEntity(entity))
			continue;

		static char sClassname[32];
		GetEdictClassname(entity, sClassname, sizeof(sClassname));
		if (strcmp(sClassname, "insect_swarm") != 0)
			continue;

		int witchRef = g_iAcidPuddleWitch[entity];
		int witch = EntRefToEntIndex(witchRef);
		if (!IsValidWitch(witch))
			continue;

		float puddlePos[3];
		GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", puddlePos);

		if (GetVectorDistance(clientPos, puddlePos) <= 100.0)
		{
			DealDamage(client, g_iAcidDamage, witch, DMG_ACID, "insect_swarm");
		}
	}

	return Plugin_Continue;
}

Action Timer_WhiteFire(Handle timer, int witch) 
{
	if (!IsValidWitch(witch))
		return Plugin_Stop;
	
	CreateParticle(witch, "fire_small_01", 1.0);
	return Plugin_Continue;
}

Action Timer_WitchGreen(Handle timer, int witch) 
{
	if (!IsValidWitch(witch))
		return Plugin_Stop;
	
	if (g_bIsLeft4Dead2)
	{
		CreateParticle(witch, "spitter_areaofdenial_base_refract", 5.0);
	}
	return Plugin_Continue;
}

Action Timer_WitchBlue(Handle timer, int witch) 
{
	if (!IsValidWitch(witch))
		return Plugin_Stop;
	
	if (g_bIsLeft4Dead2) 
	{
		CreateParticle(witch, "apc_wheel_smoke1", 1.0);
		CreateParticle(witch, "water_child_water5", 3.0);
	} 
	else 
	{
		CreateParticle(witch, "apc_wheel_smoke1", 1.0);
		CreateParticle(witch, "boomer_leg_smoke", 3.0);
	}
	return Plugin_Continue;
}

Action Timer_WitchBlack(Handle timer, int witch) 
{
	if (!IsValidWitch(witch))
		return Plugin_Stop;
	
	float entpos[3], effectpos[3];
	GetEntPropVector(witch, Prop_Send, "m_vecOrigin", entpos);
	effectpos[0] = entpos[0];
	effectpos[1] = entpos[1];
	effectpos[2] = entpos[2] + 70;
	ShowParticle(effectpos, "policecar_tail_strobe_2b", 3.0);
	return Plugin_Continue;
}

Action Timer_WitchVomit(Handle timer, int witch) 
{
	if (!IsValidWitch(witch))
		return Plugin_Stop;
	
	if (g_bIsLeft4Dead2) 
	{
		CreateParticle(witch, "vomit_jar_b", 1.0);
	} 
	else 
	{
		CreateParticle(witch, "boomer_explode_D", 1.0);
	}
	return Plugin_Continue;
}

Action Timer_Fadeout(Handle timer, int killer)
{
	g_iVisibility += 8;
	if (g_iVisibility > 240) 
		g_iVisibility = 240;
	
	ScreenFade(killer, 0, 0, 0, g_iVisibility, 0, 0);
	if (g_iVisibility >= 240)
	{
		FakeRealism(true);
		return Plugin_Stop;
	}
	
	return Plugin_Continue;
}

Action Timer_IceWitch(Handle timer, int client)
{
	int color[4];
	color[0] = GetRandomInt(1, 255);
	color[1] = GetRandomInt(1, 255);
	color[2] = GetRandomInt(1, 255);
	color[3] = 255;
	
	float vec[3];
	GetClientAbsOrigin(client, vec);
	vec[2] += 30;
	
	TE_SetupBeamRingPoint(vec, 20.0, 200.0, g_iBeamSprite, g_iHaloSprite, 0, 15, 3.0, 6.0, 0.0, color, 10, 0);
	TE_SendToAll();
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == 2)
		{
			float pos[3], pos_t[3];
			GetClientAbsOrigin(client, pos);
			GetClientAbsOrigin(i, pos_t);
			float distance = GetVectorDistance(pos, pos_t);
			
			if (distance <= 1200.0)
			{
				ServerCommand("sm_freeze \"%N\" \"3\"", i);
				CreateTimer(g_fIceTimeout, Timer_IceOut, i, TIMER_FLAG_NO_MAPCHANGE);
				EmitSoundToAll("ambient/ambience/rainscapes/rain/debris_05.wav", i, 0, 75, 0, 1.0, 100, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
			}
		}
	}
	
	GetClientAbsOrigin(client, g_fBrandPos[client]);
	g_iBeamCol[client][0] = GetRandomInt(0, 255);
	g_iBeamCol[client][1] = GetRandomInt(0, 255);
	g_iBeamCol[client][2] = GetRandomInt(0, 255);
	g_iBeamCol[client][3] = 135;
	return Plugin_Continue;
}

Action Timer_UnFreeze(Handle timer, int client)
{
	if (client && IsClientInGame(client) && !IsFakeClient(client) && IsPlayerAlive(client) && GetClientTeam(client) == 2)
	{
		SetEntityRenderMode(client, RENDER_GLOW);
		SetEntityRenderColor(client, 255, 255, 255, 255);
		SetEntityMoveType(client, MOVETYPE_WALK);
	}
	return Plugin_Continue;
}

void FakeRealism(bool mode)
{
	ConVar cvar;
	
	cvar = FindConVar("sv_disable_glow_faritems");
	if (cvar)
		cvar.SetInt(!!mode, true, true);
	
	cvar = FindConVar("sv_disable_glow_survivors");
	if (cvar)
		cvar.SetInt(!!mode, true, true);
}

void ScreenFade(int target, int red, int green, int blue, int alpha, int duration, int type)
{
	Handle msg = StartMessageOne("Fade", target);
	if (msg)
	{
		BfWriteShort(msg, 500);
		BfWriteShort(msg, duration);
		BfWriteShort(msg, type ? (0x0001 | 0x0010) : (0x0002 | 0x0008));
		BfWriteByte(msg, red);
		BfWriteByte(msg, green);
		BfWriteByte(msg, blue);
		BfWriteByte(msg, alpha);
		EndMessage();
	}
}

void DealDamage(int victim, int damage, int attacker = 0, int dmg_type = DMG_GENERIC, const char[] weapon = "") 
{
	if (victim > 0 && IsValidEdict(victim) && IsClientInGame(victim) && IsPlayerAlive(victim)) 
	{
		static char sDamage[16], sDamageType[32];
		IntToString(damage, sDamage, sizeof(sDamage));
		IntToString(dmg_type, sDamageType, sizeof(sDamageType));
		
		int pointHurt = CreateEntityByName("point_hurt");
		if (pointHurt) 
		{
			DispatchKeyValue(victim, "targetname", "war3_hurtme");
			DispatchKeyValue(pointHurt, "DamageTarget", "war3_hurtme");
			DispatchKeyValue(pointHurt, "Damage", sDamage);
			DispatchKeyValue(pointHurt, "DamageType", sDamageType);
			
			if (weapon[0])
			{
				DispatchKeyValue(pointHurt, "classname", weapon);
			}
			DispatchSpawn(pointHurt);
			AcceptEntityInput(pointHurt, "Hurt", (attacker > 0) ? attacker : -1);
			DispatchKeyValue(pointHurt, "classname", "point_hurt");
			DispatchKeyValue(victim, "targetname", "war3_donthurtme");
			RemoveEdict(pointHurt);
		}
	}
}

bool IsValidWitch(int entity) 
{
	if (entity <= 0 || !IsValidEntity(entity))
		return false;
	
	static char sClassname[32];
	GetEdictClassname(entity, sClassname, sizeof(sClassname));
	return (sClassname[0] == 'w' && strcmp(sClassname, "witch") == 0);
}