#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "0.2"

#define TIER2	(1<<0)
#define TIER1	(1<<1)
#define MAGNUM	(1<<2)
#define PISTOL	(1<<3)

static const String:s_Weapons[][] =	{
									"weapon_pistol",
									"weapon_smg",
									"weapon_pumpshotgun",
									"weapon_autoshotgun",
									"weapon_rifle",
									"weapon_hunting_rifle",
									"weapon_smg_silenced",
									"weapon_shotgun_chrome",
									"weapon_rifle_desert",
									"weapon_sniper_military",
									"weapon_shotgun_spas",
									"weapon_rifle_ak47",
									"weapon_pistol_magnum",
									"weapon_smg_mp5",
									"weapon_rifle_sg552",
									"weapon_sniper_awp",
									"weapon_sniper_scout"
									};

static const String:s_WeaponSpawns[][] =	{
											"weapon_pistol_spawn",
											"weapon_smg_spawn",
											"weapon_pumpshotgun_spawn",
											"weapon_autoshotgun_spawn",
											"weapon_rifle_spawn",
											"weapon_hunting_rifle_spawn",
											"weapon_smg_silenced_spawn",
											"weapon_shotgun_chrome_spawn",
											"weapon_rifle_desert_spawn",
											"weapon_sniper_military_spawn",
											"weapon_shotgun_spas_spawn",
											"weapon_rifle_ak47_spawn",
											"weapon_pistol_magnum_spawn",
											"weapon_smg_mp5_spawn",
											"weapon_rifle_sg552_spawn",
											"weapon_sniper_awp_spawn",
											"weapon_sniper_scout_spawn"
											};

static const i_WeaponIds[] =		{
									1,
									2,
									3,
									4,
									5,
									6,
									7,
									8,
									9,
									10,
									11,
									26,
									32,
									33,
									34,
									35,
									36
									};

static const i_WeaponsAmmo[] =		{
									0,
									650,
									56,
									90,
									360,
									150,
									650,
									56,
									360,
									180,
									90,
									360,
									0,
									650,
									360,
									180,
									180
									};

static const i_Tier2Index1[] =		{3, 4, 5};
static const i_Tier2Index2[] =		{8, 9, 10, 11, 14, 15, 16};
static const i_Tier1Index1[] =		{1, 2};
static const i_Tier1Index2[] =		{6, 7, 13};
static const i_MagnumIndex =		12;
static const i_PistolIndex =		0;

static const Float:f_RoundStartDelay = 10.0;
static const Float:f_ResetSbStopInterval = 5.0;

new Handle:h_CvarGunTypes;
new Handle:h_CvarGunCount;
new Handle:h_CvarMaxBotHalt;
new Handle:h_CvarMaxClientsLoading;
new Handle:h_CvarShowMessage;
new Handle:h_SbStopCvar;
new Handle:h_RoundStartDelayedTimer;
new Handle:h_ResetSbStopTimer;

new bool:b_IsL4D2;
new bool:b_BlockUse;
new bool:b_ShowedMsg[MAXPLAYERS+1];

public Plugin:myinfo =
{
	name = "[L4D & L4D2] Single Gun Spawns",
	author = "Don't Fear The Reaper",
	description = "Replaces all gun spawns with single guns",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=172918"
}

public OnPluginStart()
{
	decl String:s_Game[16];
	GetGameFolderName(s_Game, sizeof(s_Game));
	if (!StrEqual(s_Game, "left4dead", false) && !StrEqual(s_Game, "left4dead2", false))
	{
		SetFailState("Plugin supports 'Left 4 Dead' and 'Left 4 Dead 2' only.");
	}
	
	if (StrEqual(s_Game, "left4dead", false))
	{
		b_IsL4D2 = false;
	}
	
	if (StrEqual(s_Game, "left4dead2", false))
	{
		b_IsL4D2 = true;
	}
	
	CreateConVar("l4d_1gunspawns_version", PLUGIN_VERSION, "Version of the '[L4D & L4D2] Single Guns Spawns' plugin", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_SPONLY|FCVAR_DONTRECORD);
	h_CvarGunTypes = CreateConVar("l4d_1gunspawns_types", "15", "Sum of gun types to get replaced (1: Tier 2, 2: Tier 1, 4: Magnum, 8: Pistol, 15: All)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 15.0);
	h_CvarGunCount = CreateConVar("l4d_1gunspawns_count", "1", "Amount of guns to replace a weapon spawn with", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 1.0, true, 16.0);
	h_CvarMaxBotHalt = CreateConVar("l4d_1gunspawns_maxbothalt", "60", "Maximum time (in seconds) the survivor bots will be halted on round start", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 900.0);
	h_CvarMaxClientsLoading = CreateConVar("l4d_1gunspawns_maxloading", "1", "Maximum number of loading clients to ignore on bot reactivation", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 32.0);
	h_CvarShowMessage = CreateConVar("l4d_1gunspawns_message", "1", "Disable/Enable hint message while use is blocked", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	
	AutoExecConfig(true, "l4d_1gunspawns");
	
	h_SbStopCvar = FindConVar("sb_stop");
	
	HookEvent("round_start", Event_RoundStart);
	HookEvent("round_end", Event_RoundEnd);
}

public Event_RoundStart(Handle:h_Event, const String:s_Name[], bool:b_DontBroadcast)
{
	if (GetConVarInt(h_CvarShowMessage))
	{
		for (new i = 0; i < MAXPLAYERS+1; i++)
		{
			b_ShowedMsg[i] = false;
		}
	}
	
	SetConVarBool(h_SbStopCvar, true);
	b_BlockUse = true;
	
	h_RoundStartDelayedTimer = CreateTimer(f_RoundStartDelay, RoundStartDelayed, INVALID_HANDLE, TIMER_FLAG_NO_MAPCHANGE);
}

public Event_RoundEnd(Handle:h_Event, const String:s_Name[], bool:b_DontBroadcast)
{
	if (h_RoundStartDelayedTimer != INVALID_HANDLE)
	{
		KillTimer(h_RoundStartDelayedTimer);
		h_RoundStartDelayedTimer = INVALID_HANDLE;
	}
	
	if (h_ResetSbStopTimer != INVALID_HANDLE)
	{
		KillTimer(h_ResetSbStopTimer);
		h_ResetSbStopTimer = INVALID_HANDLE;
	}
}

public Action:RoundStartDelayed(Handle:h_Timer)
{
	if (b_IsL4D2)
	{
		ReplaceRandom("weapon_spawn");
	}
	
	new i_GunTypes = GetConVarInt(h_CvarGunTypes);
	
	if (i_GunTypes & TIER2)
	{
		for (new i = 0; i < sizeof(i_Tier2Index1); i++)
		{
			ReplaceDefined(s_WeaponSpawns[i_Tier2Index1[i]], i_Tier2Index1[i]);
		}
		
		if (b_IsL4D2)
		{
			for (new i = 0; i < sizeof(i_Tier2Index2); i++)
			{
				ReplaceDefined(s_WeaponSpawns[i_Tier2Index2[i]], i_Tier2Index2[i]);
			}
		}
	}
	
	if (i_GunTypes & TIER1)
	{
		for (new i = 0; i < sizeof(i_Tier1Index1); i++)
		{
			ReplaceDefined(s_WeaponSpawns[i_Tier1Index1[i]], i_Tier1Index1[i]);
		}
		
		if (b_IsL4D2)
		{
			for (new i = 0; i < sizeof(i_Tier1Index2); i++)
			{
				ReplaceDefined(s_WeaponSpawns[i_Tier1Index2[i]], i_Tier1Index2[i]);
			}
		}
	}
	
	if ((i_GunTypes & MAGNUM) && b_IsL4D2)
	{
		ReplaceDefined(s_WeaponSpawns[i_MagnumIndex], i_MagnumIndex);
	}
	
	if (i_GunTypes & PISTOL)
	{
		ReplaceDefined(s_WeaponSpawns[i_PistolIndex], i_PistolIndex);
	}
	
	new i_StartTime = RoundToNearest(GetGameTime());

	h_ResetSbStopTimer = CreateTimer(f_ResetSbStopInterval, ResetSbStop, i_StartTime, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	b_BlockUse = false;
	
	h_RoundStartDelayedTimer = INVALID_HANDLE;
}

public Action:ResetSbStop(Handle:h_Timer, any:i_StartTime)
{
	new i_MaxBotHalt = GetConVarInt(h_CvarMaxBotHalt);
	new i_PassedTime = RoundToNearest(GetGameTime()) - i_StartTime;
	
	if (i_PassedTime >= i_MaxBotHalt)
	{
		SetConVarBool(h_SbStopCvar, false);
		h_ResetSbStopTimer = INVALID_HANDLE;
		return Plugin_Stop;
	}
	
	new i_MaxClientsLoading = GetConVarInt(h_CvarMaxClientsLoading);
	new i_ClientsLoading = GetClientCount(false) - GetClientCount(true);
	
	if (i_ClientsLoading > i_MaxClientsLoading)
	{
		return Plugin_Continue;
	}
	
	SetConVarBool(h_SbStopCvar, false);
	h_ResetSbStopTimer = INVALID_HANDLE;
	return Plugin_Stop;
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if (b_BlockUse)
	{
		if ((GetClientTeam(client) == 2) && (buttons & IN_USE))
		{
			if (GetConVarInt(h_CvarShowMessage) && !b_ShowedMsg[client])
			{
				PrintHintText(client, "Updating weapon spawns, one moment please.");
				b_ShowedMsg[client] = true;
				return Plugin_Handled;
			}
			
			return Plugin_Handled;
		}
		
		return Plugin_Continue;
	}
	
	return Plugin_Continue;
}

ReplaceDefined(const String:s_WeaponSpawn[], const i_Index)
{
	new i_EdictIndex = -1;
	
	while ((i_EdictIndex = FindEntityByClassname(i_EdictIndex, s_WeaponSpawn)) != INVALID_ENT_REFERENCE)
	{
		new Float:v_Origin[3], Float:v_Angles[3];
		
		GetEntPropVector(i_EdictIndex, Prop_Send, "m_vecOrigin", v_Origin);
		GetEntPropVector(i_EdictIndex, Prop_Send, "m_angRotation", v_Angles);
		
		AcceptEntityInput(i_EdictIndex, "Kill");
		
		new i_GunCount = GetConVarInt(h_CvarGunCount);
		
		for (new i = 1; i <= i_GunCount; i++)
		{
			new i_NewEdict = CreateEntityByName(s_Weapons[i_Index]);
			
			DispatchKeyValueVector(i_NewEdict, "origin", v_Origin);
			DispatchKeyValueVector(i_NewEdict, "angles", v_Angles);
			DispatchKeyValue(i_NewEdict, "spawnflags", "1");
			DispatchSpawn(i_NewEdict);
			SetEntProp(i_NewEdict, Prop_Send, "m_iExtraPrimaryAmmo", i_WeaponsAmmo[i_Index]);
		}
	}
}

ReplaceRandom(const String:s_WeaponSpawn[])
{
	new i_EdictIndex = -1;
	
	while ((i_EdictIndex = FindEntityByClassname(i_EdictIndex, s_WeaponSpawn)) != INVALID_ENT_REFERENCE)
	{
		new i_WeaponId = GetEntProp(i_EdictIndex, Prop_Send, "m_weaponID");
		new i_Index = CheckWeaponId(i_WeaponId);
		
		if (i_Index != -1)
		{
			new Float:v_Origin[3], Float:v_Angles[3];
			
			GetEntPropVector(i_EdictIndex, Prop_Send, "m_vecOrigin", v_Origin);
			GetEntPropVector(i_EdictIndex, Prop_Send, "m_angRotation", v_Angles);
			
			AcceptEntityInput(i_EdictIndex, "Kill");
			
			new i_GunCount = GetConVarInt(h_CvarGunCount);
			
			for (new i = 1; i <= i_GunCount; i++)
			{
				new i_NewEdict = CreateEntityByName(s_Weapons[i_Index]);
				
				DispatchKeyValueVector(i_NewEdict, "origin", v_Origin);
				DispatchKeyValueVector(i_NewEdict, "angles", v_Angles);
				DispatchKeyValue(i_NewEdict, "spawnflags", "1");
				DispatchSpawn(i_NewEdict);
				SetEntProp(i_NewEdict, Prop_Send, "m_iExtraPrimaryAmmo", i_WeaponsAmmo[i_Index]);
			}
		}
	}
}

CheckWeaponId(const i_WeaponId)
{
	new i_Index = -1;
	
	for (new i = 0; i < sizeof(i_WeaponIds); i++)
	{
		if (i_WeaponId == i_WeaponIds[i])
		{
			new i_GunTypes = GetConVarInt(h_CvarGunTypes);
			
			if (i_GunTypes & TIER2)
			{
				for (new j = 0; j < sizeof(i_Tier2Index1); j++)
				{
					if (i == i_Tier2Index1[j])
					{
						i_Index = i;
						return i_Index;
					}
				}
				
				for (new j = 0; j < sizeof(i_Tier2Index2); j++)
				{
					if (i == i_Tier2Index2[j])
					{
						i_Index = i;
						return i_Index;
					}
				}
			}
			
			if (i_GunTypes & TIER1)
			{
				for (new j = 0; j < sizeof(i_Tier1Index1); j++)
				{
					if (i == i_Tier1Index1[j])
					{
						i_Index = i;
						return i_Index;
					}
				}
				
				for (new j = 0; j < sizeof(i_Tier1Index2); j++)
				{
					if (i == i_Tier1Index2[j])
					{
						i_Index = i;
						return i_Index;
					}
				}
			}
			
			if ((i_GunTypes & MAGNUM) && (i == i_MagnumIndex))
			{
				i_Index = i;
				return i_Index;
			}
			
			if ((i_GunTypes & PISTOL) && (i == i_PistolIndex))
			{
				i_Index = i;
				return i_Index;
			}
		}
	}
	
	return i_Index;
}
