#include <sourcemod>
#include <sdkhooks>
#include <sdktools>

//ConVar's
ConVar cvarGlowColorRed, cvarGlowColorGreen, cvarGlowColorBlue, cvarGlowFlash, cvarTimeExplode, cvarChanceProp, cvarDamage,
	cvarRadius;

//Int's
int GlowColorBlue, GlowColorRed, GlowColorGreen, GlowFlash;

//Float's
float TimeExplode, ModelChance, iRadius, ExplosionDamage;

//pragma's
#pragma semicolon 1
#pragma newdecls required

//Entity's And Sound's
#define SOUND_SPAWN		"plats/churchbell_end.wav"
#define EXPLOSION_SOUND	"animation/bombing_run_01.wav"
#define EXPLOSION			"weapon_grenade_explosion"
#define SPAWN_EFFECT		 "electrical_arc_01_system"
#define EXPLOSION_HUGE	"gas_explosion_main"

public Plugin myinfo = 
{
	name		= "[L4D2]Tank Props Throw",
	author	  = "King_OXO",
	description = "Chance to the tank create a prop when launch rock",
	version	 = "3.0",
	url		 = "www.sourcemod.com"
};

public void OnPluginStart()
{
	cvarGlowColorRed	  = CreateConVar("l4d2_prop_glow_red", "255", "glow red color", FCVAR_NOTIFY, true, 0.0, true, 255.0);
	cvarGlowColorGreen	= CreateConVar("l4d2_prop_glow_green", "0", "glow green color", FCVAR_NOTIFY, true, 0.0, true, 255.0);
	cvarGlowColorBlue	 = CreateConVar("l4d2_prop_glow_blue", "0", "glow blue color", FCVAR_NOTIFY, true, 0.0, true, 255.0);
	cvarGlowFlash		 = CreateConVar("l4d2_prop_glow_flash", "1", "flashing glow prop created by the tank", FCVAR_NOTIFY);
	cvarTimeExplode	= CreateConVar("l4d2_prop_timer_explode", "15.0", "time for entities to explode", FCVAR_NOTIFY);
	cvarChanceProp		= CreateConVar("l4d2_prop_chance", "75.0", "Spawn prop chance", FCVAR_NOTIFY, true, 0.0, true, 100.0);	
	cvarDamage			= CreateConVar("l4d2_prop_explosion_damage", "27.0", "Damage when prop explodes", FCVAR_NOTIFY);	
	cvarRadius			= CreateConVar("l4d2_prop_explosion_radius", "1000.0", "Explosion radius when prop explodes", FCVAR_NOTIFY);	
	
	GlowColorRed	=  cvarGlowColorRed.IntValue;
	GlowColorGreen  =  cvarGlowColorGreen.IntValue;
	GlowColorBlue   =  cvarGlowColorBlue.IntValue;
	GlowFlash	=  cvarGlowFlash.IntValue;
	ExplosionDamage =  cvarDamage.FloatValue;
	ModelChance	 =  cvarChanceProp.FloatValue;
	TimeExplode	 =  cvarTimeExplode.FloatValue;
	iRadius		 =  cvarRadius.FloatValue;
	
	cvarGlowColorBlue.AddChangeHook(OnTPRCVarsChanged);
	cvarGlowColorGreen.AddChangeHook(OnTPRCVarsChanged);
	cvarGlowColorRed.AddChangeHook(OnTPRCVarsChanged);
	cvarGlowFlash.AddChangeHook(OnTPRCVarsChanged);
	cvarTimeExplode.AddChangeHook(OnTPRCVarsChanged);
	cvarChanceProp.AddChangeHook(OnTPRCVarsChanged);
	
	HookEvent("player_hurt", Player_Hurt);
	
	AutoExecConfig(true, "l4d2_tank_props");
}

public void OnTPRCVarsChanged(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	GlowColorRed	=  cvarGlowColorRed.IntValue;
	GlowColorGreen  =  cvarGlowColorGreen.IntValue;
	GlowColorBlue   =  cvarGlowColorBlue.IntValue;
	GlowFlash	=  cvarGlowFlash.IntValue;
	ExplosionDamage =  cvarDamage.FloatValue;
	ModelChance	 =  cvarChanceProp.FloatValue;
	TimeExplode	 =  cvarTimeExplode.FloatValue;
	iRadius		 =  cvarRadius.FloatValue;
}

public void OnMapStart()
{
	//Models 
	CheckModelPreCache("models/props_foliage/tree_trunk_fallen.mdl");
	CheckModelPreCache("models/props/cs_militia/militiarock01.mdl");
	CheckModelPreCache("models/props_vehicles/airport_baggage_cart2.mdl");
	CheckModelPreCache("models/props_debris/concrete_chunk01a.mdl");
	CheckModelPreCache("models/props_foliage/tree_trunk.mdl");
	
	//Sound's
	PrecacheSound(SOUND_SPAWN, true);
	PrecacheSound(EXPLOSION_SOUND, true);
	
	//Particle's
	PrecacheParticle(EXPLOSION_HUGE);
	PrecacheParticle(SPAWN_EFFECT);
	PrecacheParticle(EXPLOSION);
}

stock void CheckModelPreCache(const char[] Modelfile)
{
	if (!IsModelPrecached(Modelfile))
	{
		PrecacheModel(Modelfile, true);
		PrintToServer("Model: ♦ %s ♦, Are Precached",Modelfile);
	}
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if (StrEqual(classname, "tank_rock", false))
		RequestFrame(OnTankRockNextFrame, EntIndexToEntRef(entity));
}

void OnTankRockNextFrame(int iEntRef)
{
	if (!IsValidEntRef(iEntRef))
		return;
	
	int entity = EntRefToEntIndex(iEntRef);
	
	int client = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
	
	if (!IsValidClient(client))
		return;
	
	if (!IsPlayerAlive(client))
		return;

	if (GetClientTeam(client) != 3)
		return;
	
	CreateTimer(0.1, Throw, entity, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);

}

Action Throw(Handle timer, int entity)
{
	float velocity[3];
	if (IsValidEntity(entity))
	{
		int g_iVelocity = FindSendPropInfo("CBasePlayer", "m_vecVelocity[0]");	
		GetEntDataVector(entity, g_iVelocity, velocity);
		float v = GetVectorLength(velocity);
		if (v > 0.1)
		{
			int client = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
		
			float Pos[3];
			GetEntPropVector(entity, Prop_Send, "m_vecOrigin", Pos);  
		
			if( GetRandomFloat( 0.0, 100.0 ) < ModelChance )
			{
				Handle msg;
				msg = StartMessageOne("Shake", client);
		
				BfWriteByte(msg, 0);
				BfWriteFloat(msg, 20.0);
				BfWriteFloat(msg, 8.0);
				BfWriteFloat(msg, 5.0);
				EndMessage();
				
				int physics = CreateEntityByName("prop_physics_multiplayer");
				if (IsValidEntity(physics))
				{
					int Model = GetRandomInt(0, 2);
					switch(Model)
					{
						case 0: SetEntityModel(physics, "models/props_foliage/tree_trunk_fallen.mdl");
						case 1: SetEntityModel(physics, "models/props/cs_militia/militiarock01.mdl");
						case 2: SetEntityModel(physics, "models/props_vehicles/airport_baggage_cart2.mdl");
					}
					RemoveEntity(entity);
				
					ShowParticle(Pos, SPAWN_EFFECT);
					EmitSoundToAll(SOUND_SPAWN, client);
					
					DispatchSpawn(physics);
					float speed = GetConVarFloat(FindConVar("z_tank_throw_force"));
					ScaleVector(velocity, speed*2.0);
					TeleportEntity(physics, Pos, NULL_VECTOR, velocity);
					CreateTimer(TimeExplode, Explosion, physics);
				
					SetEntProp(physics, Prop_Send, "m_glowColorOverride", GlowColorRed + (GlowColorGreen * 256) + (GlowColorBlue * 65536));
					SetEntProp(physics, Prop_Send, "m_iGlowType", 3);
					SetEntProp(physics, Prop_Send, "m_bFlashing", GlowFlash);
				}
			}
			else
			{
				int Model = GetRandomInt(0, 1);
				switch(Model)
				{
					case 0: 
					{
						SetEntityModel(entity, "models/props_debris/concrete_chunk01a.mdl");
						SetEntPropFloat(entity, Prop_Send, "m_flModelScale", 1.2);
						IgniteEntity(entity, 5.0);
						SetEntityRenderColor(entity, 255, 0, 0, 50);
					}
					case 1: 
					{
						SetEntityModel(entity, "models/props_foliage/tree_trunk.mdl");
						SetEntPropFloat(entity, Prop_Send, "m_flModelScale", 1.2);
						IgniteEntity(entity, 5.0);
						SetEntityRenderColor(entity, 255, 0, 0, 50);
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

public bool bTraceEntityFilterPlayer( int entity, int contentsMask )
{
	return ( entity > MaxClients || !entity );
}

public void Player_Hurt(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	char weapon[64];
	GetEventString(event, "weapon", weapon, sizeof(weapon));
	if (StrEqual(weapon, "tank_rock", true) && IsTank(attacker))
	{
		float Pos[3];
		
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", Pos);
		MiniExplosion(Pos, client);
	}
}

public Action Explosion(Handle timer, int physics)
{
	if(IsValidEntity(physics))
	{
		float Pos[3];
		GetEntPropVector(physics, Prop_Send, "m_vecOrigin", Pos);
	 
		RemoveEntity(physics);
	
		ExplodeMain(Pos, physics);
	}
	
	return Plugin_Stop;
}

void ExplodeMain(float Pos[3], int physics)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsSurvivor( i ))
		{
			float SurvivorPoS[3];
			GetClientAbsOrigin(i, SurvivorPoS);
			float distance = GetVectorDistance(Pos, SurvivorPoS);
			if (distance <= iRadius)
			{
				SurvivorReaction(i, Pos, ExplosionDamage);
			}
		}
	}
	ShowParticle(Pos, EXPLOSION_HUGE);
	
	EmitSoundToAll(EXPLOSION_SOUND, physics);
}

void MiniExplosion(float Pos[3], int victim)
{
	SurvivorReaction(victim, Pos, 15.0);
	
	ShowParticle(Pos, EXPLOSION);
	
	EmitSoundToAll(EXPLOSION_SOUND, victim);
}

void PrecacheParticle(const char[] sEffectName)
{
	static int table = INVALID_STRING_TABLE;
	if( table == INVALID_STRING_TABLE )
	{
		table = FindStringTable("ParticleEffectNames");
	}

	if( FindStringIndex(table, sEffectName) == INVALID_STRING_INDEX )
	{
		bool save = LockStringTables(false);
		AddToStringTable(table, sEffectName);
		LockStringTables(save);
	}
}

void ShowParticle( float Pos[3], char[] particlename )
{
	int particle = CreateEntityByName("info_particle_system");
	if( particle != -1 )
	{
		DispatchKeyValue(particle, "effect_name", particlename);
		
		DispatchSpawn(particle);
		ActivateEntity(particle);
		AcceptEntityInput(particle, "start");

		TeleportEntity(particle, Pos, NULL_VECTOR, NULL_VECTOR);

		SetVariantString("OnUser1 !self:Kill::1.0:1");
		AcceptEntityInput(particle, "AddOutput");
		AcceptEntityInput(particle, "FireUser1"); 
	}
}

/**
 * Validates if is a valid entity reference.
 *
 * @param client		Entity reference.
 * @return			  True if entity reference is valid, false otherwise.
 */
bool IsValidEntRef(int iEntRef)
{
	return iEntRef != 0 && EntRefToEntIndex(iEntRef) != INVALID_ENT_REFERENCE;
}

bool IsValidClient(int client)
{
	return (1 <= client <= MaxClients && IsClientInGame(client));
}

bool IsTank(int client)
{
	if (IsValidClient(client) && GetClientTeam(client) == 3)
	{
		int class = GetEntProp(client, Prop_Send, "m_zombieClass");
		if (class == 8)
			return true;
		return false;
	}
	return false;
}

stock bool IsSurvivor(int client)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2)
	{
		return true;
	}
	return false;
}

stock void SurvivorReaction(int target, float vPos[3], float damage)
{
	if (target > 0 && target <= MaxClients)
	{
		if (IsClientInGame(target) && IsPlayerAlive(target))
		{
			SDKHooks_TakeDamage(target, 0, 0, damage, DMG_BLAST);
			
			Handle msg;
			msg = StartMessageOne("Shake", target);
	
			BfWriteByte(msg, 0);
			BfWriteFloat(msg, 20.0);
			BfWriteFloat(msg, 8.0);
			BfWriteFloat(msg, 5.0);
			EndMessage();
			
			StaggerClient(GetClientUserId(target), vPos);
		}
	}
}

void StaggerClient(int iUserID, const float fPos[3])
{
	static int iScriptLogic = INVALID_ENT_REFERENCE;
	if( iScriptLogic == INVALID_ENT_REFERENCE || !IsValidEntity(iScriptLogic) )
	{
		iScriptLogic = EntIndexToEntRef(CreateEntityByName("logic_script"));
		if(iScriptLogic == INVALID_ENT_REFERENCE || !IsValidEntity(iScriptLogic))
			LogError("Could not create 'logic_script");

		DispatchSpawn(iScriptLogic);
	}

	char sBuffer[96];
	Format(sBuffer, sizeof(sBuffer), "GetPlayerFromUserID(%d).Stagger(Vector(%d,%d,%d))", iUserID, RoundFloat(fPos[0]), RoundFloat(fPos[1]), RoundFloat(fPos[2]));
	SetVariantString(sBuffer);
	AcceptEntityInput(iScriptLogic, "RunScriptCode");
	RemoveEntity(iScriptLogic);
}