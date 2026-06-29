#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "0.1"

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

static const Float:f_RoundStartDelay = 10.0;
static const Float:f_ResetSbStopInterval = 5.0;
static const i_ResetSbStopMaxDelay = 60;
static const i_MaxClientsLoading = 1;

new Handle:h_SbStopCvar;

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
	if (!StrEqual(s_Game, "left4dead2", false) && !StrEqual(s_Game, "left4dead2", false))
	{
		SetFailState("Plugin supports 'Left 4 Dead' and 'Left 4 Dead 2' only.");
	}
	
	CreateConVar("l4d_1gunspawns_version", PLUGIN_VERSION, "Version of the '[L4D & L4D2] Single Guns Spawns' Plugin", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_SPONLY|FCVAR_DONTRECORD);
	
	h_SbStopCvar = FindConVar("sb_stop");
	
	HookEvent("round_start", Event_RoundStart);
}

public Event_RoundStart(Handle:h_Event, const String:s_Name[], bool:b_DontBroadcast)
{
	for (new i = 0; i < MAXPLAYERS+1; i++)
	{
		b_ShowedMsg[i] = false;
	}
	
	SetConVarBool(h_SbStopCvar, true);
	b_BlockUse = true;
	
	CreateTimer(f_RoundStartDelay, RoundStartDelayed, INVALID_HANDLE, TIMER_FLAG_NO_MAPCHANGE);
}

public Action:RoundStartDelayed(Handle:h_RoundStartTimer)
{
	ReplaceRandom("weapon_spawn");
	
	for (new i = 0; i < sizeof(s_WeaponSpawns); i++)
	{
		ReplaceDefined(s_WeaponSpawns[i], i);
	}
	
	new i_StartTime = RoundToNearest(GetGameTime());

	CreateTimer(f_ResetSbStopInterval, ResetSbStop, i_StartTime, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	b_BlockUse = false;
	
	return Plugin_Stop;
}

public Action:ResetSbStop(Handle:h_Timer, any:i_StartTime)
{
	if (RoundToNearest(GetGameTime()) - i_StartTime >= i_ResetSbStopMaxDelay)
	{
		SetConVarBool(h_SbStopCvar, false);
		return Plugin_Stop;
	}
	
	if (GetClientCount(false) - GetClientCount(true) > i_MaxClientsLoading)
	{
		return Plugin_Continue;
	}
	
	SetConVarBool(h_SbStopCvar, false);
	return Plugin_Stop;
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if (b_BlockUse)
	{
		if ((GetClientTeam(client) == 2) && (buttons & IN_USE))
		{
			if (!b_ShowedMsg[client])
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
		
		new i_NewEdict = CreateEntityByName(s_Weapons[i_Index]);
		
		DispatchKeyValueVector(i_NewEdict, "origin", v_Origin);
		DispatchKeyValueVector(i_NewEdict, "angles", v_Angles);
		DispatchKeyValue(i_NewEdict, "spawnflags", "1");
		DispatchSpawn(i_NewEdict);
		SetEntProp(i_NewEdict, Prop_Send, "m_iExtraPrimaryAmmo", i_WeaponsAmmo[i_Index]);
	}
}

ReplaceRandom(const String:s_WeaponSpawn[])
{
	new i_EdictIndex = -1;
	
	while ((i_EdictIndex = FindEntityByClassname(i_EdictIndex, s_WeaponSpawn)) != INVALID_ENT_REFERENCE)
	{
		new i_WeaponId = GetEntProp(i_EdictIndex, Prop_Send, "m_weaponID");
		new i_Index = FindWeaponIdIndex(i_WeaponId);
		
		if (i_Index != -1)
		{
			new Float:v_Origin[3], Float:v_Angles[3];
			
			GetEntPropVector(i_EdictIndex, Prop_Send, "m_vecOrigin", v_Origin);
			GetEntPropVector(i_EdictIndex, Prop_Send, "m_angRotation", v_Angles);
			
			AcceptEntityInput(i_EdictIndex, "Kill");
			
			new i_NewEdict = CreateEntityByName(s_Weapons[i_Index]);
			
			DispatchKeyValueVector(i_NewEdict, "origin", v_Origin);
			DispatchKeyValueVector(i_NewEdict, "angles", v_Angles);
			DispatchKeyValue(i_NewEdict, "spawnflags", "1");
			DispatchSpawn(i_NewEdict);
			SetEntProp(i_NewEdict, Prop_Send, "m_iExtraPrimaryAmmo", i_WeaponsAmmo[i_Index]);
		}
	}
}

FindWeaponIdIndex(const i_WeaponId)
{
	new i_Index = -1;
	
	for (new i = 0; i < sizeof(i_WeaponIds); i++)
	{
		if (i_WeaponId == i_WeaponIds[i])
		{
			i_Index = i;
			return i_Index;
		}
		
		return i_Index;
	}
	
	return i_Index;
}
