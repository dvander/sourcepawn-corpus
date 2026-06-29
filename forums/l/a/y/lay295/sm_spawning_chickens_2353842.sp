#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

public Plugin: myinfo =
{
	name = "Chicken spawner",
	author = "PeEzZ",
	description = "You can spawn chickens.",
	version = "1.1",
	url = ""
};

#define MODEL_CHICKEN "models/chicken/chicken.mdl"
#define MODEL_CHICKEN_ZOMBIE "models/chicken/chicken_zombie.mdl"

#define SOUND_CHICKEN_SPAWN "player/pl_respawn.wav"

public OnPluginStart()
{
	RegAdminCmd("sm_spawn_chicken", CMD_SpawnChicken, ADMFLAG_GENERIC, "Spawning chicken to the aim position.");
	RegAdminCmd("sm_spawnchicken", CMD_SpawnChicken, ADMFLAG_GENERIC, "Spawning chicken to the aim position.");
	RegAdminCmd("sm_sc", CMD_SpawnChicken, ADMFLAG_GENERIC, "Spawning chicken to the aim position.");
	
	RegAdminCmd("sm_spawn_zombie_chicken", CMD_SpawnZombieChicken, ADMFLAG_GENERIC, "Spawning zombie chicken to the aim position.");
	RegAdminCmd("sm_spawnzombiechicken", CMD_SpawnZombieChicken, ADMFLAG_GENERIC, "Spawning zombie chicken to the aim position.");
	RegAdminCmd("sm_szc", CMD_SpawnZombieChicken, ADMFLAG_GENERIC, "Spawning zombie chicken to the aim position.");
}

public OnMapStart()
{
	PrecacheModel(MODEL_CHICKEN, true);
	PrecacheModel(MODEL_CHICKEN_ZOMBIE, true);
	
	PrecacheSound(SOUND_CHICKEN_SPAWN, true);
	
	LoadTranslations("spawningchickens.phrases");
}

//-----COMMANDS-----//
public Action: CMD_SpawnChicken(client, args)
{
	SpawnChicken(client, 0);
	return Plugin_Handled;
}
public Action: CMD_SpawnZombieChicken(client, args)
{
	SpawnChicken(client, 1);
	return Plugin_Handled;
}

//----------------//
//-----STOCKS-----//
SpawnChicken(client, zombie)
{
	if(((client > 0) && (client <= MaxClients)) && IsClientInGame(client) && IsClientConnected(client))
	{
		if(IsPlayerAlive(client))
		{
			new Float: eye_pos[3],
				Float: eye_ang[3];
			
			GetClientEyePosition(client, eye_pos);
			GetClientEyeAngles(client, eye_ang);
			
			new Handle: trace = TR_TraceRayFilterEx(eye_pos, eye_ang, MASK_SOLID, RayType_Infinite, Dont_Hit_Players);
			if(TR_DidHit(trace))
			{
				if(TR_GetEntityIndex(trace) == 0)
				{
					new chicken = CreateEntityByName("chicken"); //The Chicken
					if(IsValidEntity(chicken))
					{
						new Float: end_pos[3];
						TR_GetEndPosition(end_pos, trace);
						end_pos[2] = (end_pos[2] + 10.0);
						
						new String: skin[16];
						Format(skin, sizeof(skin), "%i", GetRandomInt(0, 1));
						
						DispatchKeyValue(chicken, "glowenabled", "0"); //Glowing (0-off, 1-on)
						DispatchKeyValue(chicken, "glowcolor", "255 255 255"); //Glowing color (R, G, B)
						DispatchKeyValue(chicken, "rendercolor", "255 255 255"); //Chickens model color (R, G, B)
						DispatchKeyValue(chicken, "modelscale", "1"); //Chickens model scale (0.5 smaller, 1.5 bigger chicken, min: 0.1, max: -)
						DispatchKeyValue(chicken, "skin", skin); //Chickens model skin(default white 0, brown is 1)
						//DispatchKeyValue(chicken, "spawnflags", "1");
						DispatchSpawn(chicken);
						
						TeleportEntity(chicken, end_pos, NULL_VECTOR, NULL_VECTOR);
						
						if(zombie == 0)
						{
							CreateParticle(chicken, 0);
						}
						else if(zombie == 1)
						{
							CreateParticle(chicken, 1);
							SetEntityModel(chicken, MODEL_CHICKEN_ZOMBIE);
							HookSingleEntityOutput(chicken, "OnBreak", OnZombieChickenKill);
						}
						EmitSoundToAll(SOUND_CHICKEN_SPAWN, chicken);
						
						ReplyToCommand(client, "%t", "ChickenSpawned");
					}
				}
				else
				{
					ReplyToCommand(client, "%t", "CantSpawnHere");
				}
			}
			else
			{
				ReplyToCommand(client, "%t", "CantSpawnHere");
			}
		}
		else
		{
			ReplyToCommand(client, "%t", "OnlyAlive");
		}
	}
}

CreateParticle(entity, zombie)
{	
	new particle = CreateEntityByName("info_particle_system");
	if(IsValidEntity(particle))
	{
		new Float: pos[3];
		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", pos);
		TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);
		
		if(zombie == 0)
		{
			DispatchKeyValue(particle, "effect_name", "chicken_gone_feathers");
		}
		else if(zombie == 1)
		{
			DispatchKeyValue(particle, "effect_name", "chicken_gone_feathers_zombie");
		}
		
		DispatchKeyValue(particle, "angles", "-90 0 0");
		DispatchSpawn(particle);
		ActivateEntity(particle);
		
		AcceptEntityInput(particle, "Start");
		
		CreateTimer(5.0, KillEntity, particle);
	}
}

//-----SINGLEOUTPUTS-----//
public OnZombieChickenKill(const String: output[], caller, activator, Float: delay)
{
	CreateParticle(caller, 1);
}

//-----TIMERS-----//
public Action: KillEntity(Handle: timer, any: entity)
{
	AcceptEntityInput(entity, "Kill");
}

//-----FILTERS-----//
public bool: Dont_Hit_Players(entity, contentsMask, any: data)
{
	return !((entity > 0) && (entity <= MaxClients));
}