#pragma newdecls required
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define PLUGIN_VERSION "0.5e"
#define CVAR_FLAGS	FCVAR_SPONLY

#define TIER2					(1<<0)
#define TIER1					(1<<1)
#define MAGNUM					(1<<2)
#define PISTOL					(1<<3)

char 	s_Weapons[][] =
		{
			"weapon_pistol",					//	[0]
			"weapon_smg",						//	[1]
			"weapon_pumpshotgun",				//	[2]
			"weapon_autoshotgun",				//	[3]
			"weapon_rifle",						//	[4]
			"weapon_hunting_rifle",				//	[5]
			"weapon_smg_silenced",				//	[6]
			"weapon_shotgun_chrome",			//	[7]
			"weapon_rifle_desert",				//	[8]
			"weapon_sniper_military",			//	[9]
			"weapon_shotgun_spas",				//	[10]
			"weapon_rifle_ak47",				//	[11]
			"weapon_pistol_magnum",				//	[12]
			"weapon_smg_mp5",					//	[13]
			"weapon_rifle_sg552",				//	[14]
			"weapon_sniper_awp",				//	[15]
			"weapon_sniper_scout"				//	[16]
		},

		s_WeaponSpawns[][] =
		{
			"weapon_pistol_spawn",				//	[0]
			"weapon_smg_spawn",					//	[1]
			"weapon_pumpshotgun_spawn",			//	[2]
			"weapon_autoshotgun_spawn",			//	[3]
			"weapon_rifle_spawn",				//	[4]
			"weapon_hunting_rifle_spawn",		//	[5]
			"weapon_smg_silenced_spawn",		//	[6]
			"weapon_shotgun_chrome_spawn",		//	[7]
			"weapon_rifle_desert_spawn",		//	[8]
			"weapon_sniper_military_spawn",		//	[9]
			"weapon_shotgun_spas_spawn",		//	[10]
			"weapon_rifle_ak47_spawn",			//	[11]
			"weapon_pistol_magnum_spawn",		//	[12]
			"weapon_smg_mp5_spawn",				//	[13]
			"weapon_rifle_sg552_spawn",			//	[14]
			"weapon_sniper_awp_spawn",			//	[15]
			"weapon_sniper_scout_spawn"			//	[16]
		};

int 	i_WeaponIds[] =
		{
			1,									//	[0]
			2,									//	[1]
			3,									//	[2]
			4,									//	[3]
			5,									//	[4]
			6,									//	[5]
			7,									//	[6]
			8,									//	[7]
			9,									//	[8]
			10,									//	[9]
			11,									//	[10]
			26,									//	[11]
			32,									//	[12]
			33,									//	[13]
			34,									//	[14]
			35,									//	[15]
			36									//	[16]
		},

		// Number of rounds in a single weapon
		i_WeaponsAmmo[] =
		{
			0,									//	[0]		//	pistol
			650,								//	[1]		//	smg
			128,								//	[2]		//	pumpshotgun
			128,								//	[3] 	//	autoshotgun
			450,								//	[4]		//	rifle
			150,								//	[5]		//	hunting_rifle
			650,								//	[6]		//	smg_silenced
			128,								//	[7]		//	shotgun_chrome
			360,								//	[8]		//	rifle_desert
			180,								//	[9]		//	sniper_military
			90,									//	[10]	//	shotgun_spas
			360,								//	[11]	//	rifle_ak47
			0,									//	[12]	//	pistol_magnum
			650,								//	[13]	//	smg_mp5
			360,								//	[14]	//	rifle_sg552
			180,								//	[15]	//	sniper_awp
			180									//	[16]	//	sniper_scout
		},

		i_Tier2Index1[] = {3, 4, 5},
		i_Tier2Index2[] = {8, 9, 10, 11, 14, 15, 16},
		i_Tier1Index1[] = {1, 2},
		i_Tier1Index2[] = {6, 7, 13},
		i_MagnumIndex = 12,
		i_PistolIndex = 0;
		
ConVar	h_Cvar_PluginEnable, h_Cvar_GunTypes, h_Cvar_AutoShotgunCount, h_Cvar_RifleCount, h_Cvar_Hunting_RifleCount, h_Cvar_PistolCount, h_Cvar_PumpshotgunCount,
		h_Cvar_SmgCount, h_Cvar_OtherGunsCount, h_Cvar_MaxBotHalt, h_Cvar_MaxClientsLoading;

int	i_Cvar_AutoShotgunCount, i_Cvar_RifleCount, i_Cvar_Hunting_RifleCount, i_Cvar_PistolCount, i_Cvar_PumpshotgunCount,
	i_Cvar_SmgCount, i_Cvar_OtherGunsCount, i_Cvar_GunTypes, i_Cvar_MaxBotHalt, i_Cvar_MaxClientsLoading;
	
Handle h_DelayTimer, h_SbStopTimer, h_SbStopCvar;

bool b_Enable, b_Left4Dead2;

public Plugin myinfo =
{
	name = "[L4D & L4D2] Single Gun Spawns",
	author = "Don't Fear The Reaper, [ALLY] Electr0, Dosergen",
	description = "Replaces all gun spawns with single guns",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=172918"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{	
	EngineVersion iEngineVersion = GetEngineVersion();
	if( iEngineVersion == Engine_Left4Dead ) 
	{
		b_Left4Dead2 = false;
	}
	else if( iEngineVersion == Engine_Left4Dead2 ) 
	{
		b_Left4Dead2 = true;
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

	h_Cvar_PluginEnable = CreateConVar("l4d_1gunspawns_enable", "1", "Plugin Enable? (1: ON, 0: OFF)", CVAR_FLAGS, true, 0.0, true, 1.0);
	h_Cvar_GunTypes = CreateConVar("l4d_1gunspawns_types", "15", "Sum of gun types to get replaced (1: Tier 2, 2: Tier 1, 4: Magnum, 8: Pistol, 15: All)", CVAR_FLAGS, true, 0.0, true, 15.0);
	h_Cvar_AutoShotgunCount = CreateConVar("l4d_1gunspawns_autoshotgun_count", "1", "Amount of Autoshotguns to replace a weapon spawn with", CVAR_FLAGS, true, 0.0, true, 16.0);
	h_Cvar_RifleCount = CreateConVar("l4d_1gunspawns_rifle_count", "1", "Amount of M4s to replace a weapon spawn with", CVAR_FLAGS, true, 0.0, true, 16.0);
	h_Cvar_Hunting_RifleCount = CreateConVar("l4d_1gunspawns_hunting_rifle_count", "1", "Amount of Hunting Sniper Rifles to replace a weapon spawn with", CVAR_FLAGS, true, 0.0, true, 16.0);
	h_Cvar_PistolCount = CreateConVar("l4d_1gunspawns_pistol_count", "1", "Amount of Pistols to replace a weapon spawn with", CVAR_FLAGS, true, 0.0, true, 16.0);
	h_Cvar_PumpshotgunCount = CreateConVar("l4d_1gunspawns_pumpshotgun_count", "1", "Amount of Pumpshotguns to replace a weapon spawn with", CVAR_FLAGS, true, 0.0, true, 16.0);
	h_Cvar_SmgCount = CreateConVar("l4d_1gunspawns_smg_count", "1", "Amount of SMGs to replace a weapon spawn with", CVAR_FLAGS, true, 0.0, true, 16.0);
	h_Cvar_OtherGunsCount = CreateConVar("l4d_1gunspawns_count", "1", "Amount of Other guns to replace a weapon spawn with", CVAR_FLAGS, true, 0.0, true, 16.0);
	h_Cvar_MaxBotHalt = CreateConVar("l4d_1gunspawns_maxbothalt", "30", "Maximum time (in seconds) the survivor bots will be halted on round start", CVAR_FLAGS, true, 0.0, true, 300.0);
	h_Cvar_MaxClientsLoading = CreateConVar("l4d_1gunspawns_maxloading", "1", "Maximum number of loading clients to ignore on bot reactivation", CVAR_FLAGS, true, 0.0, true, 32.0);

	AutoExecConfig(true, "l4d_1gunspawns");
	
	h_Cvar_PluginEnable.AddChangeHook(ConVarChanged_Allow);
	h_Cvar_GunTypes.AddChangeHook(ConVarChanged_Cvars);
	h_Cvar_AutoShotgunCount.AddChangeHook(ConVarChanged_Cvars);
	h_Cvar_RifleCount.AddChangeHook(ConVarChanged_Cvars);
	h_Cvar_Hunting_RifleCount.AddChangeHook(ConVarChanged_Cvars);
	h_Cvar_PistolCount.AddChangeHook(ConVarChanged_Cvars);
	h_Cvar_PumpshotgunCount.AddChangeHook(ConVarChanged_Cvars);
	h_Cvar_SmgCount.AddChangeHook(ConVarChanged_Cvars);
	h_Cvar_OtherGunsCount.AddChangeHook(ConVarChanged_Cvars);
	h_SbStopCvar = FindConVar("sb_stop");
	h_Cvar_MaxBotHalt.AddChangeHook(ConVarChanged_Cvars);
	h_Cvar_MaxClientsLoading.AddChangeHook(ConVarChanged_Cvars);
	
	IsAllowed();
}

public void OnConfigsExecuted()
{
	IsAllowed();
}

public void ConVarChanged_Allow(ConVar convar, const char[] oldValue, const char[] newValue)
{
	IsAllowed();
}

public void ConVarChanged_Cvars(ConVar convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

void GetCvars()
{
	i_Cvar_GunTypes = h_Cvar_GunTypes.IntValue;
	i_Cvar_AutoShotgunCount = h_Cvar_AutoShotgunCount.IntValue;
	i_Cvar_RifleCount = h_Cvar_RifleCount.IntValue;
	i_Cvar_Hunting_RifleCount = h_Cvar_Hunting_RifleCount.IntValue;
	i_Cvar_PistolCount = h_Cvar_PistolCount.IntValue;
	i_Cvar_PumpshotgunCount = h_Cvar_PumpshotgunCount.IntValue;
	i_Cvar_SmgCount = h_Cvar_SmgCount.IntValue;
	i_Cvar_OtherGunsCount = h_Cvar_OtherGunsCount.IntValue;
	i_Cvar_MaxBotHalt = h_Cvar_MaxBotHalt.IntValue;
	i_Cvar_MaxClientsLoading = h_Cvar_MaxClientsLoading.IntValue;
}

void IsAllowed()
{
	bool bCvarAllow = h_Cvar_PluginEnable.BoolValue;
	GetCvars();

	if( b_Enable == false && bCvarAllow == true )
	{
		b_Enable = true;
		HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
		HookEvent("round_end", Event_RoundEnd, EventHookMode_PostNoCopy);
	}

	else if( b_Enable == true && bCvarAllow == false )
	{
		b_Enable = false;
		UnhookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
		UnhookEvent("round_end", Event_RoundEnd, EventHookMode_PostNoCopy);
	}
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	SetConVarBool(h_SbStopCvar, true);
	h_DelayTimer = CreateTimer(3.0, PrepareMap, _, TIMER_FLAG_NO_MAPCHANGE);
}

public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	if (h_DelayTimer != null)
	{
		KillTimer(h_DelayTimer);
		h_DelayTimer = null;
	}
	
	if (h_SbStopTimer != null)
	{
		KillTimer(h_SbStopTimer);
		h_SbStopTimer = null;
	}
}

public Action PrepareMap(Handle Timer)
{
	if (b_Left4Dead2)
	{
		ReplaceRandom("weapon_spawn");
	}

	if (i_Cvar_GunTypes & TIER2)
	{
		for (int i = 0; i < sizeof(i_Tier2Index1); i++)
		{
			ReplaceDefined(s_WeaponSpawns[i_Tier2Index1[i]], i_Tier2Index1[i]);
		}

		if (b_Left4Dead2)
		{
			for (int i = 0; i < sizeof(i_Tier2Index2); i++)
			{
				ReplaceDefined(s_WeaponSpawns[i_Tier2Index2[i]], i_Tier2Index2[i]);
			}
		}
	}

	if (i_Cvar_GunTypes & TIER1)
	{
		for (int i = 0; i < sizeof(i_Tier1Index1); i++)
		{
			ReplaceDefined(s_WeaponSpawns[i_Tier1Index1[i]], i_Tier1Index1[i]);
		}

		if (b_Left4Dead2)
		{
			for (int i = 0; i < sizeof(i_Tier1Index2); i++)
			{
				ReplaceDefined(s_WeaponSpawns[i_Tier1Index2[i]], i_Tier1Index2[i]);
			}
		}
	}

	if ((i_Cvar_GunTypes & MAGNUM) && b_Left4Dead2)
	{
		ReplaceDefined(s_WeaponSpawns[i_MagnumIndex], i_MagnumIndex);
	}

	if (i_Cvar_GunTypes & PISTOL)
	{
		ReplaceDefined(s_WeaponSpawns[i_PistolIndex], i_PistolIndex);
	}

	int i_StartTime = RoundToNearest(GetGameTime());
	h_SbStopTimer = CreateTimer(1.0, ResetSbStop, i_StartTime, TIMER_REPEAT);

	h_DelayTimer = null;
	return Plugin_Stop;
}

public Action ResetSbStop(Handle h_Timer, any i_StartTime)
{
	int i_PassedTime = RoundToNearest(GetGameTime()) - i_StartTime;
	
	if (i_PassedTime >= i_Cvar_MaxBotHalt)
	{
		SetConVarBool(h_SbStopCvar, false);
		h_SbStopTimer = null;
		return Plugin_Stop;
	}
	
	int i_ClientsLoading = GetClientCount(false) - GetClientCount(true);
	
	if (i_ClientsLoading > i_Cvar_MaxClientsLoading)
	{
		SetConVarBool(h_SbStopCvar, false);
		h_SbStopTimer = null;
		return Plugin_Stop;
	}
	
	return Plugin_Continue;
}

void ReplaceDefined(const char[] s_WeaponSpawn, const int i_Index)
{
	int i_EdictIndex = -1;

	while ((i_EdictIndex = FindEntityByClassname(i_EdictIndex, s_WeaponSpawn)) != INVALID_ENT_REFERENCE)
	{
		ReplaceCount(i_EdictIndex, i_Index);
	}
}

void ReplaceRandom(const char[] s_WeaponSpawn)
{
	int i_EdictIndex = -1;

	while ((i_EdictIndex = FindEntityByClassname(i_EdictIndex, s_WeaponSpawn)) != INVALID_ENT_REFERENCE)
	{
		int i_Index = CheckWeaponId(GetEntProp(i_EdictIndex, Prop_Send, "m_weaponID"));

		if (i_Index != -1)
		{
			ReplaceCount(i_EdictIndex, i_Index);
		}
	}
}

void ReplaceCount(const int i_EdictIndex, const int i_Index)
{
	float v_Origin[3], v_Angles[3];

	GetEntPropVector(i_EdictIndex, Prop_Send, "m_vecOrigin", v_Origin);
	GetEntPropVector(i_EdictIndex, Prop_Send, "m_angRotation", v_Angles);

	AcceptEntityInput(i_EdictIndex, "Kill");

	int i_GunCount = GetGunCountById(i_Index);

	for (int i = 1; i <= i_GunCount; i++)
	{
		int i_NewEdict = CreateEntityByName(s_Weapons[i_Index]);

		DispatchKeyValueVector(i_NewEdict, "origin", v_Origin);
		DispatchKeyValueVector(i_NewEdict, "angles", v_Angles);		
		DispatchKeyValue(i_NewEdict, "spawnflags", "1");
		DispatchSpawn(i_NewEdict);
		SetEntProp(i_NewEdict, Prop_Send, "m_iExtraPrimaryAmmo", i_WeaponsAmmo[i_Index]);
	}
}

int GetGunCountById(const int i_Index)
{
	//0 - "weapon_pistol",
	//1 - "weapon_smg",
	//2 - "weapon_pumpshotgun",
	//3 - "weapon_autoshotgun",
	//4 - "weapon_rifle",
	//5 - "weapon_hunting_rifle",
	//6 - "weapon_smg_silenced",
	//7 - "weapon_shotgun_chrome",
	//8 - "weapon_rifle_desert",
	//9 - "weapon_sniper_military",
	//10 - "weapon_shotgun_spas",
	//11 - "weapon_rifle_ak47",
	//12 - "weapon_pistol_magnum",
	//13 - "weapon_smg_mp5",
	//14 - "weapon_rifle_sg552",
	//15 - "weapon_sniper_awp",
	//16 - "weapon_sniper_scout"

	if(i_Index == 0)
	{
		return i_Cvar_PistolCount;
	}
	else if(i_Index == 1)
	{
		return i_Cvar_SmgCount;
	}
	else if(i_Index == 2)
	{
		return i_Cvar_PumpshotgunCount;
	}
	else if(i_Index == 3)
	{
		return i_Cvar_AutoShotgunCount;
	}
	else if(i_Index == 4)
	{
		return i_Cvar_RifleCount;
	}
	else if(i_Index == 5)
	{
		return i_Cvar_Hunting_RifleCount;
	}
	else
	{
		return i_Cvar_OtherGunsCount;
	}
}

int CheckWeaponId(const int i_WeaponId)
{
	int i_Index = -1;

	for (int i = 0; i < sizeof(i_WeaponIds); i++)
	{
		if (i_WeaponId == i_WeaponIds[i])
		{
			if (i_Cvar_GunTypes & TIER2)
			{
				for (int j = 0; j < sizeof(i_Tier2Index1); j++)
				{
					if (i == i_Tier2Index1[j])
					{
						i_Index = i;
						return i_Index;
					}
				}

				for (int j = 0; j < sizeof(i_Tier2Index2); j++)
				{
					if (i == i_Tier2Index2[j])
					{
						i_Index = i;
						return i_Index;
					}
				}
			}

			if (i_Cvar_GunTypes & TIER1)
			{
				for (int j = 0; j < sizeof(i_Tier1Index1); j++)
				{
					if (i == i_Tier1Index1[j])
					{
						i_Index = i;
						return i_Index;
					}
				}

				for (int j = 0; j < sizeof(i_Tier1Index2); j++)
				{
					if (i == i_Tier1Index2[j])
					{
						i_Index = i;
						return i_Index;
					}
				}
			}

			if ((i_Cvar_GunTypes & MAGNUM) && (i == i_MagnumIndex))
			{
				i_Index = i;
				return i_Index;
			}

			if ((i_Cvar_GunTypes & PISTOL) && (i == i_PistolIndex))
			{
				i_Index = i;
				return i_Index;
			}
		}
	}

	return i_Index;
}