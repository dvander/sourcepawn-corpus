#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define VERSION "1.0"

public Plugin:myinfo =
{
	name = "Fun Projectiles",
	author = "Aurora",
	description = "Fun filled kaboooom!",
	version = VERSION,
	url = "http://uno-gamer.com"
};

/*

	Example keyvalues config:
	
	"FunProjectiles"
	{
		"ghost"
		{
			"model"		"models/props_halloween/ghost_no_hat.mdl"
			"sounds"
			{
				"1"		"vo/halloween_scream1.wav"
				"2"		"vo/halloween_scream2.wav"
				"3"		"vo/halloween_scream3.wav"
				"4"		"vo/halloween_scream4.wav"
				"5"		"vo/halloween_scream5.wav"
				"6"		"vo/halloween_scream6.wav"
				"7"		"vo/halloween_scream7.wav"
			}
			"chance"	"100"
			"projectiles"
			{
				"1"		"tf_projectile_rocket"
				"2"		"tf_projectile_sentryrocket"
			}
		}
	}

*/

//This stuff will store the lists of things.
new Handle:g_hSounds = INVALID_HANDLE;
new Handle:g_hProjectiles = INVALID_HANDLE;

//This stuff will store the singular config stuff
new String:g_sModel[PLATFORM_MAX_PATH];
new g_iChance;

//The path to the config will go here
new String:g_sFileDir[PLATFORM_MAX_PATH];

//The convar for which config to use.
new Handle:g_hConfigVar = INVALID_HANDLE;

public OnPluginStart()
{
	//Build the path to the config!
	BuildPath(Path_SM, g_sFileDir, sizeof(g_sFileDir), "configs/funprojectiles.cfg");
	
	//Cvar's
	g_hConfigVar = CreateConVar("sm_funprojectiles_config", "ghost", "The convar which allows you to select which projectiles config to use.");
	CreateConVar("sm_funprojectiles_version", VERSION, "Plugin Version", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	//Set up arrays
	g_hSounds = CreateArray(PLATFORM_MAX_PATH);
	g_hProjectiles = CreateArray(PLATFORM_MAX_PATH);
	
	HookConVarChange(g_hConfigVar, OnConfigChange);
	
	ReloadConfiguration();
}

public OnMapStart()
{
	PrecacheModel(g_sModel);
}

public OnConfigChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	ReloadConfiguration();
}

stock ReloadConfiguration()
{
	//Clear arrays
	ClearArray(g_hSounds);
	ClearArray(g_hProjectiles);
	
	//Re-populate them!
	new Handle:kv = CreateKeyValues("FunProjectiles");
	FileToKeyValues(kv, g_sFileDir);
	
	decl String:config[64];
	GetConVarString(g_hConfigVar, config, sizeof(config));
	
	if (!KvJumpToKey(kv, config))
	{
		return;
	}
	
	KvGetString(kv, "model", g_sModel, sizeof(g_sModel), "");
	PrecacheModel(g_sModel);
	g_iChance = KvGetNum(kv, "chance", 100);
	
	//PrintToChatAll("Model: %s, Chance: %d", g_sModel, g_iChance);

	if(KvJumpToKey(kv, "sounds"))
	{
		if(KvGotoFirstSubKey(kv, false))
		{
			//PrintToChatAll("We got to the first sub key!");
			PopulateSounds(kv);
			KvGoBack(kv);
		}
	}
	
	KvGoBack(kv);
	
	if(KvJumpToKey(kv, "projectiles"))
	{
		if(KvGotoFirstSubKey(kv, false))
		{
			PopulateProjectiles(kv);
			KvGoBack(kv);
		}
	}
	
	CloseHandle(kv);
}

stock PopulateSounds(Handle:kv)
{
	do
	{
		decl String:sound[PLATFORM_MAX_PATH];
		KvGetString(kv, NULL_STRING, sound, sizeof(sound));
		PushArrayString(g_hSounds, sound);
		//PrintToChatAll("Sound: %s", sound);
	} while (KvGotoNextKey(kv, false));
}

stock PopulateProjectiles(Handle:kv)
{
	do
	{
		decl String:projectile[PLATFORM_MAX_PATH];
		KvGetString(kv, NULL_STRING, projectile, sizeof(projectile));
		PushArrayString(g_hProjectiles, projectile);
		//PrintToChatAll("Projectile: %s", projectile);
	} while (KvGotoNextKey(kv, false));
}

public OnEntityCreated(entity, const String:classname[])
{
	if (!IsValidEdict(entity))
		return;
	
	if (FindStringInArray(g_hProjectiles, classname) != -1)
	{
		new chance = GetRandomInt(0, 100);
		//PrintToChatAll("Chance: %d | Set Chance: %d", chance, g_iChance);
		if(chance > g_iChance)
			return;
		//PrintToChatAll("Hooking Projectile!");
		SDKHook(entity, SDKHook_SpawnPost, OnProjectileSpawned);
	}
}

public OnProjectileSpawned(entity)
{
	new Float:mins[3], Float:maxs[3];
	GetEntPropVector(entity,Prop_Send,"m_vecMins",mins);
	GetEntPropVector(entity,Prop_Send,"m_vecMaxs",maxs);
	
	//PrintToChatAll(m_ModelName);
	SetEntityModel(entity, g_sModel);
	
	SetEntPropVector(entity,Prop_Send,"m_vecMins",mins);
	SetEntPropVector(entity,Prop_Send,"m_vecMaxs",maxs);
	
	if(GetArraySize(g_hSounds) > 0)
	{
		new noise = GetRandomInt(0, GetArraySize(g_hSounds)-1);
		decl String:sound[PLATFORM_MAX_PATH];
		GetArrayString(g_hSounds, noise, sound, sizeof(sound));
		PrecacheSound(sound);
		EmitSoundToAll(sound, entity);
	}
}