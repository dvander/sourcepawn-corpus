#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define PLUGIN_VERSION "0.5g"
#define CVAR_FLAGS FCVAR_NOTIFY

#define TIER2 (1<<0)
#define TIER1 (1<<1)
#define MAGNUM (1<<2)
#define PISTOL (1<<3)

static const char g_sWeapons[][] =
{
	"weapon_pistol",                  // [0]
	"weapon_smg",                     // [1]
	"weapon_pumpshotgun",             // [2]
	"weapon_autoshotgun",             // [3]
	"weapon_rifle",                   // [4]
	"weapon_hunting_rifle",           // [5]
	"weapon_smg_silenced",            // [6]
	"weapon_shotgun_chrome",          // [7]
	"weapon_rifle_desert",            // [8]
	"weapon_sniper_military",         // [9]
	"weapon_shotgun_spas",            // [10]
	"weapon_rifle_ak47",              // [11]
	"weapon_pistol_magnum",           // [12]
	"weapon_smg_mp5",                 // [13]
	"weapon_rifle_sg552",             // [14]
	"weapon_sniper_awp",              // [15]
	"weapon_sniper_scout"             // [16]
};

static const char g_sWeaponSpawns[][] =
{
	"weapon_pistol_spawn",            // [0]
	"weapon_smg_spawn",               // [1]
	"weapon_pumpshotgun_spawn",       // [2]
	"weapon_autoshotgun_spawn",       // [3]
	"weapon_rifle_spawn",             // [4]
	"weapon_hunting_rifle_spawn",     // [5]
	"weapon_smg_silenced_spawn",      // [6]
	"weapon_shotgun_chrome_spawn",    // [7]
	"weapon_rifle_desert_spawn",      // [8]
	"weapon_sniper_military_spawn",   // [9]
	"weapon_shotgun_spas_spawn",      // [10]
	"weapon_rifle_ak47_spawn",        // [11]
	"weapon_pistol_magnum_spawn",     // [12]
	"weapon_smg_mp5_spawn",           // [13]
	"weapon_rifle_sg552_spawn",       // [14]
	"weapon_sniper_awp_spawn",        // [15]
	"weapon_sniper_scout_spawn"       // [16]
};

static const int g_iWeaponIds[] =
{
	1,                                // [0]
	2,                                // [1]
	3,                                // [2]
	4,                                // [3]
	5,                                // [4]
	6,                                // [5]
	7,                                // [6]
	8,                                // [7]
	9,                                // [8]
	10,                               // [9]
	11,                               // [10]
	26,                               // [11]
	32,                               // [12]
	33,                               // [13]
	34,                               // [14]
	35,                               // [15]
	36                                // [16]
};

// Number of rounds in a single weapon
static const int g_iWeaponsAmmo[] =
{
	0,                                // [0] pistol
	650,                              // [1] smg
	128,                              // [2] pumpshotgun
	128,                              // [3] autoshotgun
	450,                              // [4] rifle
	150,                              // [5] hunting_rifle
	650,                              // [6] smg_silenced
	128,                              // [7] shotgun_chrome
	360,                              // [8] rifle_desert
	180,                              // [9] sniper_military
	90,                               // [10] shotgun_spas
	360,                              // [11] rifle_ak47
	0,                                // [12] pistol_magnum
	650,                              // [13] smg_mp5
	360,                              // [14] rifle_sg552
	180,                              // [15] sniper_awp
	180                               // [16] sniper_scout
};

static const int g_iTier2Index1[] = {3, 4, 5};
static const int g_iTier2Index2[] = {8, 9, 10, 11, 14, 15, 16};
static const int g_iTier1Index1[] = {1, 2};
static const int g_iTier1Index2[] = {6, 7, 13};
static const int g_iMagnumIndex = 12;
static const int g_iPistolIndex = 0;
		
ConVar g_hCvar_PluginEnable, g_hCvar_GunTypes, g_hCvar_AutoShotgunCount, g_hCvar_RifleCount, g_hCvar_Hunting_RifleCount, g_hCvar_PistolCount, 
       g_hCvar_PumpshotgunCount, g_hCvar_SmgCount, g_hCvar_OtherGunsCount, g_hCvar_MaxBotHalt, g_hCvar_MaxClientsLoading, g_hSbStopCvar;
int    g_iCvar_AutoShotgunCount, g_iCvar_RifleCount, g_iCvar_Hunting_RifleCount, g_iCvar_PistolCount, g_iCvar_PumpshotgunCount,
       g_iCvar_SmgCount, g_iCvar_OtherGunsCount, g_iCvar_GunTypes, g_iCvar_MaxBotHalt, g_iCvar_MaxClientsLoading;
Handle g_hDelayTimer, g_hSbStopTimer;
bool   g_bEnable, g_bLeft4Dead2;

public Plugin myinfo =
{
	name = "[L4D & L4D2] Single Gun Spawns",
	author = "Don't Fear The Reaper, Electr0, Dosergen",
	description = "Replaces all gun spawns with single guns",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=172918"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{	
	EngineVersion iEngineVersion = GetEngineVersion();
	if (iEngineVersion == Engine_Left4Dead) 
	{
		g_bLeft4Dead2 = false;
	}
	else if (iEngineVersion == Engine_Left4Dead2) 
	{
		g_bLeft4Dead2 = true;
	}
	else
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 1 & 2.");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

public void OnPluginStart()
{
	CreateConVar("l4d_1gunspawns_version", PLUGIN_VERSION, "Version of the '[L4D & L4D2] Single Guns Spawns' plugin", FCVAR_NOTIFY|FCVAR_DONTRECORD);

	g_hCvar_PluginEnable = CreateConVar("l4d_1gunspawns_enable", "1", "Plugin Enable? (1: ON, 0: OFF)", CVAR_FLAGS, true, 0.0, true, 1.0);
	g_hCvar_GunTypes = CreateConVar("l4d_1gunspawns_types", "15", "Sum of gun types to get replaced (1: Tier 2, 2: Tier 1, 4: Magnum, 8: Pistol, 15: All)", CVAR_FLAGS, true, 0.0, true, 15.0);
	g_hCvar_AutoShotgunCount = CreateConVar("l4d_1gunspawns_autoshotgun_count", "1", "Amount of Autoshotguns to replace a weapon spawn with", CVAR_FLAGS, true, 0.0, true, 16.0);
	g_hCvar_RifleCount = CreateConVar("l4d_1gunspawns_rifle_count", "1", "Amount of M4s to replace a weapon spawn with", CVAR_FLAGS, true, 0.0, true, 16.0);
	g_hCvar_Hunting_RifleCount = CreateConVar("l4d_1gunspawns_hunting_rifle_count", "1", "Amount of Hunting Sniper Rifles to replace a weapon spawn with", CVAR_FLAGS, true, 0.0, true, 16.0);
	g_hCvar_PistolCount = CreateConVar("l4d_1gunspawns_pistol_count", "1", "Amount of Pistols to replace a weapon spawn with", CVAR_FLAGS, true, 0.0, true, 16.0);
	g_hCvar_PumpshotgunCount = CreateConVar("l4d_1gunspawns_pumpshotgun_count", "1", "Amount of Pumpshotguns to replace a weapon spawn with", CVAR_FLAGS, true, 0.0, true, 16.0);
	g_hCvar_SmgCount = CreateConVar("l4d_1gunspawns_smg_count", "1", "Amount of SMGs to replace a weapon spawn with", CVAR_FLAGS, true, 0.0, true, 16.0);
	g_hCvar_OtherGunsCount = CreateConVar("l4d_1gunspawns_count", "1", "Amount of Other guns to replace a weapon spawn with", CVAR_FLAGS, true, 0.0, true, 16.0);
	g_hCvar_MaxBotHalt = CreateConVar("l4d_1gunspawns_maxbothalt", "30", "Maximum time (in seconds) the survivor bots will be halted on round start", CVAR_FLAGS, true, 0.0, true, 300.0);
	g_hCvar_MaxClientsLoading = CreateConVar("l4d_1gunspawns_maxloading", "1", "Maximum number of loading clients to ignore on bot reactivation", CVAR_FLAGS, true, 0.0, true, 32.0);

	AutoExecConfig(true, "l4d_1gunspawns");
	
	g_hCvar_PluginEnable.AddChangeHook(ConVarChanged_Allow);
	g_hCvar_GunTypes.AddChangeHook(ConVarChanged_Cvars);
	g_hCvar_AutoShotgunCount.AddChangeHook(ConVarChanged_Cvars);
	g_hCvar_RifleCount.AddChangeHook(ConVarChanged_Cvars);
	g_hCvar_Hunting_RifleCount.AddChangeHook(ConVarChanged_Cvars);
	g_hCvar_PistolCount.AddChangeHook(ConVarChanged_Cvars);
	g_hCvar_PumpshotgunCount.AddChangeHook(ConVarChanged_Cvars);
	g_hCvar_SmgCount.AddChangeHook(ConVarChanged_Cvars);
	g_hCvar_OtherGunsCount.AddChangeHook(ConVarChanged_Cvars);
	g_hSbStopCvar = FindConVar("sb_stop");
	g_hCvar_MaxBotHalt.AddChangeHook(ConVarChanged_Cvars);
	g_hCvar_MaxClientsLoading.AddChangeHook(ConVarChanged_Cvars);
	
	IsAllowed();
}

public void OnConfigsExecuted()
{
	IsAllowed();
}

void ConVarChanged_Allow(ConVar convar, const char[] oldValue, const char[] newValue)
{
	IsAllowed();
}

void ConVarChanged_Cvars(ConVar convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

void GetCvars()
{
	g_iCvar_GunTypes = g_hCvar_GunTypes.IntValue;
	g_iCvar_AutoShotgunCount = g_hCvar_AutoShotgunCount.IntValue;
	g_iCvar_RifleCount = g_hCvar_RifleCount.IntValue;
	g_iCvar_Hunting_RifleCount = g_hCvar_Hunting_RifleCount.IntValue;
	g_iCvar_PistolCount = g_hCvar_PistolCount.IntValue;
	g_iCvar_PumpshotgunCount = g_hCvar_PumpshotgunCount.IntValue;
	g_iCvar_SmgCount = g_hCvar_SmgCount.IntValue;
	g_iCvar_OtherGunsCount = g_hCvar_OtherGunsCount.IntValue;
	g_iCvar_OtherGunsCount = g_hCvar_OtherGunsCount.IntValue;	
	g_iCvar_MaxBotHalt = g_hCvar_MaxBotHalt.IntValue;
	g_iCvar_MaxClientsLoading = g_hCvar_MaxClientsLoading.IntValue;
}

void IsAllowed()
{
	bool bCvarAllow = g_hCvar_PluginEnable.BoolValue;
	GetCvars();
	if (g_bEnable == false && bCvarAllow == true)
	{
		g_bEnable = true;
		HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
		HookEvent("round_end", Event_RoundEnd, EventHookMode_PostNoCopy);
	}

	else if (g_bEnable == true && bCvarAllow == false)
	{
		g_bEnable = false;
		UnhookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
		UnhookEvent("round_end", Event_RoundEnd, EventHookMode_PostNoCopy);
	}
}

void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	g_hSbStopCvar.SetBool(true);
	g_hDelayTimer = CreateTimer(3.0, PrepareMap, _, TIMER_FLAG_NO_MAPCHANGE);
}

void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	delete g_hDelayTimer;
	delete g_hSbStopTimer;
}

Action PrepareMap(Handle Timer)
{
	if (g_bLeft4Dead2)
	{
		ReplaceRandom("weapon_spawn");
	}
	if (g_iCvar_GunTypes & TIER2)
	{
		for (int i = 0; i < sizeof(g_iTier2Index1); i++)
		{
			ReplaceDefined(g_sWeaponSpawns[g_iTier2Index1[i]], g_iTier2Index1[i]);
		}
		if (g_bLeft4Dead2)
		{
			for (int i = 0; i < sizeof(g_iTier2Index2); i++)
			{
				ReplaceDefined(g_sWeaponSpawns[g_iTier2Index2[i]], g_iTier2Index2[i]);
			}
		}
	}
	if (g_iCvar_GunTypes & TIER1)
	{
		for (int i = 0; i < sizeof(g_iTier1Index1); i++)
		{
			ReplaceDefined(g_sWeaponSpawns[g_iTier1Index1[i]], g_iTier1Index1[i]);
		}
		if (g_bLeft4Dead2)
		{
			for (int i = 0; i < sizeof(g_iTier1Index2); i++)
			{
				ReplaceDefined(g_sWeaponSpawns[g_iTier1Index2[i]], g_iTier1Index2[i]);
			}
		}
	}
	if ((g_iCvar_GunTypes & MAGNUM) && g_bLeft4Dead2)
	{
		ReplaceDefined(g_sWeaponSpawns[g_iMagnumIndex], g_iMagnumIndex);
	}
	if (g_iCvar_GunTypes & PISTOL)
	{
		ReplaceDefined(g_sWeaponSpawns[g_iPistolIndex], g_iPistolIndex);
	}
	int g_iStartTime = RoundToNearest(GetGameTime());
	g_hSbStopTimer = CreateTimer(1.0, ResetSbStop, g_iStartTime, TIMER_REPEAT);
	g_hDelayTimer = null;
	return Plugin_Stop;
}

Action ResetSbStop(Handle g_hTimer, any g_iStartTime)
{
	int g_iPassedTime = RoundToNearest(GetGameTime()) - g_iStartTime;
	int g_iClientsLoading = GetClientCount(false) - GetClientCount(true);
	if (g_iPassedTime >= g_iCvar_MaxBotHalt || g_iClientsLoading > g_iCvar_MaxClientsLoading)
	{
		g_hSbStopCvar.SetBool(false);
		g_hSbStopTimer = null;
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

void ReplaceDefined(const char[] g_sWeaponSpawn, const int g_iIndex)
{
	int g_iEdictIndex = -1;
	while ((g_iEdictIndex = FindEntityByClassname(g_iEdictIndex, g_sWeaponSpawn)) != INVALID_ENT_REFERENCE)
	{
		ReplaceCount(g_iEdictIndex, g_iIndex);
	}
}

void ReplaceRandom(const char[] g_sWeaponSpawn)
{
	int g_iEdictIndex = -1;
	while ((g_iEdictIndex = FindEntityByClassname(g_iEdictIndex, g_sWeaponSpawn)) != INVALID_ENT_REFERENCE)
	{
		int g_iIndex = CheckWeaponId(GetEntProp(g_iEdictIndex, Prop_Send, "m_weaponID"));
		if (g_iIndex != -1)
		{
			ReplaceCount(g_iEdictIndex, g_iIndex);
		}
	}
}

void ReplaceCount(const int g_iEdictIndex, const int g_iIndex)
{
	float v_Origin[3], v_Angles[3];
	GetEntPropVector(g_iEdictIndex, Prop_Send, "m_vecOrigin", v_Origin);
	GetEntPropVector(g_iEdictIndex, Prop_Send, "m_angRotation", v_Angles);
	RemoveEntity(g_iEdictIndex);
	int g_iGunCount = GetGunCountById(g_iIndex);
	for (int i = 1; i <= g_iGunCount; i++)
	{
		int g_iNewEdict = CreateEntityByName(g_sWeapons[g_iIndex]);
		DispatchKeyValueVector(g_iNewEdict, "origin", v_Origin);
		DispatchKeyValueVector(g_iNewEdict, "angles", v_Angles);
		DispatchKeyValue(g_iNewEdict, "disableshadows", "1");		
		DispatchKeyValue(g_iNewEdict, "spawnflags", "1");
		DispatchSpawn(g_iNewEdict);
		SetEntProp(g_iNewEdict, Prop_Send, "m_iExtraPrimaryAmmo", g_iWeaponsAmmo[g_iIndex]);
	}
}

int GetGunCountById(const int g_iIndex)
{
	// 0 - "weapon_pistol",
	// 1 - "weapon_smg",
	// 2 - "weapon_pumpshotgun",
	// 3 - "weapon_autoshotgun",
	// 4 - "weapon_rifle",
	// 5 - "weapon_hunting_rifle",
	// 6 - "weapon_smg_silenced",
	// 7 - "weapon_shotgun_chrome",
	// 8 - "weapon_rifle_desert",
	// 9 - "weapon_sniper_military",
	// 10 - "weapon_shotgun_spas",
	// 11 - "weapon_rifle_ak47",
	// 12 - "weapon_pistol_magnum",
	// 13 - "weapon_smg_mp5",
	// 14 - "weapon_rifle_sg552",
	// 15 - "weapon_sniper_awp",
	// 16 - "weapon_sniper_scout"

	if (g_iIndex == 0)
	{
		return g_iCvar_PistolCount;
	}
	else if (g_iIndex == 1)
	{
		return g_iCvar_SmgCount;
	}
	else if (g_iIndex == 2)
	{
		return g_iCvar_PumpshotgunCount;
	}
	else if (g_iIndex == 3)
	{
		return g_iCvar_AutoShotgunCount;
	}
	else if (g_iIndex == 4)
	{
		return g_iCvar_RifleCount;
	}
	else if (g_iIndex == 5)
	{
		return g_iCvar_Hunting_RifleCount;
	}
	else
	{
		return g_iCvar_OtherGunsCount;
	}
}

int CheckWeaponId(const int g_iWeaponId)
{
	int g_iIndex = -1;
	for (int i = 0; i < sizeof(g_iWeaponIds); i++)
	{
		if (g_iWeaponId == g_iWeaponIds[i])
		{
			if (g_iCvar_GunTypes & TIER2)
			{
				for (int j = 0; j < sizeof(g_iTier2Index1); j++)
				{
					if (i == g_iTier2Index1[j])
					{
						g_iIndex = i;
						return g_iIndex;
					}
				}
				for (int j = 0; j < sizeof(g_iTier2Index2); j++)
				{
					if (i == g_iTier2Index2[j])
					{
						g_iIndex = i;
						return g_iIndex;
					}
				}
			}
			if (g_iCvar_GunTypes & TIER1)
			{
				for (int j = 0; j < sizeof(g_iTier1Index1); j++)
				{
					if (i == g_iTier1Index1[j])
					{
						g_iIndex = i;
						return g_iIndex;
					}
				}
				for (int j = 0; j < sizeof(g_iTier1Index2); j++)
				{
					if (i == g_iTier1Index2[j])
					{
						g_iIndex = i;
						return g_iIndex;
					}
				}
			}
			if ((g_iCvar_GunTypes & MAGNUM) && (i == g_iMagnumIndex))
			{
				g_iIndex = i;
				return g_iIndex;
			}
			if ((g_iCvar_GunTypes & PISTOL) && (i == g_iPistolIndex))
			{
				g_iIndex = i;
				return g_iIndex;
			}
		}
	}
	return g_iIndex;
}