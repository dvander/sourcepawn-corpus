#pragma semicolon 1
#include <sourcemod> 
#include <sdktools> 
#include <sdktools_functions>
#include "sceneprocessor" 
#define PLUGIN_VERSION		"1.0"
#define ZOEY_MODEL_INDEX 365

#define MAX_ENTITIES 4096
static const String:MODEL_ZOEY[] 		= "models/survivors/survivor_teenangst.mdl";

static bool:g_bIsRescuePoint[MAX_ENTITIES + 1];
static bool:g_bIsClientZoey[MAXPLAYERS+1];

public Plugin:myinfo =  
{ 
	name = "[L4D2] Zoey Vocalization", 
	author = "DeathChaos", 
	description = "Players using Zoey's character model will have Zoey's voice whenever they use the vocalize command.", 
	version = PLUGIN_VERSION,
}

public OnPluginStart()
{
	AddNormalSoundHook(RescueCallOut_SoundHook);
	HookEvent("weapon_reload", Event_WeaponReload);
}

public OnEntityCreated(entity, const String:classname[])
{
	if (entity <= 0 || entity > MAX_ENTITIES)
	{
		return;
	}
	
	if (StrEqual(classname, "info_survivor_rescue"))
	{
		g_bIsRescuePoint[entity] = true;
	}
	
}

public OnEntityDestroyed(entity)
{
	if (entity <= 0 || entity > MAX_ENTITIES)
	{
		return;
	}
	
	g_bIsRescuePoint[entity] = false;
}

public Action:RescueCallOut_SoundHook(clients[64], &numClients, String:sample[PLATFORM_MAX_PATH], &entity, &channel, &Float:volume, &level, &pitch, &flags)
{
	if (entity <= 0 || entity > MAX_ENTITIES)
	{
		return Plugin_Continue;
	}
	
	if (g_bIsRescuePoint[entity] && StrContains(sample, "gambler\\CallForRescue", false) != -1)
	{
		new owner = GetEntPropEnt(entity, Prop_Send, "m_survivor");
		if (owner > 0 && owner <= MaxClients && g_bIsClientZoey[owner])
		{
			IsEntityZoey(entity);
			decl String:newSample[PLATFORM_MAX_PATH];
			decl String:fileSample[PLATFORM_MAX_PATH];
			decl sceneNumber;
			for (new i = 0; i < 50; i++)
			{
				sceneNumber = GetRandomInt(1, 15);
				Format(newSample, PLATFORM_MAX_PATH, "player\\survivor\\voice\\teengirl\\callforrescue%s%d.wav", (sceneNumber < 10 ? "0" : ""), sceneNumber);
				Format(fileSample, PLATFORM_MAX_PATH, "sound\\%s", newSample);
				
				if (!FileExists(fileSample, true))
				{
					continue;
				}
				
				new Handle:pack = CreateDataPack();
				WritePackCell(pack, entity);
				WritePackCell(pack, level);
				WritePackCell(pack, channel);
				WritePackCell(pack, flags);
				WritePackCell(pack, pitch);
				WritePackFloat(pack, volume);
				WritePackString(pack, newSample);
				CreateTimer(0.0, OnRescueCallOut_Timer, pack, TIMER_FLAG_NO_MAPCHANGE | TIMER_DATA_HNDL_CLOSE);
				break;
			}
			
			volume = 0.0;
			return Plugin_Changed;
		}
	}
	
	return Plugin_Continue;
}

public Action:OnRescueCallOut_Timer(Handle:timer, Handle:pack)
{
	ResetPack(pack);
	new entity = ReadPackCell(pack);
	new level = ReadPackCell(pack);
	new channel = ReadPackCell(pack);
	new flags = ReadPackCell(pack);
	new pitch = ReadPackCell(pack);
	new Float:volume = ReadPackFloat(pack);
	decl String:sample[PLATFORM_MAX_PATH];
	ReadPackString(pack, sample, PLATFORM_MAX_PATH);
	
	if (!IsSoundPrecached(sample))
	{
		PrecacheSound(sample, true);
	}
	
	EmitSoundToAll(sample, entity, channel, level, flags, volume, pitch);
	return Plugin_Stop;
}  

stock bool:IsSurvivor(client)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2)
	{
		return true;
	}
	return false;
}
stock bool:IsFakeZoey(client)
{
	if (IsSurvivor(client))
	{
		new character = GetEntProp(client, Prop_Send, "m_survivorCharacter");
		if (character == 0)
		{
			decl String:model[42];
			GetEntPropString(client, Prop_Data, "m_ModelName", model, sizeof(model));
			if (StrEqual(model, MODEL_ZOEY, false))
			{
				return true;
			}
		}
	}
	return false;
}

stock bool:IsEntityZoey(entity)
{
	decl String:modelname[PLATFORM_MAX_PATH];
	GetEntPropString(entity, Prop_Data, "m_ModelName", modelname, sizeof(modelname));
	if (StrEqual(modelname, MODEL_ZOEY))
	{
		return true;
	}
	return false;
}  

public Event_WeaponReload(Handle:event, const String:name[], bool:dontBroadcast)
{
	for (new i = 1; i < MAXPLAYERS; i++)
	{
		if (IsSurvivor(i) && IsFakeZoey(i))
		{
			g_bIsClientZoey[i] = true;
		}
	}
}