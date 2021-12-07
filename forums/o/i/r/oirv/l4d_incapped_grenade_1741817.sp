/*

	Created by DJ_WEST
	
	Web: http://amx-x.ru
	AMX Mod X and SourceMod Russian Community
	
*/

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.5"

#define MODEL_V_PIPEBOMB "models/v_models/v_pipebomb.mdl"
#define MODEL_V_MOLOTOV "models/v_models/v_molotov.mdl"
#define MODEL_V_VOMITJAR "models/v_models/v_bile_flask.mdl"
#define MODEL_V_PISTOL_1 "models/v_models/v_pistol.mdl"
#define MODEL_V_PISTOL_2 "models/v_models/v_pistola.mdl"
#define MODEL_V_DUALPISTOL_1 "models/v_models/v_dualpistols.mdl"
#define MODEL_V_DUALPISTOL_2 "models/v_models/v_dual_pistola.mdl"
#define MODEL_V_MAGNUM "models/v_models/v_desert_eagle.mdl"
#define MODEL_GASCAN "models/props_junk/gascan001a.mdl"
#define MODEL_PROPANE "models/props_junk/propanecanister001a.mdl"
#define MODEL_W_PIPEBOMB "models/w_models/weapons/w_eq_pipebomb.mdl"
#define MODEL_W_MOLOTOV "models/w_models/weapons/w_eq_molotov.mdl"
#define MODEL_W_VOMITJAR "models/w_models/weapons/w_eq_bile_flask.mdl"
#define SOUND_PIPEBOMB "weapons/hegrenade/beep.wav"
#define SOUND_VOMITJAR ")weapons/ceda_jar/ceda_jar_explode.wav"
#define SOUND_MOLOTOV "weapons/molotov/fire_ignite_2.wav"
#define SOUND_PISTOL "weapons/pistol/gunfire/pistol_fire.wav"
#define SOUND_DUAL_PISTOL ")weapons/pistol/gunfire/pistol_dual_fire.wav"
#define SOUND_MAGNUM ")weapons/magnum/gunfire/magnum_shoot.wav"

#define BOUNCE_TIME 10
#define TEAM_SURVIVOR 2

new const String:g_VoicePipebombNick[7][] =
{
	"grenade01",
	"grenade02",
	"grenade05",
	"grenade07",
	"grenade09",
	"grenade11",
	"grenade13"
}

new const String:g_VoiceMolotovNick[4][] =
{
	"grenade03",
	"grenade04",
	"grenade06",
	"grenade08"
}

new const String:g_VoiceVomitjarNick[][] =
{
	"boomerjar08",
	"boomerjar09",
	"boomerjar10"
}

new const String:g_VoicePipebombRochelle[4][] =
{
	"grenade01",
	"grenade02",
	"grenade05",
	"grenade07"
}

new const String:g_VoiceMolotovRochelle[3][] =
{
	"grenade03",
	"grenade04",
	"grenade06"
}

new const String:g_VoiceVomitjarRochelle[3][] =
{
	"boomerjar07",
	"boomerjar08",
	"boomerjar09"
}

new const String:g_VoicePipebombCoach[6][] =
{
	"grenade01",
	"grenade03",
	"grenade06",
	"grenade07",
	"grenade11",
	"grenade12"
}

new const String:g_VoiceMolotovCoach[3][] =
{
	"grenade02",
	"grenade04",
	"grenade05"
}

new const String:g_VoiceVomitjarCoach[3][] =
{
	"boomerjar09",
	"boomerjar10",
	"boomerjar11"
}

new const String:g_VoicePipebombEllis[8][] =
{
	"grenade01",
	"grenade02",
	"grenade03",
	"grenade07",
	"grenade09",
	"grenade11",
	"grenade12",
	"grenade13"
}

new const String:g_VoiceMolotovEllis[4][] =
{
	"grenade05",
	"grenade06",
	"grenade08",
	"grenade10"
}

new const String:g_VoiceVomitjarEllis[6][] =
{
	"boomerjar08",
	"boomerjar09",
	"boomerjar10",
	"boomerjar12",
	"boomerjar13",
	"boomerjar14"
}

new const String:g_VoiceFrancisBill[6][] =
{
	"grenade01",
	"grenade02",
	"grenade03",
	"grenade04",
	"grenade05",
	"grenade06"
}

new const String:g_VoiceZoey[6][] =
{
	"grenade02",
	"grenade04",
	"grenade09",
	"grenade10",
	"grenade12",
	"grenade13"
}

new const String:g_VoiceLouis[7][] =
{
	"grenade01",
	"grenade02",
	"grenade03",
	"grenade04",
	"grenade05",
	"grenade06",
	"grenade07"
}

enum GRENADE_TYPE
{
	NONE,
	PIPEBOMB,
	MOLOTOV,
	VOMITJAR
}

enum GAME_MOD
{
	LEFT4DEAD,
	LEFT4DEAD2
}

new g_ActiveWeaponOffset, g_PipebombModel, g_MolotovModel, g_VomitjarModel, GRENADE_TYPE:g_PlayerIncapacitated[MAXPLAYERS+1], 
	Float:g_PlayerGameTime[MAXPLAYERS+1], GAME_MOD:g_Mod, g_ThrewGrenade[MAXPLAYERS+1], 
	g_PipebombBounce[MAXPLAYERS+1], bool:g_b_InAction[MAXPLAYERS+1], Handle:g_h_GrenadeTimer[MAXPLAYERS+1], bool:g_b_AllowThrow[MAXPLAYERS+1], 
	Handle:g_t_PipeTicks, Handle:h_CvarVomitjarSpeed, Handle:h_CvarPipebombSpeed, Handle:h_CvarMolotovSpeed, Handle:h_CvarPipebombDuration,
	Handle:h_CvarVomitjarDuration, Handle:h_CvarVomitjarGlowDuration, Handle:h_CvarVomitjarRadius, Handle:h_CvarMessageType,
	g_PistolModel, g_DualPistolModel, g_MagnumModel, Handle:g_t_GrenadeOwner, g_GameInstructor[MAXPLAYERS+1]

public Plugin:myinfo =
{
	name = "Incapped Grenade (Pipe, Molotov, Vomitjar)",
	author = "DJ_WEST",
	description = "Throw a pipebomb/molotov/vomitjar while the player is incapacitated",
	version = PLUGIN_VERSION,
	url = "http://amx-x.ru"
}

public OnPluginStart()
{
	decl String:s_Game[12], Handle:h_Version
	
	GetGameFolderName(s_Game, sizeof(s_Game))
	if (StrEqual(s_Game, "left4dead"))
		g_Mod = LEFT4DEAD
	else if (StrEqual(s_Game, "left4dead2"))
		g_Mod = LEFT4DEAD2
	else
		SetFailState("Incapped Grenade supports Left 4 Dead and Left 4 Dead 2 only!")
		
	LoadTranslations("incapped_grenade.phrases")
	
	g_ActiveWeaponOffset = FindSendPropInfo("CBasePlayer", "m_hActiveWeapon")
		
	h_Version = CreateConVar("incapped_grenade_version", PLUGIN_VERSION, "Incapped Grenade version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY)
	h_CvarPipebombSpeed = CreateConVar("l4d_incapped_pipebomb_speed", "600.0", "Pipebomb speed", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 300.0, true, 1000.0)
	h_CvarMolotovSpeed = CreateConVar("l4d_incapped_molotov_speed", "700.0", "Molotov speed", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 300.0, true, 1000.0)
	h_CvarPipebombDuration = CreateConVar("l4d_incapped_pipebomb_duration", "6.0", "Pipebomb duration", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 30.0)
	h_CvarMessageType = CreateConVar("l4d_incapped_message_type", "3", "Message type (0 - disable, 1 - chat, 2 - hint, 3 - instructor hint)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 2.0)
	
	HookEvent("mission_lost", EventMissionLost);	
	HookEvent("player_incapacitated", EventPlayerIncapacitated)
	HookEvent("revive_success", EventReviveSuccess)
	HookEvent("revive_begin", EventReviveBegin)
	HookEvent("revive_end", EventReviveEnd)
	HookEvent("player_death", EventPlayerDeath)
	HookEvent("grenade_bounce", EventGrenadeBounce)
	HookEvent("player_team", EventPlayerTeam)
	HookEvent("round_end", EventRoundEnd)
	HookEvent("pounce_stopped", EventAllowThrow)
	HookEvent("tongue_release", EventAllowThrow)
	
	if (g_Mod == LEFT4DEAD2)
	{
		HookEvent("charger_pummel_end", EventAllowThrow)
		HookEvent("defibrillator_used", EventAllowThrow)
		h_CvarVomitjarDuration = CreateConVar("l4d_incapped_vomitjar_duration", "15.0", "Vomitjar duration", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 30.0)
		h_CvarVomitjarSpeed = CreateConVar("l4d_incapped_vomitjar_speed", "700.0", "Vomitjar speed", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 300.0, true, 1000.0)
		h_CvarVomitjarGlowDuration = CreateConVar("l4d_incapped_vomitjar_glowduration", "20.0", "Vomitjar glow duration", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 50.0)
		h_CvarVomitjarRadius = CreateConVar("l4d_incapped_vomitjar_radius", "110.0", "Vomitjar radius", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 500.0)
	}
			
	g_t_PipeTicks = CreateTrie()
	g_t_GrenadeOwner = CreateTrie() 
	
	SetConVarString(h_Version, PLUGIN_VERSION)
}

public Action:EventMissionLost(Handle:h_Event, const String:s_Name[], bool:b_DontBroadcast)
{
	// if the round restart, nobody can throw grenades
	
	for (new client=1;client<=MaxClients;client++)
	{
		if (GetClientTeam(client) == TEAM_SURVIVOR)
			g_b_AllowThrow[client] = false
	}		
	
	
}

public Action:EventRoundEnd(Handle:h_Event, const String:s_Name[], bool:b_DontBroadcast)
{
	for (new i = 1; i <= MaxClients; i++)
		if (g_h_GrenadeTimer[i] != INVALID_HANDLE)
		{
			KillTimer(g_h_GrenadeTimer[i])
			g_h_GrenadeTimer[i] = INVALID_HANDLE
		}	
}

public Action:EventPlayerTeam(Handle:h_Event, const String:s_Name[], bool:b_DontBroadcast)
{
	if (!GetEventBool(h_Event, "isbot"))
	{
		decl i_UserID, i_Client
	
		i_UserID = GetEventInt(h_Event, "userid")
		i_Client = GetClientOfUserId(i_UserID)
		
		if (GetEventInt(h_Event, "team") == TEAM_SURVIVOR)
			CreateTimer(0.1, DelayCheckPlayer, i_Client)
	}
}

public Action:DelayCheckPlayer(Handle:h_Timer, any:i_Client)
{
	if (i_Client < 0 || !IsClientInGame(i_Client))
		return Plugin_Continue
		
	if (GetEntProp(i_Client, Prop_Send, "m_isIncapacitated") && GetGrenadeOnIncap(i_Client) > 0 )
		g_b_AllowThrow[i_Client] = true
	else
		g_b_AllowThrow[i_Client] = false
	
	return Plugin_Continue
}

public Action:EventReviveBegin(Handle:h_Event, const String:s_Name[], bool:b_DontBroadcast)
{
	decl i_UserID, i_Client, i_Weapon
	
	i_UserID = GetEventInt(h_Event, "subject")
	i_Client = GetClientOfUserId(i_UserID)
	
	if (!i_Client || !IsClientInGame(i_Client))
		return Plugin_Handled
		
	i_Weapon = GetEntDataEnt2(i_Client, g_ActiveWeaponOffset)
	g_b_InAction[i_Client] = false

	if (i_Weapon != -1)
	{
		SetPlayerWeaponModel(i_Client, i_Weapon)
		SetEntPropFloat(i_Weapon, Prop_Send, "m_flNextPrimaryAttack", GetGameTime())
	}
		
	g_b_AllowThrow[i_Client] = false
	
	return Plugin_Continue
}

public Action:EventReviveEnd(Handle:h_Event, const String:s_Name[], bool:b_DontBroadcast)
{
	decl i_UserID, i_Client
		
	i_UserID = GetEventInt(h_Event, "subject")
	i_Client = GetClientOfUserId(i_UserID)
		
	g_b_AllowThrow[i_Client] = true
}

public SetPlayerWeaponModel(i_Client, i_Weapon)
{
	decl i_Viewmodel, String:s_ClassName[32]
	
	i_Viewmodel = GetEntPropEnt(i_Client, Prop_Send, "m_hViewModel")
	GetEdictClassname(i_Weapon, s_ClassName, sizeof(s_ClassName))
	
	if (StrEqual(s_ClassName, "weapon_pistol_magnum"))
		SetEntProp(i_Viewmodel, Prop_Send, "m_nModelIndex", g_MagnumModel)
	else if (StrEqual(s_ClassName, "weapon_pistol"))
	{
		if (GetEntProp(i_Weapon, Prop_Send, "m_hasDualWeapons"))
			SetEntProp(i_Viewmodel, Prop_Send, "m_nModelIndex", g_DualPistolModel, 2)
		else
			SetEntProp(i_Viewmodel, Prop_Send, "m_nModelIndex", g_PistolModel, 2)
	}
	SetEntProp(i_Viewmodel, Prop_Send, "m_nLayerSequence", 1)
}

public Action:EventReviveSuccess(Handle:h_Event, const String:s_Name[], bool:b_DontBroadcast)
{
	decl i_UserID, i_Client, i_Weapon
	
	i_UserID = GetEventInt(h_Event, "subject")
	i_Client = GetClientOfUserId(i_UserID)
	
	if (!i_Client || !IsClientInGame(i_Client))
		return Plugin_Handled
		
	i_Weapon = GetEntDataEnt2(i_Client, g_ActiveWeaponOffset)
	
	if (i_Weapon != -1)
		SetPlayerWeaponModel(i_Client, i_Weapon)
	
	g_PlayerIncapacitated[i_Client] = NONE
	g_b_AllowThrow[i_Client] = false

	return Plugin_Continue
}

public Action:EventAllowThrow(Handle:h_Event, const String:s_Name[], bool:b_DontBroadcast)
{
	decl i_UserID, i_Client
	
	if (GetEventInt(h_Event, "victim"))
		i_UserID = GetEventInt(h_Event, "victim")
	else if (GetEventInt(h_Event, "subject"))
		i_UserID = GetEventInt(h_Event, "subject")
		
	i_Client = GetClientOfUserId(i_UserID)

	if (g_PlayerIncapacitated[i_Client])
		g_b_AllowThrow[i_Client] = true
	else
		g_b_AllowThrow[i_Client] = false
}

public ThrowMolotov(i_Client)
{
	decl i_Ent, Float:f_Origin[3], Float:f_Speed[3], Float:f_Angles[3], String:s_TargetName[32], Float:f_CvarSpeed, String:s_Ent[4]
	
	i_Ent = CreateEntityByName("molotov_projectile")
	
	if (IsValidEntity(i_Ent))
	{
		SetEntPropEnt(i_Ent, Prop_Data, "m_hOwnerEntity", i_Client)
		SetEntityModel(i_Ent, MODEL_W_MOLOTOV)
		FormatEx(s_TargetName, sizeof(s_TargetName), "molotov%d", i_Ent)
		DispatchKeyValue(i_Ent, "targetname", s_TargetName)
		DispatchSpawn(i_Ent)
	}
	
	g_ThrewGrenade[i_Client] = i_Ent

	GetClientEyePosition(i_Client, f_Origin)
	GetClientEyeAngles(i_Client, f_Angles)
	GetAngleVectors(f_Angles, f_Speed, NULL_VECTOR, NULL_VECTOR)
	f_CvarSpeed = GetConVarFloat(h_CvarMolotovSpeed)
	
	f_Speed[0] *= f_CvarSpeed
	f_Speed[1] *= f_CvarSpeed
	f_Speed[2] *= f_CvarSpeed
	
	GetRandomAngles(f_Angles)
	TeleportEntity(i_Ent, f_Origin, f_Angles, f_Speed)
	EmitSoundToAll(SOUND_MOLOTOV, 0, SNDCHAN_WEAPON, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, f_Origin, NULL_VECTOR, false, 0.0)

	IntToString(i_Ent, s_Ent, sizeof(s_Ent))
	SetTrieValue(g_t_GrenadeOwner, s_Ent, i_Client)
	
	g_h_GrenadeTimer[i_Client] = CreateTimer(0.1, MolotovThink, i_Ent, TIMER_REPEAT)
}

public Action:MolotovThink(Handle:h_Timer, any:i_Ent)
{
	decl i_Client, String:s_Ent[4], String:s_ClassName[32]

	IntToString(i_Ent, s_Ent, sizeof(s_Ent))
	GetTrieValue(g_t_GrenadeOwner, s_Ent, i_Client)
	GetEdictClassname(i_Ent, s_ClassName, sizeof(s_ClassName))
	
	if (!IsValidEdict(i_Ent) || StrContains(s_ClassName, "projectile") == -1)
	{
		if (g_h_GrenadeTimer[i_Client] != INVALID_HANDLE)
		{
			KillTimer(g_h_GrenadeTimer[i_Client])
			g_h_GrenadeTimer[i_Client] = INVALID_HANDLE
			g_ThrewGrenade[i_Client] = 0
			RemoveFromTrie(g_t_GrenadeOwner, s_Ent)
		}
		
		return Plugin_Handled
	}
	
	decl Float:f_Origin[3]

	GetEntPropVector(i_Ent, Prop_Send, "m_vecOrigin", f_Origin)
	
	if (0.0 < OnGroundUnits(i_Ent) <= 10.0)
	{	
		if (g_h_GrenadeTimer[i_Client] != INVALID_HANDLE)
		{
			KillTimer(g_h_GrenadeTimer[i_Client])
			g_h_GrenadeTimer[i_Client] = INVALID_HANDLE
		}	
		
		g_ThrewGrenade[i_Client] = 0
		RemoveEdict(i_Ent)
		
		i_Ent = CreateEntityByName("prop_physics")
		DispatchKeyValue(i_Ent, "physdamagescale", "0.0")
		DispatchKeyValue(i_Ent, "model", MODEL_GASCAN)
		DispatchSpawn(i_Ent)
		TeleportEntity(i_Ent, f_Origin, NULL_VECTOR, NULL_VECTOR)
		SetEntityMoveType(i_Ent, MOVETYPE_VPHYSICS)
		AcceptEntityInput(i_Ent, "Break")
		
		return Plugin_Continue
	}
	else
	{
		decl Float:f_Angles[3]
		
		GetRandomAngles(f_Angles)
		TeleportEntity(i_Ent, NULL_VECTOR, f_Angles, NULL_VECTOR)
	}
	
	return Plugin_Continue
}

public ThrowVomitjar(i_Client)
{
	decl i_Ent, Float:f_Position[3], Float:f_Speed[3], Float:f_Angles[3], String:s_TargetName[32], Float:f_CvarSpeed, String:s_Ent[4]
	
	i_Ent = CreateEntityByName("vomitjar_projectile")
	
	if (IsValidEntity(i_Ent))
	{
		SetEntPropEnt(i_Ent, Prop_Data, "m_hOwnerEntity", i_Client)
		SetEntityModel(i_Ent, MODEL_W_VOMITJAR)
		FormatEx(s_TargetName, sizeof(s_TargetName), "vomitjar%d", i_Ent)
		DispatchKeyValue(i_Ent, "targetname", s_TargetName)
		DispatchSpawn(i_Ent)
	}
	
	g_ThrewGrenade[i_Client] = i_Ent

	GetClientEyePosition(i_Client, f_Position)
	GetClientEyeAngles(i_Client, f_Angles)
	GetAngleVectors(f_Angles, f_Speed, NULL_VECTOR, NULL_VECTOR)
	f_CvarSpeed = GetConVarFloat(h_CvarVomitjarSpeed)
	
	f_Speed[0] *= f_CvarSpeed
	f_Speed[1] *= f_CvarSpeed
	f_Speed[2] *= f_CvarSpeed
	
	GetRandomAngles(f_Angles)
	TeleportEntity(i_Ent, f_Position, f_Angles, f_Speed)
	
	IntToString(i_Ent, s_Ent, sizeof(s_Ent))
	SetTrieValue(g_t_GrenadeOwner, s_Ent, i_Client)

	g_h_GrenadeTimer[i_Client] = CreateTimer(0.1, VomitjarThink, i_Ent, TIMER_REPEAT)
}

public Action:VomitjarThink(Handle:h_Timer, any:i_Ent)
{
	decl i_Client, String:s_Ent[4], String:s_ClassName[32]

	IntToString(i_Ent, s_Ent, sizeof(s_Ent))
	GetTrieValue(g_t_GrenadeOwner, s_Ent, i_Client)
	GetEdictClassname(i_Ent, s_ClassName, sizeof(s_ClassName))
	
	if (!IsValidEdict(i_Ent) || StrContains(s_ClassName, "projectile") == -1)
	{
		if (g_h_GrenadeTimer[i_Client] != INVALID_HANDLE)
		{
			KillTimer(g_h_GrenadeTimer[i_Client])
			g_h_GrenadeTimer[i_Client] = INVALID_HANDLE
			g_ThrewGrenade[i_Client] = 0
			RemoveFromTrie(g_t_GrenadeOwner, s_Ent)
		}	
		
		return Plugin_Handled
	}
	
	decl Float:f_Origin[3]

	GetEntPropVector(i_Ent, Prop_Send, "m_vecOrigin", f_Origin)
	
	if (0.0 < OnGroundUnits(i_Ent) <= 15.0)
	{
		decl Float:f_EntOrigin[3], i_MaxEntities, String:s_ModelName[64], i_InfoEnt, Float:f_CvarDuration
		
		if (g_h_GrenadeTimer[i_Client] != INVALID_HANDLE)
		{
			KillTimer(g_h_GrenadeTimer[i_Client])
			g_h_GrenadeTimer[i_Client] = INVALID_HANDLE
		}	
		
		g_ThrewGrenade[i_Client] = 0
		EmitSoundToAll(SOUND_VOMITJAR, 0, SNDCHAN_WEAPON, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, f_Origin, NULL_VECTOR, false, 0.0)
		f_CvarDuration = GetConVarFloat(h_CvarVomitjarDuration)
		RemoveEdict(i_Ent)
		DisplayParticle(f_Origin, "vomit_jar", f_CvarDuration)
		
		i_InfoEnt = CreateEntityByName("info_goal_infected_chase")
		DispatchKeyValueVector(i_InfoEnt, "origin", f_Origin)
		DispatchSpawn(i_InfoEnt)
		AcceptEntityInput(i_InfoEnt, "Enable")
		CreateTimer(f_CvarDuration, DeleteEntity, i_InfoEnt)
		
		i_MaxEntities = GetMaxEntities()
		for (new i = 1; i <= i_MaxEntities; i++)
		{
			if (IsValidEdict(i) && IsValidEntity(i))
			{
				GetEntPropString(i, Prop_Data, "m_ModelName", s_ModelName, sizeof(s_ModelName))

				if (StrContains(s_ModelName, "infected") != -1)
				{
					GetEntPropVector(i, Prop_Send, "m_vecOrigin", f_EntOrigin)
					
					if (GetVectorDistance(f_Origin, f_EntOrigin) <= GetConVarFloat(h_CvarVomitjarRadius))
					{
						SetEntProp(i, Prop_Send, "m_iGlowType", 3)
						SetEntProp(i, Prop_Send, "m_glowColorOverride", -4713783)
						CreateTimer(GetConVarFloat(h_CvarVomitjarGlowDuration), DisableGlow, i)
					}
				}
			}
		}
		
		return Plugin_Continue
	}
	else
	{
		decl Float:f_Angles[3]
		
		GetRandomAngles(f_Angles)
		TeleportEntity(i_Ent, NULL_VECTOR, f_Angles, NULL_VECTOR)
	}
	
	return Plugin_Continue
}

public ThrowPipebomb(i_Client)
{
	decl i_Ent, Float:f_Position[3], Float:f_Angles[3], Float:f_Speed[3], String:s_Ent[4], String:s_TargetName[32],
		Float:f_CvarSpeed
	
	i_Ent = CreateEntityByName("pipe_bomb_projectile")
	
	if (IsValidEntity(i_Ent))
	{
		SetEntPropEnt(i_Ent, Prop_Data, "m_hOwnerEntity", i_Client)
		SetEntityModel(i_Ent, MODEL_W_PIPEBOMB)
		FormatEx(s_TargetName, sizeof(s_TargetName), "pipebomb%d", i_Ent)
		DispatchKeyValue(i_Ent, "targetname", s_TargetName)
		DispatchSpawn(i_Ent)
	}
	
	g_ThrewGrenade[i_Client] = i_Ent

	GetClientEyePosition(i_Client, f_Position)
	GetClientEyeAngles(i_Client, f_Angles)
	GetAngleVectors(f_Angles, f_Speed, NULL_VECTOR, NULL_VECTOR)
	f_CvarSpeed = GetConVarFloat(h_CvarPipebombSpeed)
	
	f_Speed[0] *= f_CvarSpeed
	f_Speed[1] *= f_CvarSpeed
	f_Speed[2] *= f_CvarSpeed
	
	GetRandomAngles(f_Angles)
	TeleportEntity(i_Ent, f_Position, f_Angles, f_Speed)
	AttachParticle(i_Ent, "weapon_pipebomb_blinking_light", f_Position)
	AttachParticle(i_Ent, "weapon_pipebomb_fuse", f_Position)
	AttachInfected(i_Ent, f_Position)
	
	IntToString(i_Ent, s_Ent, sizeof(s_Ent))
	SetTrieValue(g_t_PipeTicks, s_Ent, 0)
	SetTrieValue(g_t_GrenadeOwner, s_Ent, i_Client)
	
	g_h_GrenadeTimer[i_Client] = CreateTimer(0.1, PipebombThink, i_Ent, TIMER_REPEAT)
}

public Action:PipebombThink(Handle:h_Timer, any:i_Ent)
{
	decl i_Client, String:s_Ent[4], String:s_ClassName[32]

	IntToString(i_Ent, s_Ent, sizeof(s_Ent))
	GetTrieValue(g_t_GrenadeOwner, s_Ent, i_Client)
	GetEdictClassname(i_Ent, s_ClassName, sizeof(s_ClassName))
	
	if (!IsValidEdict(i_Ent) || StrContains(s_ClassName, "projectile") == -1)
	{
		if (g_h_GrenadeTimer[i_Client] != INVALID_HANDLE)
		{
			KillTimer(g_h_GrenadeTimer[i_Client])
			g_h_GrenadeTimer[i_Client] = INVALID_HANDLE
			g_ThrewGrenade[i_Client] = 0
			g_PipebombBounce[i_Client] = 0
			RemoveFromTrie(g_t_PipeTicks, s_Ent)
			RemoveFromTrie(g_t_GrenadeOwner, s_Ent)
		}
		
		return Plugin_Handled
	}
	
	decl i_Count, Float:f_Angles[3], Float:f_Origin[3], Float:f_Units, Float:f_CvarDuration
	
	GetTrieValue(g_t_PipeTicks, s_Ent, i_Count)
	GetEntPropVector(i_Ent, Prop_Send, "m_vecOrigin", f_Origin)
	f_CvarDuration = GetConVarFloat(h_CvarPipebombDuration) * 10
	
	if (i_Count >= f_CvarDuration)
	{
		if (g_h_GrenadeTimer[i_Client] != INVALID_HANDLE)
		{
			KillTimer(g_h_GrenadeTimer[i_Client])
			g_h_GrenadeTimer[i_Client] = INVALID_HANDLE
		}	
		
		g_ThrewGrenade[i_Client] = 0
		g_PipebombBounce[i_Client] = 0
		RemoveFromTrie(g_t_PipeTicks, s_Ent)
		RemoveFromTrie(g_t_GrenadeOwner, s_Ent)
		RemoveEdict(i_Ent)
		
		i_Ent = CreateEntityByName("prop_physics")
		DispatchKeyValue(i_Ent, "physdamagescale", "0.0")
		DispatchKeyValue(i_Ent, "model", MODEL_PROPANE)
		DispatchSpawn(i_Ent)
		TeleportEntity(i_Ent, f_Origin, NULL_VECTOR, NULL_VECTOR)
		SetEntityMoveType(i_Ent, MOVETYPE_VPHYSICS)
		AcceptEntityInput(i_Ent, "Break")
		
		return Plugin_Continue
	}
	
	if (i_Count >= BOUNCE_TIME)
	{
		f_Angles[0] = 90.0
		f_Angles[1] = 0.0
		f_Angles[2] = 0.0
			
		TeleportEntity(i_Ent, NULL_VECTOR, f_Angles, NULL_VECTOR)
		
		f_Units = OnGroundUnits(i_Ent)
		
		if (0.0 < f_Units <= 7.0)
		{
			f_Origin[2] -= f_Units - 2.0
			SetEntPropVector(i_Ent, Prop_Send, "m_vecOrigin", f_Origin)
			SetEntityMoveType(i_Ent, MOVETYPE_NONE)
		}
	}
	else
	{
		GetRandomAngles(f_Angles)
		TeleportEntity(i_Ent, NULL_VECTOR, f_Angles, NULL_VECTOR)
	}
	
	switch (i_Count)
	{
		case 4,8,12,16,20,23,26,29,32,35,37,39,41,43,45:
			EmitSoundToAll(SOUND_PIPEBOMB, 0, SNDCHAN_WEAPON, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, f_Origin, NULL_VECTOR, false, 0.0)
	}
	
	if (i_Count > 45)
		EmitSoundToAll(SOUND_PIPEBOMB, 0, SNDCHAN_WEAPON, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, f_Origin, NULL_VECTOR, false, 0.0)
	
	i_Count++
	SetTrieValue(g_t_PipeTicks, s_Ent, i_Count)
	
	return Plugin_Continue
}

public Action:DisableGlow(Handle:h_Timer, any:i_Ent)
{
	decl String:s_ModelName[64]
	
	if (!IsValidEdict(i_Ent) || !IsValidEntity(i_Ent))
		return Plugin_Handled
		
	GetEntPropString(i_Ent, Prop_Data, "m_ModelName", s_ModelName, sizeof(s_ModelName))

	if (StrContains(s_ModelName, "infected") != -1)
	{
		SetEntProp(i_Ent, Prop_Send, "m_iGlowType", 0)
		SetEntProp(i_Ent, Prop_Send, "m_glowColorOverride", 0)
	}
	
	return Plugin_Continue
}

public Float:OnGroundUnits(i_Ent)
{
	if (!(GetEntityFlags(i_Ent) & (FL_ONGROUND)))
	{ 
		decl Handle:h_Trace, Float:f_Origin[3], Float:f_Position[3], Float:f_Down[3] = { 90.0, 0.0, 0.0 }
		
		GetEntPropVector(i_Ent, Prop_Send, "m_vecOrigin", f_Origin)
		h_Trace = TR_TraceRayFilterEx(f_Origin, f_Down, CONTENTS_SOLID|CONTENTS_MOVEABLE, RayType_Infinite, TraceFilterClients, i_Ent)

		if (TR_DidHit(h_Trace))
		{
			decl Float:f_Units
			TR_GetEndPosition(f_Position, h_Trace)
			
			f_Units = f_Origin[2] - f_Position[2]

			CloseHandle(h_Trace)
			
			return f_Units
		} 
	
		CloseHandle(h_Trace)
	} 
	
	return 0.0
}

public bool:TraceFilterClients(i_Entity, i_Mask, any:i_Data)
{
	if (i_Entity == i_Data)
		return false
	if (i_Entity >= 1 && i_Entity <= MaxClients)
		return false
		
	return true
}

public OnMapStart()
{
	g_PipebombModel = PrecacheModel(MODEL_V_PIPEBOMB, true)
	g_MolotovModel = PrecacheModel(MODEL_V_MOLOTOV, true)
	
	if (!IsModelPrecached(MODEL_PROPANE))
		PrecacheModel(MODEL_PROPANE, true)
	if (!IsModelPrecached(MODEL_GASCAN))
		PrecacheModel(MODEL_GASCAN, true)
	if (!IsModelPrecached(MODEL_W_PIPEBOMB))
		PrecacheModel(MODEL_W_PIPEBOMB, true)
	if (!IsModelPrecached(MODEL_W_MOLOTOV))
		PrecacheModel(MODEL_W_MOLOTOV, true)
		
	if (!IsSoundPrecached(SOUND_PIPEBOMB))
		PrecacheSound(SOUND_PIPEBOMB, true)
	if (!IsSoundPrecached(SOUND_MOLOTOV))
			PrecacheSound(SOUND_MOLOTOV, true)
					
	if (g_Mod == LEFT4DEAD2)
	{
		g_PistolModel = PrecacheModel(MODEL_V_PISTOL_2, true)
		g_DualPistolModel = PrecacheModel(MODEL_V_DUALPISTOL_2, true)
		g_MagnumModel = PrecacheModel(MODEL_V_MAGNUM, true)
		g_VomitjarModel = PrecacheModel(MODEL_V_VOMITJAR, true)
		
		if (!IsModelPrecached(MODEL_W_VOMITJAR))
			PrecacheModel(MODEL_W_VOMITJAR, true)
			
		if (!IsSoundPrecached(SOUND_VOMITJAR))
			PrecacheSound(SOUND_VOMITJAR, true)
	}
	else
	{
		g_PistolModel = PrecacheModel(MODEL_V_PISTOL_1, true)
		g_DualPistolModel = PrecacheModel(MODEL_V_DUALPISTOL_1, true)
	}
}

public OnClientPutInServer(i_Client)
{
	if (IsFakeClient(i_Client))
		return
		
	g_PlayerIncapacitated[i_Client] = NONE
	g_b_InAction[i_Client] = false
	g_b_AllowThrow[i_Client] = false
	g_PlayerGameTime[i_Client] = 0.0
	g_ThrewGrenade[i_Client] = 0
	g_PipebombBounce[i_Client] = 0
	g_GameInstructor[i_Client] = -1
}

public Action:EventPlayerIncapacitated(Handle:h_Event, const String:s_Name[], bool:b_DontBroadcast)
{
	decl i_UserID, i_Client

	i_UserID = GetEventInt(h_Event, "userid")
	i_Client = GetClientOfUserId(i_UserID)
	
	if (IsFakeClient(i_Client))
		return Plugin_Continue
		
	if (GetClientTeam(i_Client) == TEAM_SURVIVOR)
	{	
		
		if (GetGrenadeOnIncap(i_Client) > 0)
		{
			switch (GetConVarInt(h_CvarMessageType))
			{
				case 1: PrintToChat(i_Client, "\x03[%t]\x01 %t.", "Information", "Throw a grenade")
				case 2: PrintHintText(i_Client, "%t", "Throw a grenade")
				case 3: 
				{
					QueryClientConVar(i_Client, "gameinstructor_enable", ConVarQueryFinished:GameInstructor, i_Client)
					ClientCommand(i_Client, "gameinstructor_enable 1")
					CreateTimer(0.1, DisplayInstructorHint, i_Client)
				}
			}
		}
	}
	
	return Plugin_Continue
}

public GetGrenadeOnIncap(i_Client)
{
	decl i_Grenade, String:s_ModelName[64]
	
	if (GetEntProp(i_Client, Prop_Send, "m_pounceAttacker") > 0 || GetEntProp(i_Client, Prop_Send, "m_tongueOwner") > 0 || (g_Mod == LEFT4DEAD2 && GetEntProp(i_Client, Prop_Send, "m_pummelAttacker") > 0))
		g_b_AllowThrow[i_Client] = false
		else
		g_b_AllowThrow[i_Client] = true

	i_Grenade = GetPlayerWeaponSlot(i_Client, 2)
		
	if (IsValidEntity(i_Grenade))
	{
		GetEntPropString(i_Grenade, Prop_Data, "m_ModelName", s_ModelName, sizeof(s_ModelName))
		
		if (StrEqual(s_ModelName, MODEL_V_PIPEBOMB))
			g_PlayerIncapacitated[i_Client] = PIPEBOMB
		else if (StrEqual(s_ModelName, MODEL_V_MOLOTOV))
			g_PlayerIncapacitated[i_Client] = MOLOTOV
		else if (StrEqual(s_ModelName, MODEL_V_VOMITJAR))
			g_PlayerIncapacitated[i_Client] = VOMITJAR
	}

	return i_Grenade
}

public Action:EventGrenadeBounce(Handle:h_Event, const String:s_Name[], bool:b_DontBroadcast)
{
	decl i_UserID, i_Client, i_Ent
	
	i_UserID = GetEventInt(h_Event, "userid")
	i_Client = GetClientOfUserId(i_UserID)
	i_Ent = g_ThrewGrenade[i_Client]
	
	if (!IsValidEdict(i_Ent) || !i_Ent)
		return Plugin_Handled
		
	decl Float:f_Speed[3], String:s_ClassName[32]
		
	GetEdictClassname(i_Ent, s_ClassName, sizeof(s_ClassName))
	GetEntPropVector(i_Ent, Prop_Send, "m_vecVelocity", f_Speed)
		
	if (StrEqual(s_ClassName, "pipe_bomb_projectile"))
		g_PipebombBounce[i_Client]++
			
	if (g_PipebombBounce[i_Client] >= 2)
	{
		f_Speed[0] /= 1.3
		f_Speed[1] /= 1.3
		f_Speed[2] /= 1.3
	}
	else if (!g_PipebombBounce[i_Client])
	{
		f_Speed[0] /= 3.0
		f_Speed[1] /= 3.0
		f_Speed[2] /= 3.0
	}
		
	TeleportEntity(i_Ent, NULL_VECTOR, NULL_VECTOR, f_Speed)
	
	return Plugin_Continue
}

public Action:EventPlayerDeath(Handle:h_Event, const String:s_Name[], bool:b_DontBroadcast)
{
	decl i_UserID, i_Client
	
	i_UserID = GetEventInt(h_Event, "userid")
	i_Client = GetClientOfUserId(i_UserID)
	
	if (i_Client >= 1 && i_Client <= MaxClients)
		if (GetClientTeam(i_Client) == TEAM_SURVIVOR)
			g_PlayerIncapacitated[i_Client] = NONE
}

public Action:OnPlayerRunCmd(i_Client, &i_Buttons, &i_Impulse, Float:f_Velocity[3], Float:f_Angles[3], &i_Weapon)
{

	if (IsFakeClient(i_Client))
		return Plugin_Continue
		
	if (!g_b_AllowThrow[i_Client])
		return Plugin_Continue

	if (!g_PlayerIncapacitated[i_Client])
		return Plugin_Continue
		
	if (g_b_InAction[i_Client] && (i_Buttons & IN_USE))
	{
		decl i_Viewmodel
		
		i_Viewmodel = GetEntPropEnt(i_Client, Prop_Send, "m_hViewModel")
		g_Mod == LEFT4DEAD ? SetEntProp(i_Viewmodel, Prop_Send, "m_nLayerSequence", 7) : SetEntProp(i_Viewmodel, Prop_Send, "m_nLayerSequence", 5)
		
		i_Buttons &= ~IN_FORWARD
		
		return Plugin_Continue
	}
	else if (g_b_InAction[i_Client])
	{
		g_b_InAction[i_Client] = false
		decl i_Viewmodel, i_Grenade

		i_Viewmodel = GetEntPropEnt(i_Client, Prop_Send, "m_hViewModel")
		g_Mod == LEFT4DEAD ? SetEntProp(i_Viewmodel, Prop_Send, "m_nLayerSequence", 9) : SetEntProp(i_Viewmodel, Prop_Send, "m_nLayerSequence", 6)
		SetEntPropFloat(i_Viewmodel, Prop_Send, "m_flLayerStartTime", GetGameTime())
		
		PlayScene(i_Client)
		
		switch (g_PlayerIncapacitated[i_Client])
		{
			case PIPEBOMB: ThrowPipebomb(i_Client)
			case MOLOTOV: ThrowMolotov(i_Client)
			case VOMITJAR: ThrowVomitjar(i_Client)
		}
		
		i_Grenade = GetPlayerWeaponSlot(i_Client, 2)		
		if (IsValidEdict(i_Grenade))
			RemoveEdict(i_Grenade)
		g_PlayerIncapacitated[i_Client] = NONE
		
		i_Weapon = GetEntDataEnt2(i_Client, g_ActiveWeaponOffset)
		
		if (i_Weapon != -1)
			SetEntPropFloat(i_Weapon, Prop_Send, "m_flNextPrimaryAttack", GetGameTime() + 2.0)	
		
		CreateTimer(1.0, ReturnPistolDelay, i_Client)
			
		return Plugin_Continue
	}
	
	decl i_GrenadeType
	i_GrenadeType = 0
	
	switch (g_PlayerIncapacitated[i_Client])
	{
		case PIPEBOMB: i_GrenadeType = g_PipebombModel
		case MOLOTOV: i_GrenadeType = g_MolotovModel
		case VOMITJAR: i_GrenadeType = g_VomitjarModel
	}
	
	if (i_GrenadeType && !(i_Buttons & IN_FORWARD))
	{
		decl i_Viewmodel, i_Model
		
		i_Viewmodel = GetEntPropEnt(i_Client, Prop_Send, "m_hViewModel")
		i_Model = GetEntProp(i_Viewmodel, Prop_Send, "m_nModelIndex")
		
		if (i_Model == i_GrenadeType)
			g_Mod == LEFT4DEAD ? SetEntProp(i_Viewmodel, Prop_Send, "m_nLayerSequence", 3) : SetEntProp(i_Viewmodel, Prop_Send, "m_nLayerSequence", 1)
			
		if (i_Buttons & IN_ATTACK)
		{
			if (i_Model != i_GrenadeType)
				return Plugin_Continue
			
			g_Mod == LEFT4DEAD ? SetEntProp(i_Viewmodel, Prop_Send, "m_nLayerSequence", 7) : SetEntProp(i_Viewmodel, Prop_Send, "m_nLayerSequence", 5)
			SetEntPropFloat(i_Viewmodel, Prop_Send, "m_flLayerStartTime", GetGameTime())
			i_Weapon = GetEntDataEnt2(i_Client, g_ActiveWeaponOffset)
			
			if (i_Weapon != -1)
				SetEntPropFloat(i_Weapon, Prop_Send, "m_flNextPrimaryAttack", GetGameTime() + 100.0)
			
			g_b_InAction[i_Client] = true
			
			decl String:s_Sound[64]
			if (g_Mod == LEFT4DEAD)
			{
				FormatEx(s_Sound, sizeof(s_Sound), "^%s", SOUND_PISTOL)
				StopSound(i_Client, SNDCHAN_WEAPON, s_Sound)
			}
			else if (g_Mod == LEFT4DEAD2)
			{
				FormatEx(s_Sound, sizeof(s_Sound), ")%s", SOUND_PISTOL)
				StopSound(i_Client, SNDCHAN_WEAPON, s_Sound)
				StopSound(i_Client, SNDCHAN_WEAPON, SOUND_DUAL_PISTOL)
				StopSound(i_Client, SNDCHAN_WEAPON, SOUND_MAGNUM)
			}
		}
		else if (i_Buttons & IN_USE)
		{
			if ((GetGameTime() - g_PlayerGameTime[i_Client]) < 1.0)
				return Plugin_Continue
			
			i_Weapon = GetEntDataEnt2(i_Client, g_ActiveWeaponOffset)
			
			if (i_Weapon != -1 && GetEntProp(i_Weapon, Prop_Data, "m_bInReload"))
				return Plugin_Continue
		
			if (i_Model != i_GrenadeType)
			{
				SetEntProp(i_Viewmodel, Prop_Send, "m_nModelIndex", i_GrenadeType, 2)
				g_Mod == LEFT4DEAD ? SetEntProp(i_Viewmodel, Prop_Send, "m_nLayerSequence", 3) : SetEntProp(i_Viewmodel, Prop_Send, "m_nLayerSequence", 1)
				g_PlayerGameTime[i_Client] = GetGameTime()
			}
			else
			{
				SetPlayerWeaponModel(i_Client, i_Weapon)
				g_PlayerGameTime[i_Client] = GetGameTime()
			}
		}
		else if (i_Buttons & IN_RELOAD)
		{
			if (i_Model == i_GrenadeType)
				i_Buttons &= ~IN_RELOAD
		}
	}
	
	return Plugin_Continue
}

public Action:ReturnPistolDelay(Handle:h_Timer, any:i_Client)
{
	decl i_Viewmodel, i_Weapon
	
	if (!i_Client && !IsClientInGame(i_Client))
		return Plugin_Handled

	i_Viewmodel = GetEntPropEnt(i_Client, Prop_Send, "m_hViewModel")
	i_Weapon = GetEntDataEnt2(i_Client, g_ActiveWeaponOffset)
	g_Mod == LEFT4DEAD ? SetEntProp(i_Viewmodel, Prop_Send, "m_nLayerSequence", 15) : SetEntProp(i_Viewmodel, Prop_Send, "m_nLayerSequence", 2)
	if (i_Weapon != -1)
		SetPlayerWeaponModel(i_Client, i_Weapon)
	SetEntPropFloat(i_Viewmodel, Prop_Send, "m_flLayerStartTime", GetGameTime())
	
	return Plugin_Continue
}

public AttachParticle(i_Ent, String:s_Effect[], Float:f_Origin[3])
{
	decl i_Particle, String:s_TargetName[32]
	
	i_Particle = CreateEntityByName("info_particle_system")
	
	if (IsValidEdict(i_Particle))
	{
		if (StrEqual(s_Effect, "weapon_pipebomb_fuse"))
		{
			f_Origin[0] += 0.3
			f_Origin[1] += 1.7
			f_Origin[2] += 7.5
		}
		TeleportEntity(i_Particle, f_Origin, NULL_VECTOR, NULL_VECTOR)
		FormatEx(s_TargetName, sizeof(s_TargetName), "particle%d", i_Ent)
		DispatchKeyValue(i_Particle, "targetname", s_TargetName)
		GetEntPropString(i_Ent, Prop_Data, "m_iName", s_TargetName, sizeof(s_TargetName))
		DispatchKeyValue(i_Particle, "parentname", s_TargetName)
		DispatchKeyValue(i_Particle, "effect_name", s_Effect)
		DispatchSpawn(i_Particle)
		SetVariantString(s_TargetName)
		AcceptEntityInput(i_Particle, "SetParent", i_Particle, i_Particle, 0)
		ActivateEntity(i_Particle)
		AcceptEntityInput(i_Particle, "Start")
	}

	return i_Particle
}

public AttachInfected(i_Ent, Float:f_Origin[3])
{
	decl i_InfoEnt, String:s_TargetName[32]
	
	i_InfoEnt = CreateEntityByName("info_goal_infected_chase")
	
	if (IsValidEdict(i_InfoEnt))
	{
		f_Origin[2] += 20.0
		DispatchKeyValueVector(i_InfoEnt, "origin", f_Origin)
		FormatEx(s_TargetName, sizeof(s_TargetName), "goal_infected%d", i_Ent)
		DispatchKeyValue(i_InfoEnt, "targetname", s_TargetName)
		GetEntPropString(i_Ent, Prop_Data, "m_iName", s_TargetName, sizeof(s_TargetName))
		DispatchKeyValue(i_InfoEnt, "parentname", s_TargetName)
		DispatchSpawn(i_InfoEnt)
		SetVariantString(s_TargetName)
		AcceptEntityInput(i_InfoEnt, "SetParent", i_InfoEnt, i_InfoEnt, 0)
		ActivateEntity(i_InfoEnt)
		AcceptEntityInput(i_InfoEnt, "Enable")
	}

	return i_InfoEnt
}

public DisplayParticle(Float:f_Position[3], String:s_Name[], Float:f_Time)
{
	decl i_Particle
	
	i_Particle = CreateEntityByName("info_particle_system")
	if (IsValidEdict(i_Particle))
	{
		TeleportEntity(i_Particle, f_Position, NULL_VECTOR, NULL_VECTOR)
		DispatchKeyValue(i_Particle, "effect_name", s_Name)
		DispatchSpawn(i_Particle)
		ActivateEntity(i_Particle)
		AcceptEntityInput(i_Particle, "Start")
		CreateTimer(f_Time, DeleteEntity, i_Particle)
	}
}

public PlayScene(i_Client)
{
	decl i_Ent, String:s_Model[128], String:s_SceneFile[32], i_Random
	
	GetEntPropString(i_Client, Prop_Data, "m_ModelName", s_Model, sizeof(s_Model))
	
	if (g_Mod == LEFT4DEAD)
	{
		if (StrContains(s_Model, "biker") != -1)
		{
			if (g_PlayerIncapacitated[i_Client] != NONE)
			{
				i_Random = GetRandomInt(0, sizeof(g_VoiceFrancisBill)-1)
				FormatEx(s_SceneFile, sizeof(s_SceneFile), "scenes/biker/%s.vcd", g_VoiceFrancisBill[i_Random])
			}	
		}
		else if (StrContains(s_Model, "manager") != -1)
		{
			if (g_PlayerIncapacitated[i_Client] != NONE)
			{
				i_Random = GetRandomInt(0, sizeof(g_VoiceLouis)-1)
				FormatEx(s_SceneFile, sizeof(s_SceneFile), "scenes/manager/%s.vcd", g_VoiceLouis[i_Random])
			}	
		}
		else if (StrContains(s_Model, "namvet") != -1)
		{
			if (g_PlayerIncapacitated[i_Client] != NONE)
			{
				i_Random = GetRandomInt(0, sizeof(g_VoiceFrancisBill)-1)
				FormatEx(s_SceneFile, sizeof(s_SceneFile), "scenes/namvet/%s.vcd", g_VoiceFrancisBill[i_Random])
			}	
		}
		else if (StrContains(s_Model, "teenangst") != -1)
		{
			if (g_PlayerIncapacitated[i_Client] != NONE)
			{
				i_Random = GetRandomInt(0, sizeof(g_VoiceZoey)-1)
				FormatEx(s_SceneFile, sizeof(s_SceneFile), "scenes/teengirl/%s.vcd", g_VoiceZoey[i_Random])
			}	
		}	
	}
	else if (g_Mod == LEFT4DEAD2)
	{
		if (StrContains(s_Model, "gambler") != -1)
		{
			switch (g_PlayerIncapacitated[i_Client])
			{
				case PIPEBOMB:
				{
					i_Random = GetRandomInt(0, sizeof(g_VoicePipebombNick)-1)
					FormatEx(s_SceneFile, sizeof(s_SceneFile), "scenes/gambler/%s.vcd", g_VoicePipebombNick[i_Random])
				}
				case MOLOTOV:
				{
					i_Random = GetRandomInt(0, sizeof(g_VoiceMolotovNick)-1)
					FormatEx(s_SceneFile, sizeof(s_SceneFile), "scenes/gambler/%s.vcd", g_VoiceMolotovNick[i_Random])
				}
				case VOMITJAR:
				{
					i_Random = GetRandomInt(0, sizeof(g_VoiceVomitjarNick)-1)
					FormatEx(s_SceneFile, sizeof(s_SceneFile), "scenes/gambler/%s.vcd", g_VoiceVomitjarNick[i_Random])
				}
			}
		}
		else if (StrContains(s_Model, "coach") != -1)
		{
			switch (g_PlayerIncapacitated[i_Client])
			{
				case PIPEBOMB:
				{
					i_Random = GetRandomInt(0, sizeof(g_VoicePipebombCoach)-1)
					FormatEx(s_SceneFile, sizeof(s_SceneFile), "scenes/coach/%s.vcd", g_VoicePipebombCoach[i_Random])
				}
				case MOLOTOV:
				{
					i_Random = GetRandomInt(0, sizeof(g_VoiceMolotovCoach)-1)
					FormatEx(s_SceneFile, sizeof(s_SceneFile), "scenes/coach/%s.vcd", g_VoiceMolotovCoach[i_Random])
				}
				case VOMITJAR:
				{
					i_Random = GetRandomInt(0, sizeof(g_VoiceVomitjarCoach)-1)
					FormatEx(s_SceneFile, sizeof(s_SceneFile), "scenes/coach/%s.vcd", g_VoiceVomitjarCoach[i_Random])
				}
			}	
		}
		else if (StrContains(s_Model, "mechanic") != -1)
		{
			switch (g_PlayerIncapacitated[i_Client])
			{
				case PIPEBOMB:
				{
					i_Random = GetRandomInt(0, sizeof(g_VoicePipebombEllis)-1)
					FormatEx(s_SceneFile, sizeof(s_SceneFile), "scenes/mechanic/%s.vcd", g_VoicePipebombEllis[i_Random])
				}
				case MOLOTOV:
				{
					i_Random = GetRandomInt(0, sizeof(g_VoiceMolotovEllis)-1)
					FormatEx(s_SceneFile, sizeof(s_SceneFile), "scenes/mechanic/%s.vcd", g_VoiceMolotovEllis[i_Random])
				}
				case VOMITJAR:
				{
					i_Random = GetRandomInt(0, sizeof(g_VoiceVomitjarEllis)-1)
					FormatEx(s_SceneFile, sizeof(s_SceneFile), "scenes/mechanic/%s.vcd", g_VoiceVomitjarEllis[i_Random])
				}
			}	
		}
		else if (StrContains(s_Model, "producer") != -1)
		{
			switch (g_PlayerIncapacitated[i_Client])
			{
				case PIPEBOMB:
				{
					i_Random = GetRandomInt(0, sizeof(g_VoicePipebombRochelle)-1)
					FormatEx(s_SceneFile, sizeof(s_SceneFile), "scenes/producer/%s.vcd", g_VoicePipebombRochelle[i_Random])
				}
				case MOLOTOV:
				{
					i_Random = GetRandomInt(0, sizeof(g_VoiceMolotovRochelle)-1)
					FormatEx(s_SceneFile, sizeof(s_SceneFile), "scenes/producer/%s.vcd", g_VoiceMolotovRochelle[i_Random])
				}
				case VOMITJAR:
				{
					i_Random = GetRandomInt(0, sizeof(g_VoiceVomitjarRochelle)-1)
					FormatEx(s_SceneFile, sizeof(s_SceneFile), "scenes/producer/%s.vcd", g_VoiceVomitjarRochelle[i_Random])
				}
			}	
		}
	}
		
	i_Ent = CreateEntityByName("instanced_scripted_scene")
	DispatchKeyValue(i_Ent, "SceneFile", s_SceneFile)
	DispatchSpawn(i_Ent)
	SetEntPropEnt(i_Ent, Prop_Data, "m_hOwner", i_Client)
	ActivateEntity(i_Ent)
	AcceptEntityInput(i_Ent, "Start", i_Client, i_Client)
}

public Action:DisplayInstructorHint(Handle:h_Timer, any:i_Client)
{
	decl i_Ent, String:s_TargetName[32], String:s_Message[256], Handle:h_Pack

	i_Ent = CreateEntityByName("env_instructor_hint")
	FormatEx(s_TargetName, sizeof(s_TargetName), "hint%d", i_Client)
	FormatEx(s_Message, sizeof(s_Message), "%t", "Throw a grenade")
	ReplaceString(s_Message, sizeof(s_Message), "\n", " ")
	DispatchKeyValue(i_Client, "targetname", s_TargetName)
	DispatchKeyValue(i_Ent, "hint_target", s_TargetName)
	DispatchKeyValue(i_Ent, "hint_timeout", "5")
	DispatchKeyValue(i_Ent, "hint_range", "0.01")
	DispatchKeyValue(i_Ent, "hint_icon_onscreen", "use_binding")
	DispatchKeyValue(i_Ent, "hint_caption", s_Message)
	DispatchKeyValue(i_Ent, "hint_color", "255 255 255")
	DispatchKeyValue(i_Ent, "hint_binding", "+attack2")
	DispatchSpawn(i_Ent)
	AcceptEntityInput(i_Ent, "ShowHint")
	
	h_Pack = CreateDataPack()
	WritePackCell(h_Pack, i_Client)
	WritePackCell(h_Pack, i_Ent)
	CreateTimer(5.0, RemoveInstructorHint, h_Pack)
}

public GameInstructor(QueryCookie:q_Cookie, i_Client, ConVarQueryResult:c_Result, const String:s_CvarName[], const String:s_CvarValue[])
	g_GameInstructor[i_Client] = StringToInt(s_CvarValue)

stock GetRandomAngles(Float:f_Angles[3])
{
	f_Angles[0] = GetRandomFloat(-180.0, 180.0)
	f_Angles[1] = GetRandomFloat(-180.0, 180.0)
	f_Angles[2] = GetRandomFloat(-180.0, 180.0)
}

public Action:RemoveInstructorHint(Handle:h_Timer, Handle:h_Pack)
{
	decl i_Ent, i_Client
	
	ResetPack(h_Pack, false)
	i_Client = ReadPackCell(h_Pack)
	i_Ent = ReadPackCell(h_Pack)
	CloseHandle(h_Pack)
	
	if (!i_Client || !IsClientInGame(i_Client))
		return Plugin_Handled
	
	if (IsValidEntity(i_Ent))
			RemoveEdict(i_Ent)
	
	if (!g_GameInstructor[i_Client])
		ClientCommand(i_Client, "gameinstructor_enable 0")
		
	return Plugin_Continue
}

public Action:DeleteEntity(Handle:h_Timer, any:i_Ent)
{
	if (IsValidEntity(i_Ent))
			RemoveEdict(i_Ent)
}