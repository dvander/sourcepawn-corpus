#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#pragma semicolon				1
#pragma newdecls required

#define PLUGIN_VERSION 			"0.9.0"
#define TEST_DEBUG				0
#define TEST_DEBUG_LOG			1


#define PISTOL 					1
#define SMG 					2
#define PUMPSHOTGUN 			3
#define AUTOSHOTGUN 			4
#define RIFLE 					5
#define HUNTING_RIFLE 			6
#define SMG_SILENCED 			7
#define SHOTGUN_CHROME 			8
#define RIFLE_DESERT 			9
#define SNIPER_MILITARY 		10
#define SHOTGUN_SPAS 			11
#define MOLOTOV 				13
#define PIPE_BOMB 				14
#define VOMITJAR 				25
#define RIFLE_AK47 				26
#define PISTOL_MAGNUM 			32
#define SMG_MP5 				33
#define RIFLE_SG552 			34
#define SNIPER_AWP 				35
#define SNIPER_SCOUT 			36
//credits to Rectus https://steamcommunity.com/sharedfiles/filedetails/?id=924194917
#define VS_PRECACHEWEAPONS "local weapons = [\"weapon_rifle_sg552\", \"weapon_smg_mp5\", \"weapon_sniper_awp\", \"weapon_sniper_scout\"];foreach(weapon in weapons){PrecacheEntityFromTable({classname = weapon});};"

const float PLUGINSTART_DELAY		= 1.0;
const float ROUNDSTART_DELAY			= 6.0;
const float LOCATION_ERROR_MARGIN	= 4.0;

// chances weapons getting transformed into CSS brethren are 1:X - X being the value set here. 1:1 is 100%, 1:2 is 50%, 1:3 is 33%, 1:4 is 25%, 1:5 is 20%...
const SG552_LOTTERY_CHANCE			= 4;
const MP5_LOTTERY_CHANCE				= 3;
const AWP_LOTTERY_CHANCE				= 2;
const SCOUT_LOTTERY_CHANCE			= 2;

// other chances, again in 1:X format
const PISTOL_IS_MAGNUM_CHANCE		= 3;
const RIFLE_IS_DESERT_ED_CHANCE		= 3;
//const GRENADE_KEEPS_CLASS_CHANCE 	= 3;//default
const GRENADE_KEEPS_CLASS_CHANCE 	= 100;
const SPAS_IS_AUTOSHOTGUN_CHANCE 	= 2;
const PUMPSHOT_IS_CHROME_CHANCE		= 2;
const SMG_IS_SILENCED_CHANCE			= 2;


char VEC_ORIGIN_ENTPROP[] = "m_vecOrigin";
char ANG_ROTATION_ENTPROP[]	= "m_angRotation";
char WEAPON_ID_ENTPROP[]	= "m_weaponID";


static Handle cvarEnabled					= INVALID_HANDLE;
static Handle cvarAWPEnabled				= INVALID_HANDLE;
static Handle cvarMP5Enabled				= INVALID_HANDLE;
static Handle cvarScoutEnabled				= INVALID_HANDLE;
static Handle cvarSG552Enabled				= INVALID_HANDLE;

static WeaponSpawn_ID[64]					= 0;
static WeaponSpawn_IDMod[64]				= 0;
static float WeaponOrigin[64][3];
static float WeaponAngles[64][3];

static bool InitFinished					= false;
//Used to keep spawns the same for both teams on competitive modes.
static bool g_bNewMap						= false;
static bool g_bScavengeHalftime				= false;

forward void SRS_OnItemsHandled(bool justIndexed);

public Plugin myinfo =
{
	name = "[L4D2] Weapon Unlock",
	author = "Crimson_Fox & AtomicStryker & z",
	description = "Unlocks the hidden CSS weapons.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?p=1041458"
}

public void OnPluginStart()
{
	char game[16];
	GetGameFolderName(game, sizeof(game)); 	//Look up what game we're running, and don't load if it's not L4D2.
	if (!StrEqual(game, "left4dead2", false))
	{
		SetFailState("Plugin supports Left 4 Dead 2 only.");
	}
	
	//Set up cvars and event hooks.
	CreateConVar(					 "l4d2_weaponunlock", 	PLUGIN_VERSION, "Weapon Unlock version.", 				FCVAR_NONE|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	cvarEnabled = 		CreateConVar("l4d2_wu_enable", 		"1", 			"Is Weapon Unlock plug-in enabled?", 	FCVAR_NONE|FCVAR_DONTRECORD);
	cvarAWPEnabled = 	CreateConVar("l4d2_wu_awp", 		"1", 			"Enable AWP sniper rifle?", 			FCVAR_NONE);
	cvarMP5Enabled = 	CreateConVar("l4d2_wu_mp5", 		"1", 			"Enable MP5 submachine gun?", 			FCVAR_NONE);
	cvarScoutEnabled = 	CreateConVar("l4d2_wu_scout", 		"1", 			"Enable Scout sniper rifle?", 			FCVAR_NONE);
	cvarSG552Enabled = 	CreateConVar("l4d2_wu_sg552", 		"1", 			"Enable SG552 assault rifle?", 			FCVAR_NONE);
	
	AutoExecConfig(true, "l4d2_weaponunlock");
	
	HookEvent("round_start", Event_RoundStart);
	HookEvent("scavenge_round_halftime", Event_ScavengeRoundHalftime);
	
	HookConVarChange(cvarEnabled, ConVarChange_Enabled);
	
	//Precache hidden weapon models and initialize them after one second.
	PrecacheWeaponModels();
	CreateTimer(PLUGINSTART_DELAY, InitHiddenWeaponsDelayed);
}

public void ConVarChange_Enabled(Handle convar, const char[] oldValue, const char[] newValue)
{
	if ((StringToInt(oldValue) == 1) && (StringToInt(newValue) == 0))
	{
		RestoreWeaponSpawns();
	}
	if ((StringToInt(oldValue) == 0) && (StringToInt(newValue) == 1))
	{
		CreateTimer(ROUNDSTART_DELAY, RoundStartDelayed);
	}
}

public void OnMapStart()
{
	g_bNewMap = true;
	g_bScavengeHalftime = false;
	for (int i = 0; i < sizeof(WeaponSpawn_ID); i++)
	{
		WeaponSpawn_ID[i] = -1;
	}

}
public void OnEntityCreated(int entity, const char[] classname){

	if(g_bNewMap && strcmp(classname, "info_director") == 0)
		SDKHook(entity, SDKHook_SpawnPost, OnSpawnedDirector);
}

public void OnSpawnedDirector(int entity){
	if (entity > 0 && entity > MaxClients && IsValidEntity(entity)){
		//precache css weapons with VScript
		SetVariantString(VS_PRECACHEWEAPONS);
		AcceptEntityInput(entity, "RunScriptCode");
	}
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	if (!GetConVarBool(cvarEnabled)) return;
	CreateTimer(ROUNDSTART_DELAY, RoundStartDelayed);
}

public void SRS_OnItemsHandled(bool justIndexed)
{
	DebugPrintToAll("SRS_OnItemsHandled fired, justIndexed: %b", justIndexed);
	
	if (!GetConVarBool(cvarEnabled)
	|| !IsAllowedMap())
	{
		return;
	}

	if (justIndexed)
	{
		IndexWeaponSpawns();
	}

	SpawnIndexedWeapons();
}

static bool IsSRSMODactive()
{
	Handle cvar = FindConVar("srs_remove_enabled");
	if (cvar != INVALID_HANDLE)
	{
		if (GetConVarBool(cvar))
		{
			return true;
		}
	}
	return false;
}

static bool IsAllowedMap()
{
	char GameMode[16];
	GetConVarString(FindConVar("mp_gamemode"), GameMode, sizeof(GameMode));
	
	char Map[56];
	GetCurrentMap(Map, sizeof(Map));
	//If we're in a coop mode and running c4m1-4, don't modify spawns as it causes crashes on transitions.
	if (
	(StrEqual(GameMode, "coop") ||
	StrEqual(GameMode, "realism"))
	&&
	(StrEqual(Map, "c4m1_milltown_a") ||
	StrEqual(Map, "c4m2_sugarmill_a") ||
	StrEqual(Map, "c4m3_sugarmill_b") ||
	StrEqual(Map, "c4m4_milltown_b")))
	{
		return false;
	}
	
	return true;
}

public Action RoundStartDelayed(Handle timer)
{
	if (!InitFinished || !IsAllowedMap()) return;
	
	if (IsSRSMODactive())
	{
		DebugPrintToAll("Active srsmod Item Module found, aborting automatic Weapon exchange");
		return;
	}
	
	//Look up the map and type of game we're running.
	char GameMode[16];
	GetConVarString(FindConVar("mp_gamemode"), GameMode, sizeof(GameMode));
	
	if (StrEqual(GameMode, "survival"))
	{
		return;
	}
	
	if (StrEqual(GameMode, "scavenge"))
	{
		if (g_bScavengeHalftime)
		{
			g_bScavengeHalftime = false;
		}
		else
		{
			IndexWeaponSpawns();
		}
	}
	
	//if (StrEqual(GameMode, "versus") || StrEqual(GameMode, "teamversus") || StrEqual(GameMode, "mutation12"))
	if (g_bNewMap)
	{
		IndexWeaponSpawns();
		g_bNewMap = false;
	}
	
	SpawnIndexedWeapons();
}

public void Event_ScavengeRoundHalftime(Event event, const char[] name, bool dontBroadcast)
{
	g_bScavengeHalftime = true;
}

void IndexWeaponSpawns()
{
	//Search for dynamic weapon spawns,
	char EdictClassName[32];
	int count = 0;
	int entcount = GetEntityCount();
	for (int i = 32; i <= entcount; i++)
	{
		if (IsValidEdict(i))
		{
			GetEdictClassname(i, EdictClassName, sizeof(EdictClassName));
			if (StrEqual(EdictClassName, "weapon_spawn"))
			{
				//and record their position.
				GetEntPropVector(i, Prop_Send, VEC_ORIGIN_ENTPROP, WeaponOrigin[count]);
				GetEntPropVector(i, Prop_Send, ANG_ROTATION_ENTPROP, WeaponAngles[count]);
				WeaponSpawn_ID[count] = GetEntProp(i, Prop_Send, WEAPON_ID_ENTPROP);
				
				DebugPrintToAll("Indexed dynamic %s, spawnid %i, index %i - removing entid %i now", EdictClassName, WeaponSpawn_ID[count], count, i);
				RemoveEdict(i);
				
				count++;
			}
		}
	}
	
	//If dynamic spawns were found, and we're not running scavenge, modify the stored spawns like this:
	char GameMode[16];
	GetConVarString(FindConVar("mp_gamemode"), GameMode, sizeof(GameMode));
	if (!StrEqual(GameMode, "scavenge"))
	{
		for (int i = 0; i <= count; i++)
		{
			WeaponSpawn_IDMod[i] = WeaponSpawn_ID[i];
			switch(WeaponSpawn_ID[i])
			{
				case RIFLE_AK47: 		if ((GetConVarBool(cvarSG552Enabled)) && (GetRandomInt(1, SG552_LOTTERY_CHANCE) 	== 1)) WeaponSpawn_IDMod[i] = RIFLE_SG552;
				case SNIPER_MILITARY: 	if ((GetConVarBool(cvarAWPEnabled))   && (GetRandomInt(1, AWP_LOTTERY_CHANCE) 		== 1)) WeaponSpawn_IDMod[i] = SNIPER_AWP;
				case RIFLE_DESERT: 		if ((GetConVarBool(cvarSG552Enabled)) && (GetRandomInt(1, SG552_LOTTERY_CHANCE) 	== 1)) WeaponSpawn_IDMod[i] = RIFLE_SG552;
				case SMG_SILENCED: 		if ((GetConVarBool(cvarMP5Enabled))   && (GetRandomInt(1, MP5_LOTTERY_CHANCE) 		== 1)) WeaponSpawn_IDMod[i] = SMG_MP5;
				case HUNTING_RIFLE: 	if ((GetConVarBool(cvarScoutEnabled)) && (GetRandomInt(1, SCOUT_LOTTERY_CHANCE) 	== 1)) WeaponSpawn_IDMod[i] = SNIPER_SCOUT;
				case RIFLE: 			if ((GetConVarBool(cvarSG552Enabled)) && (GetRandomInt(1, SG552_LOTTERY_CHANCE) 	== 1)) WeaponSpawn_IDMod[i] = RIFLE_SG552;
				case SMG: 				if ((GetConVarBool(cvarMP5Enabled))   && (GetRandomInt(1, MP5_LOTTERY_CHANCE) 		== 1)) WeaponSpawn_IDMod[i] = SMG_MP5;
			}
		}
	}
	//Otherwise, search for static spawns,
	else
	{
		int dynamiccount = count;
		
		for (int i = 32; i <= entcount; i++)
		{
			if (IsValidEdict(i))
			{
				GetEdictClassname(i, EdictClassName, sizeof(EdictClassName));
				if (IsWantedGunEntity(EdictClassName))
				{
					//and record their position.
					GetEntPropVector(i, Prop_Send, VEC_ORIGIN_ENTPROP, WeaponOrigin[count]);
					GetEntPropVector(i, Prop_Send, ANG_ROTATION_ENTPROP, WeaponAngles[count]);
					WeaponSpawn_ID[count] = GetEntProp(i, Prop_Send, WEAPON_ID_ENTPROP);
					
					DebugPrintToAll("Indexed static %s, spawnid %i, index %i - removing entid %i now", EdictClassName, WeaponSpawn_ID[count], count, i);
					RemoveEdict(i);
					
					count++;
				}
			}
		}
		//and modify them like this:
		for (int i = dynamiccount; i <= count; i++)
		{
			WeaponSpawn_IDMod[i] = WeaponSpawn_ID[i];
			switch(WeaponSpawn_ID[i])
			{
				case PISTOL_MAGNUM:
				if (GetRandomInt(1, PISTOL_IS_MAGNUM_CHANCE) == 1) 
				{
					WeaponSpawn_IDMod[i] = PISTOL;
				}
				case RIFLE_AK47:
				if (GetConVarBool(cvarSG552Enabled))
				{
					switch(GetRandomInt(1, SG552_LOTTERY_CHANCE))
					{
						case 3: WeaponSpawn_IDMod[i] = RIFLE;
						case 2: WeaponSpawn_IDMod[i] = RIFLE_DESERT;
						case 1: WeaponSpawn_IDMod[i] = RIFLE_SG552;
					}
				}
				else
				{
					switch(GetRandomInt(1, RIFLE_IS_DESERT_ED_CHANCE) == 1) 
					{
						case 2: WeaponSpawn_IDMod[i] = RIFLE;
						case 1: WeaponSpawn_IDMod[i] = RIFLE_DESERT;
					}
				}
				case VOMITJAR:
				switch(GetRandomInt(1, GRENADE_KEEPS_CLASS_CHANCE))
				{
					case 2: WeaponSpawn_IDMod[i] = PIPE_BOMB;
					case 1: WeaponSpawn_IDMod[i] = MOLOTOV;
				}
				case PIPE_BOMB:
				switch(GetRandomInt(1, GRENADE_KEEPS_CLASS_CHANCE))
				{
					case 2: WeaponSpawn_IDMod[i] = MOLOTOV;
					case 1: WeaponSpawn_IDMod[i] = VOMITJAR;
				}
				case MOLOTOV:
				switch(GetRandomInt(1, GRENADE_KEEPS_CLASS_CHANCE))
				{
					case 2: WeaponSpawn_IDMod[i] = VOMITJAR;
					case 1: WeaponSpawn_IDMod[i] = PIPE_BOMB;
				}
				case SHOTGUN_SPAS: 
				if (GetRandomInt(1, SPAS_IS_AUTOSHOTGUN_CHANCE) == 1)
				{
					WeaponSpawn_IDMod[i] = AUTOSHOTGUN;
				}
				case SNIPER_MILITARY:
				if ((GetConVarBool(cvarAWPEnabled)) && (GetRandomInt(1, AWP_LOTTERY_CHANCE) == 1))
				{
					WeaponSpawn_IDMod[i] = SNIPER_AWP;
				}
				case RIFLE_DESERT:
				if (GetConVarBool(cvarSG552Enabled))
				{
					switch(GetRandomInt(1, SG552_LOTTERY_CHANCE))
					{
						case 3: WeaponSpawn_IDMod[i] = RIFLE;
						case 2: WeaponSpawn_IDMod[i] = RIFLE_AK47;
						case 1: WeaponSpawn_IDMod[i] = RIFLE_SG552;
					}
				}
				else
				{
					switch(GetRandomInt(1, RIFLE_IS_DESERT_ED_CHANCE) == 1) 
					{
						case 2: WeaponSpawn_IDMod[i] = RIFLE;
						case 1: WeaponSpawn_IDMod[i] = RIFLE_AK47;
					}
				}
				case SHOTGUN_CHROME:
				if (GetRandomInt(1, PUMPSHOT_IS_CHROME_CHANCE) == 1) 
				{
					WeaponSpawn_IDMod[i] = PUMPSHOTGUN;
				}
				case SMG_SILENCED:
				if (GetConVarBool(cvarMP5Enabled))
				{
					switch(GetRandomInt(1, MP5_LOTTERY_CHANCE))
					{
						case 2: WeaponSpawn_IDMod[i] = SMG;
						case 1: WeaponSpawn_IDMod[i] = SMG_MP5;
					}
				}
				else if (GetRandomInt(1, SMG_IS_SILENCED_CHANCE) == 1)
				{
					WeaponSpawn_IDMod[i] = SMG;
				}
				//Since the hunting rifle is a T1 weapon in L4D2, we'll upgrade it to a T2 sniper rifle for L4D1 maps.
				case HUNTING_RIFLE:
				if (GetConVarBool(cvarAWPEnabled))
				{
					switch(GetRandomInt(1, AWP_LOTTERY_CHANCE))
					{
						case 2: WeaponSpawn_IDMod[i] = SNIPER_MILITARY;
						case 1: WeaponSpawn_IDMod[i] = SNIPER_AWP;
					}
				}
				else WeaponSpawn_IDMod[i] = SNIPER_MILITARY;
				case RIFLE:
				if (GetConVarBool(cvarSG552Enabled))
				{
					switch(GetRandomInt(1, SG552_LOTTERY_CHANCE))
					{
						case 3: WeaponSpawn_IDMod[i] = RIFLE_AK47;
						case 2: WeaponSpawn_IDMod[i] = RIFLE_DESERT;
						case 1: WeaponSpawn_IDMod[i] = RIFLE_SG552;
					}
				}
				else
				{
					switch(GetRandomInt(1, RIFLE_IS_DESERT_ED_CHANCE) == 1) 
					{
						case 2: WeaponSpawn_IDMod[i] = RIFLE_AK47;
						case 1: WeaponSpawn_IDMod[i] = RIFLE_DESERT;
					}
				}
				case AUTOSHOTGUN:
				if (GetRandomInt(1, SPAS_IS_AUTOSHOTGUN_CHANCE) == 1)
				{
					WeaponSpawn_IDMod[i] = SHOTGUN_SPAS;
				}
				case PUMPSHOTGUN:
				if (GetRandomInt(1, PUMPSHOT_IS_CHROME_CHANCE) == 1)
				{
					WeaponSpawn_IDMod[i] = SHOTGUN_CHROME;
				}
				case SMG:
				if (GetConVarBool(cvarMP5Enabled))
				{
					switch(GetRandomInt(1, MP5_LOTTERY_CHANCE))
					{
						case 2: WeaponSpawn_IDMod[i] = SMG_SILENCED;
						case 1: WeaponSpawn_IDMod[i] = SMG_MP5;
					}
				}
				else if (GetRandomInt(1, SMG_IS_SILENCED_CHANCE) == 1)
				{
					WeaponSpawn_IDMod[i] = SMG_SILENCED;
				}
				case PISTOL:
				if (GetRandomInt(1, PISTOL_IS_MAGNUM_CHANCE) == 1)
				{
					WeaponSpawn_IDMod[i] = PISTOL_MAGNUM;
				}
			}
		}
	}
}

void SetModelForWeaponId(int weaponent, int id)
{
	switch(id)
	{
		case SNIPER_SCOUT: 		SetEntityModel(weaponent, "models/w_models/weapons/w_sniper_scout.mdl");
		case SNIPER_AWP: 		SetEntityModel(weaponent, "models/w_models/weapons/w_sniper_awp.mdl");
		case RIFLE_SG552: 		SetEntityModel(weaponent, "models/w_models/weapons/w_rifle_sg552.mdl");
		case SMG_MP5: 			SetEntityModel(weaponent, "models/w_models/weapons/w_smg_mp5.mdl");
		case PISTOL_MAGNUM: 	SetEntityModel(weaponent, "models/w_models/weapons/w_desert_eagle.mdl");
		case RIFLE_AK47: 		SetEntityModel(weaponent, "models/w_models/weapons/w_rifle_ak47.mdl");
		case VOMITJAR: 			SetEntityModel(weaponent, "models/w_models/weapons/w_eq_bile_flask.mdl");
		case PIPE_BOMB: 		SetEntityModel(weaponent, "models/w_models/weapons/w_eq_pipebomb.mdl");
		case MOLOTOV: 			SetEntityModel(weaponent, "models/w_models/weapons/w_eq_molotov.mdl");
		case SHOTGUN_SPAS: 		SetEntityModel(weaponent, "models/w_models/weapons/w_shotgun_spas.mdl");
		case SNIPER_MILITARY: 	SetEntityModel(weaponent, "models/w_models/weapons/w_sniper_military.mdl");
		case RIFLE_DESERT: 		SetEntityModel(weaponent, "models/w_models/weapons/w_desert_rifle.mdl");
		case SHOTGUN_CHROME:	SetEntityModel(weaponent, "models/w_models/weapons/w_pumpshotgun_a.mdl");
		case SMG_SILENCED: 		SetEntityModel(weaponent, "models/w_models/weapons/w_smg_a.mdl");
		case HUNTING_RIFLE: 	SetEntityModel(weaponent, "models/w_models/weapons/w_sniper_mini14.mdl");
		case RIFLE: 			SetEntityModel(weaponent, "models/w_models/weapons/w_rifle_m16a2.mdl");
		case AUTOSHOTGUN: 		SetEntityModel(weaponent, "models/w_models/weapons/w_autoshot_m4super.mdl");
		case PUMPSHOTGUN: 		SetEntityModel(weaponent, "models/w_models/weapons/w_shotgun.mdl");
		case SMG: 				SetEntityModel(weaponent, "models/w_models/weapons/w_smg_uzi.mdl");
		case PISTOL: 			SetEntityModel(weaponent, "models/w_models/weapons/w_pistol_a.mdl");
	}
}

void SpawnIndexedWeapons()
{
	PrecacheWeaponModels();
	WipeStoredWeapons();
	
	DebugPrintToAll("Commencing to spawn indexed weapons now");
	
	int spawnedent;
	
	for (int i = 0; i < sizeof(WeaponSpawn_ID); i++)
	{
		if (WeaponSpawn_ID[i] == -1) break;
		
		spawnedent = CreateEntityByName("weapon_spawn");
		SetModelForWeaponId(spawnedent, WeaponSpawn_IDMod[i]);
		SetEntProp(spawnedent, Prop_Send, WEAPON_ID_ENTPROP, WeaponSpawn_IDMod[i]);
		TeleportEntity(spawnedent, WeaponOrigin[i], WeaponAngles[i], NULL_VECTOR);
		
		if (
		WeaponSpawn_IDMod[i] == VOMITJAR ||
		WeaponSpawn_IDMod[i] == PIPE_BOMB ||
		WeaponSpawn_IDMod[i] == MOLOTOV)
		{
			DispatchKeyValue(spawnedent, "count", "1");
		}
		else
		{
			DispatchKeyValue(spawnedent, "count", "4");
		}
		
		DebugPrintToAll("Spawning indexed gun %i, int ent %i, original id %i, modid %i", i, spawnedent, WeaponSpawn_ID[i], WeaponSpawn_IDMod[i]);
		DispatchSpawn(spawnedent);
	}
	
	DebugPrintToAll("Finished Spawning indexed weapons");
}

void WipeStoredWeapons()
{
	DebugPrintToAll("WipeStoredWeapons() was called. Removing stored Weapon Spawns on map");
	
	char GameMode[16];
	GetConVarString(FindConVar("mp_gamemode"), GameMode, sizeof(GameMode));
	bool wipestaticspawns = (StrEqual(GameMode, "scavenge"));
	if (wipestaticspawns) DebugPrintToAll("Gamemode is Scavenge, also wiping static Spawns");
	
	int entcount = GetEntityCount();
	char EdictClassName[64];
	float origin[3];
	
	for (int i = 32; i <= entcount; i++)
	{
		if (IsValidEdict(i) && IsValidEntity(i)) // because people still got me logs of "Is invalid edict" after IsValidEdict ... WTFFFF
		{
			GetEdictClassname(i, EdictClassName, sizeof(EdictClassName));
			if (StrEqual(EdictClassName, "weapon_spawn") || (wipestaticspawns && IsWantedGunEntity(EdictClassName)))
			{
				GetEntPropVector(i, Prop_Send, VEC_ORIGIN_ENTPROP, origin);
				if (IsIndexedOrigin(origin))
				{
					DebugPrintToAll("WipeStoredWeapons: About to wipe ent %i of class %s", i, EdictClassName);
					RemoveEdict(i);
				}
			}
		}
	}
}

static bool IsIndexedOrigin(float origin[3])
{
	for (int i = 0; i < sizeof(WeaponSpawn_ID); i++)
	{
		if (WeaponSpawn_ID[i] == -1) break;
		
		if (origin[0] >= WeaponOrigin[i][0] - LOCATION_ERROR_MARGIN && origin[0] <= WeaponOrigin[i][0] + LOCATION_ERROR_MARGIN
		&& origin[1] >= WeaponOrigin[i][1] - LOCATION_ERROR_MARGIN && origin[1] <= WeaponOrigin[i][1] + LOCATION_ERROR_MARGIN
		&& origin[2] >= WeaponOrigin[i][2] - LOCATION_ERROR_MARGIN && origin[2] <= WeaponOrigin[i][2] + LOCATION_ERROR_MARGIN)
		{
			return true;
		}
	}
	return false;
}

bool IsWantedGunEntity(const char[] EdictClassName)
{
	return (
	StrEqual(EdictClassName, "weapon_spawn") ||
	StrEqual(EdictClassName, "weapon_autoshotgun_spawn") ||
	StrEqual(EdictClassName, "weapon_hunting_rifle_spawn") ||
	StrEqual(EdictClassName, "weapon_molotov_spawn") ||
	StrEqual(EdictClassName, "weapon_pipe_bomb_spawn") ||
	StrEqual(EdictClassName, "weapon_pistol_magnum_spawn") ||
	StrEqual(EdictClassName, "weapon_pistol_spawn") ||
	StrEqual(EdictClassName, "weapon_pumpshotgun_spawn") ||
	StrEqual(EdictClassName, "weapon_rifle_ak47_spawn") ||
	StrEqual(EdictClassName, "weapon_rifle_desert_spawn") ||
	StrEqual(EdictClassName, "weapon_rifle_spawn") ||
	StrEqual(EdictClassName, "weapon_shotgun_chrome_spawn") ||
	StrEqual(EdictClassName, "weapon_shotgun_spas_spawn") ||
	StrEqual(EdictClassName, "weapon_smg_spawn") ||
	StrEqual(EdictClassName, "weapon_smg_silenced_spawn") ||
	StrEqual(EdictClassName, "weapon_sniper_military_spawn") ||
	StrEqual(EdictClassName, "weapon_vomitjar_spawn"));
}

void RestoreWeaponSpawns()
{
	WipeStoredWeapons();
	
	DebugPrintToAll("Commencing to restore default indexed weapons now");
	
	int spawnedent;
	
	for (int i = 0; i < sizeof(WeaponSpawn_ID); i++)
	{
		if (WeaponSpawn_ID[i] == -1) break;
		
		spawnedent = CreateEntityByName("weapon_spawn");
		SetModelForWeaponId(spawnedent, WeaponSpawn_ID[i]);
		SetEntProp(spawnedent, Prop_Send, WEAPON_ID_ENTPROP, WeaponSpawn_ID[i]);
		TeleportEntity(spawnedent, WeaponOrigin[i], WeaponAngles[i], NULL_VECTOR);
		
		if (
		WeaponSpawn_IDMod[i] == VOMITJAR ||
		WeaponSpawn_IDMod[i] == PIPE_BOMB ||
		WeaponSpawn_IDMod[i] == MOLOTOV)
		{
			DispatchKeyValue(spawnedent, "count", "1");
		}
		else
		{
			DispatchKeyValue(spawnedent, "count", "4");
		}
		
		DebugPrintToAll("Spawning default indexed gun %i, int ent %i, original id %i, unused modid %i", i, spawnedent, WeaponSpawn_ID[i], WeaponSpawn_IDMod[i]);
		DispatchSpawn(spawnedent);
	}
	
	DebugPrintToAll("Finished Spawning default indexed weapons");
}

void PrecacheWeaponModels()
{
	//Precache weapon models if they're not loaded.
	CheckModelPreCache("models/w_models/weapons/w_rifle_sg552.mdl");
	CheckModelPreCache("models/w_models/weapons/w_smg_mp5.mdl");
	CheckModelPreCache("models/w_models/weapons/w_sniper_awp.mdl");
	CheckModelPreCache("models/w_models/weapons/w_sniper_scout.mdl");
	CheckModelPreCache("models/w_models/weapons/w_eq_bile_flask.mdl");
	CheckModelPreCache("models/v_models/v_rif_sg552.mdl");
	CheckModelPreCache("models/v_models/v_smg_mp5.mdl");
	CheckModelPreCache("models/v_models/v_snip_awp.mdl");
	CheckModelPreCache("models/v_models/v_snip_scout.mdl");
	CheckModelPreCache("models/v_models/v_bile_flask.mdl");
	CheckModelPreCache("models/w_models/weapons/w_m60.mdl");
	CheckModelPreCache("models/v_models/v_m60.mdl");
}

stock void CheckModelPreCache(const char[] Modelfile)
{
	if (!IsModelPrecached(Modelfile))
	{
		PrecacheModel(Modelfile);
	}
}

public Action InitHiddenWeaponsDelayed(Handle timer)
{
	//Spawn and delete the hidden weapons,
	L4D2_RunScript(VS_PRECACHEWEAPONS);
	InitFinished = true;
	char Map[56];
	GetCurrentMap(Map, sizeof(Map));
	ForceChangeLevel(Map, "Hidden weapon initialization.");
}

stock void DebugPrintToAll(const char[] format, any ...)
{
	#if (TEST_DEBUG || TEST_DEBUG_LOG)
	char buffer[256];
	
	VFormat(buffer, sizeof(buffer), format, 2);
	
	#if TEST_DEBUG
	PrintToChatAll("[GUNUNLOCK] %s", buffer);
	PrintToConsole(0, "[GUNUNLOCK] %s", buffer);
	#endif
	
	LogMessage("%s", buffer);
	#else
	//suppress "format" never used warning
	if(format[0])
		return;
	else
	return;
	#endif
}

stock void L4D2_RunScript(const char[] sCode, any ...) {

	/**
	* Run a VScript (Credit to Timocop)
	*
	* @param sCode		Magic
	* @return void
	*/

	static int iScriptLogic = INVALID_ENT_REFERENCE;
	if(iScriptLogic == INVALID_ENT_REFERENCE || !IsValidEntity(iScriptLogic)) {
		iScriptLogic = EntIndexToEntRef(CreateEntityByName("logic_script"));

		if(iScriptLogic == INVALID_ENT_REFERENCE || !IsValidEntity(iScriptLogic)) {
			SetFailState("Could not create 'logic_script'");
		}
		DispatchSpawn(iScriptLogic);
	}

	char sBuffer[512];
	VFormat(sBuffer, sizeof(sBuffer), sCode, 2);
	SetVariantString(sBuffer);
	AcceptEntityInput(iScriptLogic, "RunScriptCode");
}