#include <sourcemod>
#include <sdktools>
#pragma semicolon				1


#define PLUGIN_VERSION 			"0.8.9"
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


static const Float:PLUGINSTART_DELAY		= 1.0;
static const Float:ROUNDSTART_DELAY			= 6.0;
static const Float:LOCATION_ERROR_MARGIN	= 4.0;

// chances weapons getting transformed into CSS brethren are 1:X - X being the value set here. 1:1 is 100%, 1:2 is 50%, 1:3 is 33%, 1:4 is 25%, 1:5 is 20%...
static const SG552_LOTTERY_CHANCE			= 4;
static const MP5_LOTTERY_CHANCE				= 3;
static const AWP_LOTTERY_CHANCE				= 2;
static const SCOUT_LOTTERY_CHANCE			= 2;

// other chances, again in 1:X format
static const PISTOL_IS_MAGNUM_CHANCE		= 3;
static const RIFLE_IS_DESERT_ED_CHANCE		= 3;
static const GRENADE_KEEPS_CLASS_CHANCE 	= 3;
static const SPAS_IS_AUTOSHOTGUN_CHANCE 	= 2;
static const PUMPSHOT_IS_CHROME_CHANCE		= 2;
static const SMG_IS_SILENCED_CHANCE			= 2;


static const String:VEC_ORIGIN_ENTPROP[]	= "m_vecOrigin";
static const String:ANG_ROTATION_ENTPROP[]	= "m_angRotation";
static const String:WEAPON_ID_ENTPROP[]		= "m_weaponID";


static Handle:cvarEnabled					= INVALID_HANDLE;
static Handle:cvarAWPEnabled				= INVALID_HANDLE;
static Handle:cvarMP5Enabled				= INVALID_HANDLE;
static Handle:cvarScoutEnabled				= INVALID_HANDLE;
static Handle:cvarSG552Enabled				= INVALID_HANDLE;

static WeaponSpawn_ID[64]					= 0;
static WeaponSpawn_IDMod[64]				= 0;
static Float:WeaponOrigin[64][3];
static Float:WeaponAngles[64][3];

static bool:InitFinished					= false;
//Used to keep spawns the same for both teams on competitive modes.
static bool:g_bNewMap						= false;
static bool:g_bScavengeHalftime				= false;

forward SRS_OnItemsHandled(bool:justIndexed);

public Plugin:myinfo =
{
	name = "[L4D2] Weapon Unlock",
	author = "Crimson_Fox & AtomicStryker",
	description = "Unlocks the hidden CSS weapons.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?p=1041458"
}

public OnPluginStart()
{
	decl String:game[16];
	GetGameFolderName(game, sizeof(game)); 	//Look up what game we're running, and don't load if it's not L4D2.
	if (!StrEqual(game, "left4dead2", false))
	{
		SetFailState("Plugin supports Left 4 Dead 2 only.");
	}
	
	//Set up cvars and event hooks.
	CreateConVar(					 "l4d2_WeaponUnlock", 	PLUGIN_VERSION, "Weapon Unlock version.", 				FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	cvarEnabled = 		CreateConVar("l4d2_wu_enable", 		"1", 			"Is Weapon Unlock plug-in enabled?", 	FCVAR_PLUGIN|FCVAR_DONTRECORD);
	cvarAWPEnabled = 	CreateConVar("l4d2_wu_awp", 		"1", 			"Enable AWP sniper rifle?", 			FCVAR_PLUGIN);
	cvarMP5Enabled = 	CreateConVar("l4d2_wu_mp5", 		"1", 			"Enable MP5 submachine gun?", 			FCVAR_PLUGIN);
	cvarScoutEnabled = 	CreateConVar("l4d2_wu_scout", 		"1", 			"Enable Scout sniper rifle?", 			FCVAR_PLUGIN);
	cvarSG552Enabled = 	CreateConVar("l4d2_wu_sg552", 		"1", 			"Enable SG552 assault rifle?", 			FCVAR_PLUGIN);
	
	AutoExecConfig(true, "l4d2_WeaponUnlock");
	
	HookEvent("round_start", Event_RoundStart);
	HookEvent("scavenge_round_halftime", Event_ScavengeRoundHalftime);
	
	HookConVarChange(cvarEnabled, ConVarChange_Enabled);
	
	//Precache hidden weapon models and initialize them after one second.
	PrecacheWeaponModels();
	CreateTimer(PLUGINSTART_DELAY, InitHiddenWeaponsDelayed);
}

public ConVarChange_Enabled(Handle:convar, const String:oldValue[], const String:newValue[])
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

public OnMapStart()
{
	g_bNewMap = true;
	g_bScavengeHalftime = false;
	for (new i = 0; i < sizeof(WeaponSpawn_ID); i++)
	{
		WeaponSpawn_ID[i] = -1;
	}
}

public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!GetConVarBool(cvarEnabled)) return;
	CreateTimer(ROUNDSTART_DELAY, RoundStartDelayed);
}

public SRS_OnItemsHandled(bool:justIndexed)
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

static bool:IsSRSMODactive()
{
	new Handle:cvar = FindConVar("srs_remove_enabled");
	if (cvar != INVALID_HANDLE)
	{
		if (GetConVarBool(cvar))
		{
			return true;
		}
	}
	return false;
}

static bool:IsAllowedMap()
{
	decl String:GameMode[16];
	GetConVarString(FindConVar("mp_gamemode"), GameMode, sizeof(GameMode));
	
	decl String:Map[56];
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

public Action:RoundStartDelayed(Handle:timer)
{
	if (!InitFinished || !IsAllowedMap()) return;
	
	if (IsSRSMODactive())
	{
		DebugPrintToAll("Active srsmod Item Module found, aborting automatic Weapon exchange");
		return;
	}
	
	//Look up the map and type of game we're running.
	decl String:GameMode[16];
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

public Action:Event_ScavengeRoundHalftime(Handle:event, const String:name[], bool:dontBroadcast)
{
	g_bScavengeHalftime = true;
}

static IndexWeaponSpawns()
{
	//Search for dynamic weapon spawns,
	decl String:EdictClassName[32];
	new count = 0;
	new entcount = GetEntityCount();
	for (new i = 32; i <= entcount; i++)
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
	decl String:GameMode[16];
	GetConVarString(FindConVar("mp_gamemode"), GameMode, sizeof(GameMode));
	if (!StrEqual(GameMode, "scavenge"))
	{
		for (new i = 0; i <= count; i++)
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
		new dynamiccount = count;
		
		for (new i = 32; i <= entcount; i++)
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
		for (new i = dynamiccount; i <= count; i++)
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

static SetModelForWeaponId(weaponent, id)
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

static SpawnIndexedWeapons()
{
	PrecacheWeaponModels();
	WipeStoredWeapons();
	
	DebugPrintToAll("Commencing to spawn indexed weapons now");
	
	new spawnedent;
	
	for (new i = 0; i < sizeof(WeaponSpawn_ID); i++)
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
		
		DebugPrintToAll("Spawning indexed gun %i, new ent %i, original id %i, modid %i", i, spawnedent, WeaponSpawn_ID[i], WeaponSpawn_IDMod[i]);
		DispatchSpawn(spawnedent);
	}
	
	DebugPrintToAll("Finished Spawning indexed weapons");
}

static WipeStoredWeapons()
{
	DebugPrintToAll("WipeStoredWeapons() was called. Removing stored Weapon Spawns on map");
	
	decl String:GameMode[16];
	GetConVarString(FindConVar("mp_gamemode"), GameMode, sizeof(GameMode));
	new bool:wipestaticspawns = (StrEqual(GameMode, "scavenge"));
	if (wipestaticspawns) DebugPrintToAll("Gamemode is Scavenge, also wiping static Spawns");
	
	new entcount = GetEntityCount();
	decl String:EdictClassName[64];
	decl Float:origin[3];
	
	for (new i = 32; i <= entcount; i++)
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

static bool:IsIndexedOrigin(Float:origin[3])
{
	for (new i = 0; i < sizeof(WeaponSpawn_ID); i++)
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

static bool:IsWantedGunEntity(const String:EdictClassName[])
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

static RestoreWeaponSpawns()
{
	WipeStoredWeapons();
	
	DebugPrintToAll("Commencing to restore default indexed weapons now");
	
	new spawnedent;
	
	for (new i = 0; i < sizeof(WeaponSpawn_ID); i++)
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
		
		DebugPrintToAll("Spawning default indexed gun %i, new ent %i, original id %i, unused modid %i", i, spawnedent, WeaponSpawn_ID[i], WeaponSpawn_IDMod[i]);
		DispatchSpawn(spawnedent);
	}
	
	DebugPrintToAll("Finished Spawning default indexed weapons");
}

static PrecacheWeaponModels()
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

stock CheckModelPreCache(const String:Modelfile[])
{
	if (!IsModelPrecached(Modelfile))
	{
		PrecacheModel(Modelfile);
	}
}

public Action:InitHiddenWeaponsDelayed(Handle:timer, any:client)
{
	//Spawn and delete the hidden weapons,
	PreCacheGun("weapon_rifle_sg552");
	PreCacheGun("weapon_smg_mp5");
	PreCacheGun("weapon_sniper_awp");
	PreCacheGun("weapon_sniper_scout");
	PreCacheGun("weapon_rifle_m60");
	
	InitFinished = true;
	decl String:Map[56];
	GetCurrentMap(Map, sizeof(Map));
	ForceChangeLevel(Map, "Hidden weapon initialization.");
}

static PreCacheGun(const String:GunEntity[])
{
	new index = CreateEntityByName(GunEntity);
	DispatchSpawn(index);
	RemoveEdict(index);
}

stock DebugPrintToAll(const String:format[], any:...)
{
	#if (TEST_DEBUG || TEST_DEBUG_LOG)
	decl String:buffer[256];
	
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