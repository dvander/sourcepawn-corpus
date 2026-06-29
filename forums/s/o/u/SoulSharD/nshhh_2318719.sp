#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define PLUGIN_VERSION		"1.0.2"

////
#define SOUND_HAMMER		"misc/halloween/strongman_fast_impact_01.wav"
#define MODEL_HAMMER		"models/weapons/c_models/c_big_mallet/c_big_mallet.mdl"
////

new Handle:g_hEnable = INVALID_HANDLE;
new bool:gDoomsday = false;

public Plugin:myinfo = 
{
	name = "Necro Smasher Horsemann",
	author = "SoulSharD",
	description = "Enables the Necro Smasher Horsemann featured in Scream Fortress 2014",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net"
};

public OnPluginStart()
{
	CreateConVar("sm_nsh_version", PLUGIN_VERSION, "Necro Smashin' Horsemann version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_CHEAT|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_hEnable = CreateConVar("sm_nsh_enable", "1.0", "The chance the Horsemann will spawn with a Necro Smasher. (0.0 - 1.0)");
	AddNormalSoundHook(NormalSoundHook);
}

public OnMapStart()
{
	decl String:strMap[64];
	GetCurrentMap(strMap, sizeof(strMap));
	if(StrEqual(strMap, "sd_doomsday_event", true)) {
		gDoomsday = true;
	} else {
		gDoomsday = false;
	}
	
	PrecacheModel(MODEL_HAMMER);
	PrecacheSound(SOUND_HAMMER);
}

public Action:NormalSoundHook(clients[64], &numClients, String:strSound[PLATFORM_MAX_PATH], &entity, &channel, &Float:volume, &level, &pitch, &flags)
{
	if(StrContains(strSound, "weapons/halloween_boss/knight_axe") != -1)
	{
		new weapon = GetEntPropEnt(entity, Prop_Send, "m_hActiveWeapon");
		if(weapon != INVALID_ENT_REFERENCE)
		{
			decl String:strModel[PLATFORM_MAX_PATH];
			GetEntPropString(weapon, Prop_Data, "m_ModelName", strModel, sizeof(strModel));
			if(StrEqual(strModel, MODEL_HAMMER, false))
			{
				new Float:vecOrigin[3];
				GetEntPropVector(entity, Prop_Send, "m_vecOrigin", vecOrigin);
				
				CreateDustEffect(vecOrigin);
				Format(strSound, sizeof(strSound), SOUND_HAMMER);
				return Plugin_Changed;
			}
		}
	}
	return Plugin_Continue;
}

public OnEntityCreated(entity, const String:strClassname[])
{
	if(!gDoomsday) 
	{
		if(StrEqual(strClassname, "prop_dynamic", false)) {
			RequestFrame(OnPropSpawn, EntIndexToEntRef(entity));
		}
	}
}

public OnPropSpawn(any:ref)
{
	new entity = EntRefToEntIndex(ref);
	if(IsValidEdict(entity))
	{
		new parent = GetEntPropEnt(entity, Prop_Data, "m_pParent");
		if(IsValidEdict(parent))
		{
			decl String:strClassname[64];
			GetEntityClassname(parent, strClassname, sizeof(strClassname));
			if(StrEqual(strClassname, "headless_hatman", false))
			{
				if(GetRandomFloat(0.0, 1.0) <= GetConVarFloat(g_hEnable))
				{
					SetEntityModel(entity, MODEL_HAMMER);
					SetEntPropEnt(parent, Prop_Send, "m_hActiveWeapon", entity); // It's alright, Valve. I'll do it for you.
				}
			}
		}
	}
}

CreateDustEffect(Float:vecOrigin[3])
{
	new particle = CreateEntityByName("info_particle_system");
	if(IsValidEdict(particle))
	{
		DispatchKeyValue(particle, "effect_name", "hammer_impact_button");
		
		DispatchSpawn(particle);
		ActivateEntity(particle);
		TeleportEntity(particle, vecOrigin, NULL_VECTOR, NULL_VECTOR);
		
		AcceptEntityInput(particle, "Start");
		CreateTimer(1.0, DeleteParticle, EntIndexToEntRef(particle));
	}
}

public Action:DeleteParticle(Handle:timer, any:entity)
{
	if(entity != INVALID_ENT_REFERENCE) {
		AcceptEntityInput(entity, "Kill");
	}
	return Plugin_Stop;
}