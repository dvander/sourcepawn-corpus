#include <sourcemod>
#include <sdkhooks>
#include <sdktools>

//ConVar's
ConVar g_cvChanceProp, g_cvTimeRemove;

//Float's
float g_fModelChance, g_fTimeRemove;

//pragma's
#pragma semicolon 1
#pragma newdecls required

//Entity's And Sound's
#define SOUND_SPAWN		"animation/bombing_run_01.wav"
#define SPAWN_EFFECT	 "electrical_arc_01_system"

// Model arrays
char g_sModels[][64] = {
	"models/props_foliage/tree_trunk_fallen.mdl",
	"models/props/cs_militia/militiarock01.mdl",
	"models/props_vehicles/airport_baggage_cart2.mdl",
	"models/props_debris/concrete_chunk01a.mdl",
	"models/props_vehicles/cara_69sedan.mdl",
	"models/props_vehicles/police_car_city.mdl",
	"models/props_vehicles/police_car_rural.mdl",
	"models/props_fairgrounds/coaster_car01.mdl",
	"models/props_fairgrounds/kiddyland_ridecar.mdl",
	"models/props_vehicles/floodlight_generator_pose01_static.mdl",
	"models/props_fairgrounds/swan_boat.mdl",
	"models/props_interiors/couch.mdl",
	"models/props_fairgrounds/bumpercar_wpole.mdl",
	"models/props_fairgrounds/bumpercar.mdl",
	"models/props_fairgrounds/kiddyland_ridetrain.mdl",
	"models/props_unique/airport/atlas_break_ball.mdl"
};

public Plugin myinfo = 
{
	name		= "[L4D2] TankUltraPropsRocks",
	author	  = "Davertmin",
	description = "Tank rocks spawn random props (16 objects) - No explosions",
	version	 = "1.2",
	url		 = ""
};

public void OnPluginStart()
{
	g_cvChanceProp = CreateConVar("l4d2_tankultrarocks_chance", "75.0", "Spawn prop chance", FCVAR_NOTIFY, true, 0.0, true, 100.0);
	g_cvTimeRemove = CreateConVar("l4d2_tankultrarocks_time", "15.0", "Time in seconds to remove the prop (0 = never remove)", FCVAR_NOTIFY);
	
	g_fModelChance = g_cvChanceProp.FloatValue;
	g_fTimeRemove = g_cvTimeRemove.FloatValue;
	
	g_cvChanceProp.AddChangeHook(OnTPRCVarsChanged);
	g_cvTimeRemove.AddChangeHook(OnTPRCVarsChanged);
	
	AutoExecConfig(true, "l4d2_tankultrarocks_props");
	
	// Chat commands
	RegConsoleCmd("sm_tankpropchance", Command_ChangeChance);
	RegConsoleCmd("sm_tankproptime", Command_ChangeTime);
}

public void OnTPRCVarsChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_fModelChance = g_cvChanceProp.FloatValue;
	g_fTimeRemove = g_cvTimeRemove.FloatValue;
}

public void OnMapStart()
{
	//Models 
	for(int i = 0; i < sizeof(g_sModels); i++)
	{
		CheckModelPreCache(g_sModels[i]);
	}
	
	//Sound's
	PrecacheSound(SOUND_SPAWN, true);
	
	//Particle's
	PrecacheParticle(SPAWN_EFFECT);
}

stock void CheckModelPreCache(const char[] sModelfile)
{
	if (!IsModelPrecached(sModelfile))
	{
		PrecacheModel(sModelfile, true);
		PrintToServer("Model: ♦ %s ♦, Are Precached", sModelfile);
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
	
	CreateTimer(0.1, Timer_Throw, entity, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

Action Timer_Throw(Handle timer, int entity)
{
	float velocity[3];
	
	if (!IsValidEntity(entity))
		return Plugin_Stop;
	
	int g_iVelocity = FindSendPropInfo("CBasePlayer", "m_vecVelocity[0]");	
	GetEntDataVector(entity, g_iVelocity, velocity);
	float v = GetVectorLength(velocity);
	
	if (v > 0.1)
	{
		int client = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
	
		float Pos[3];
		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", Pos);  
	
		if(GetRandomFloat(0.0, 100.0) < g_fModelChance)
		{
			Handle msg = StartMessageOne("Shake", client);
			if(msg != null)
			{
				BfWriteByte(msg, 0);
				BfWriteFloat(msg, 20.0);
				BfWriteFloat(msg, 8.0);
				BfWriteFloat(msg, 5.0);
				EndMessage();
			}
			
			int physics = CreateEntityByName("prop_physics_multiplayer");
			if (IsValidEntity(physics))
			{
				int Model = GetRandomInt(0, sizeof(g_sModels) - 1);
				SetEntityModel(physics, g_sModels[Model]);
				
				RemoveEntity(entity);
			
				ShowParticle(Pos, SPAWN_EFFECT);
				EmitSoundToAll(SOUND_SPAWN, client);
				
				DispatchSpawn(physics);
				float speed = GetConVarFloat(FindConVar("z_tank_throw_force"));
				ScaleVector(velocity, speed * 2.0);
				TeleportEntity(physics, Pos, NULL_VECTOR, velocity);
				
				if(g_fTimeRemove > 0.0)
				{
					CreateTimer(g_fTimeRemove, Timer_RemoveProp, physics);
				}
			}
		}
		return Plugin_Stop;
	}
	
	return Plugin_Continue;
}

public Action Timer_RemoveProp(Handle timer, int entity)
{
	if(IsValidEntity(entity))
	{
		RemoveEntity(entity);
	}
	return Plugin_Stop;
}

void PrecacheParticle(const char[] sEffectName)
{
	static int table = INVALID_STRING_TABLE;
	if(table == INVALID_STRING_TABLE)
	{
		table = FindStringTable("ParticleEffectNames");
	}

	if(FindStringIndex(table, sEffectName) == INVALID_STRING_INDEX)
	{
		bool save = LockStringTables(false);
		AddToStringTable(table, sEffectName);
		LockStringTables(save);
	}
}

void ShowParticle(float Pos[3], char[] particlename)
{
	int particle = CreateEntityByName("info_particle_system");
	if(particle != -1)
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

bool IsValidEntRef(int iEntRef)
{
	return iEntRef != 0 && EntRefToEntIndex(iEntRef) != INVALID_ENT_REFERENCE;
}

bool IsValidClient(int client)
{
	return (1 <= client <= MaxClients && IsClientInGame(client));
}

// ============ CHAT COMMANDS ============

public Action Command_ChangeChance(int client, int args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: !tankpropchance <0.0 - 100.0>");
		ReplyToCommand(client, "[SM] Current value: %.1f%%", g_fModelChance);
		return Plugin_Handled;
	}
	
	char sArg[8];
	GetCmdArg(1, sArg, sizeof(sArg));
	float fValue = StringToFloat(sArg);
	
	if (fValue < 0.0 || fValue > 100.0)
	{
		ReplyToCommand(client, "[SM] Error: Value must be between 0.0 and 100.0");
		return Plugin_Handled;
	}
	
	g_cvChanceProp.FloatValue = fValue;
	g_fModelChance = fValue;
	ReplyToCommand(client, "[SM] Tank prop chance set to %.1f%%", fValue);
	
	return Plugin_Handled;
}

public Action Command_ChangeTime(int client, int args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: !tankproptime <0.0 - seconds>");
		ReplyToCommand(client, "[SM] Current value: %.1f seconds (0 = never remove)", g_fTimeRemove);
		return Plugin_Handled;
	}
	
	char sArg[8];
	GetCmdArg(1, sArg, sizeof(sArg));
	float fValue = StringToFloat(sArg);
	
	if (fValue < 0.0)
	{
		ReplyToCommand(client, "[SM] Error: Value must be 0.0 or higher");
		return Plugin_Handled;
	}
	
	g_cvTimeRemove.FloatValue = fValue;
	g_fTimeRemove = fValue;
	ReplyToCommand(client, "[SM] Tank prop remove time set to %.1f seconds", fValue);
	
	return Plugin_Handled;
}