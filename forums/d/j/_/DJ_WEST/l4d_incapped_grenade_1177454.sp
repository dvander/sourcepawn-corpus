/*

	Created by DJ_WEST
	
	Web: http://amx-x.ru
	AMX Mod X and SourceMod Russian Community
	
*/

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.6"

#define MODEL_V_PIPEBOMB "models/v_models/v_pipebomb.mdl"
#define MODEL_V_MOLOTOV "models/v_models/v_molotov.mdl"
#define MODEL_V_VOMITJAR "models/v_models/v_bile_flask.mdl"
#define MODEL_V_PISTOL_1 "models/v_models/v_pistol.mdl"
#define MODEL_V_PISTOL_2 "models/v_models/v_pistola.mdl"
#define MODEL_V_DUALPISTOL_1 "models/v_models/v_dualpistols.mdl"
#define MODEL_V_DUALPISTOL_2 "models/v_models/v_dual_pistola.mdl"
#define MODEL_V_MAGNUM "models/v_models/v_desert_eagle.mdl"
#define SOUND_PISTOL "weapons/pistol/gunfire/pistol_fire.wav"
#define SOUND_DUAL_PISTOL ")weapons/pistol/gunfire/pistol_dual_fire.wav"
#define SOUND_MAGNUM ")weapons/magnum/gunfire/magnum_shoot.wav"
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

new g_ActiveWeaponOffset, g_PipebombModel, g_MolotovModel, g_VomitjarModel, Float:g_PlayerGameTime[MAXPLAYERS+1],
	GAME_MOD:g_Mod, bool:g_b_InAction[MAXPLAYERS+1], Handle:h_CvarVomitjarSpeed, Handle:h_CvarPipebombSpeed, 
	Handle:h_CvarMolotovSpeed, Handle:h_CvarPipebombDuration, Handle:h_CvarVomitjarDuration, Handle:h_CvarVomitjarRadius, 
	Handle:h_CvarMessageType, g_PistolModel, g_DualPistolModel, g_MagnumModel, Handle:g_h_GameConfig, Handle:g_h_CreatePipebomb, 
	Handle:g_h_CreateVomitjar, Handle:g_h_CreateMolotov, Handle:h_CvarPipebombRadius

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
	
	g_h_GameConfig = LoadGameConfigFile("l4d_incapped_grenade")

	if (g_h_GameConfig != INVALID_HANDLE)
	{
		StartPrepSDKCall(SDKCall_Static)
		PrepSDKCall_SetFromConf(g_h_GameConfig, SDKConf_Signature, "CPipeBombProjectile::Create")
		PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef)
		PrepSDKCall_AddParameter(SDKType_QAngle, SDKPass_ByRef)
		PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef)
		PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef)
		PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer)
		PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain)
		PrepSDKCall_SetReturnInfo(SDKType_CBaseEntity, SDKPass_Pointer)
		g_h_CreatePipebomb = EndPrepSDKCall()
		
		StartPrepSDKCall(SDKCall_Static)
		PrepSDKCall_SetFromConf(g_h_GameConfig, SDKConf_Signature, "CVomitJarProjectile::Create")
		PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef)
		PrepSDKCall_AddParameter(SDKType_QAngle, SDKPass_ByRef)
		PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef)
		PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef)
		PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer)
		g_h_CreateVomitjar = EndPrepSDKCall()

		StartPrepSDKCall(SDKCall_Static)
		PrepSDKCall_SetFromConf(g_h_GameConfig, SDKConf_Signature, "CMolotovProjectile::Create")
		PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef)
		PrepSDKCall_AddParameter(SDKType_QAngle, SDKPass_ByRef)
		PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef)
		PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef)
		PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer)
		g_h_CreateMolotov = EndPrepSDKCall()
		
		if (g_h_CreatePipebomb == INVALID_HANDLE)
			SetFailState("Don't find CPipeBombProjectile::Create function! Update gamedata/l4d_incapped_grenade.txt file.")

		if (g_h_CreateVomitjar == INVALID_HANDLE)
			SetFailState("Don't find CVomitJarProjectile::Create function! Update gamedata/l4d_incapped_grenade.txt file.")
			
		if (g_h_CreateMolotov == INVALID_HANDLE)
			SetFailState("Don't find CMolotovProjectile::Create function! Update gamedata/l4d_incapped_grenade.txt file.")
	}
	else
		SetFailState("Don't find gamedata/l4d_incapped_grenade.txt file!")
		
	g_ActiveWeaponOffset = FindSendPropInfo("CBasePlayer", "m_hActiveWeapon")
		
	h_Version = CreateConVar("incapped_grenade_version", PLUGIN_VERSION, "Incapped Grenade version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY)
	h_CvarPipebombSpeed = CreateConVar("l4d_incapped_pipebomb_speed", "300.0", "Pipebomb speed", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1000.0)
	h_CvarPipebombRadius = CreateConVar("l4d_incapped_pipebomb_radius", "750.0", "Pipebomb radius", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1000.0)
	h_CvarMolotovSpeed = CreateConVar("l4d_incapped_molotov_speed", "300.0", "Molotov speed", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1000.0)
	h_CvarPipebombDuration = CreateConVar("l4d_incapped_pipebomb_duration", "6.0", "Pipebomb duration", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 30.0)
	h_CvarMessageType = CreateConVar("l4d_incapped_message_type", "3", "Message type (0 - disable, 1 - chat, 2 - hint, 3 - instructor hint)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 3.0)
	
	HookEvent("player_incapacitated", EventPlayerIncapacitated)
	HookEvent("revive_success", EventReviveSuccess)
	HookEvent("revive_begin", EventReviveBegin)
	HookEvent("round_start", EventRoundStart)
	
	if (g_Mod == LEFT4DEAD2)
	{
		h_CvarVomitjarDuration = CreateConVar("l4d_incapped_vomitjar_duration", "15.0", "Vomitjar duration", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 30.0)
		h_CvarVomitjarSpeed = CreateConVar("l4d_incapped_vomitjar_speed", "300.0", "Vomitjar speed", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1000.0)
		h_CvarVomitjarRadius = CreateConVar("l4d_incapped_vomitjar_radius", "110.0", "Vomitjar radius", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 500.0)
	}
	
	HookConVarChange(h_CvarPipebombDuration, PipebombDurationChanged)
	HookConVarChange(h_CvarPipebombRadius, PipebombRadiusChanged)
	HookConVarChange(h_CvarVomitjarDuration, VomitjarDurationChanged)
	HookConVarChange(h_CvarVomitjarRadius, VomitjarRadiusChanged)
	
	SetConVarString(h_Version, PLUGIN_VERSION)
}

public PipebombDurationChanged(Handle:h_ConVar, const String:s_OldValue[], const String:s_NewValue[])
	SetConVarFloat(FindConVar("pipe_bomb_timer_duration"), StringToFloat(s_NewValue))

public VomitjarDurationChanged(Handle:h_ConVar, const String:s_OldValue[], const String:s_NewValue[])
{
	SetConVarFloat(FindConVar("vomitjar_duration_infected_bot"), StringToFloat(s_NewValue))
	SetConVarFloat(FindConVar("vomitjar_duration_infected_pz"), StringToFloat(s_NewValue))
}

public VomitjarRadiusChanged(Handle:h_ConVar, const String:s_OldValue[], const String:s_NewValue[])
	SetConVarFloat(FindConVar("vomitjar_radius"), StringToFloat(s_NewValue))
	
public PipebombRadiusChanged(Handle:h_ConVar, const String:s_OldValue[], const String:s_NewValue[])
	SetConVarFloat(FindConVar("pipe_bomb_shake_radius"), StringToFloat(s_NewValue))

public Action:EventRoundStart(Handle:h_Event, const String:s_Name[], bool:b_DontBroadcast)
{
	decl i_Weapon
	
	for (new i_Client = 1; i_Client <= MaxClients; i_Client++)
	{
		if (IsClientInGame(i_Client) && !IsFakeClient(i_Client) && GetClientTeam(i_Client) == TEAM_SURVIVOR)
		{
			i_Weapon = GetEntDataEnt2(i_Client, g_ActiveWeaponOffset)
			SetPlayerWeaponModel(i_Client, i_Weapon)
			g_b_InAction[i_Client] = false
		}
	}
}

public Action:EventReviveBegin(Handle:h_Event, const String:s_Name[], bool:b_DontBroadcast)
{
	decl i_UserID, i_Client, i_Weapon
	
	i_UserID = GetEventInt(h_Event, "subject")
	i_Client = GetClientOfUserId(i_UserID)
	
	if (!i_Client || !IsClientInGame(i_Client) || IsFakeClient(i_Client))
		return Plugin_Handled
		
	i_Weapon = GetEntDataEnt2(i_Client, g_ActiveWeaponOffset)
	g_b_InAction[i_Client] = false

	if (i_Weapon != -1)
	{
		SetPlayerWeaponModel(i_Client, i_Weapon)
		SetEntPropFloat(i_Weapon, Prop_Send, "m_flNextPrimaryAttack", GetGameTime())
	}
	
	return Plugin_Continue
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
	
	if (!i_Client || !IsClientInGame(i_Client) || IsFakeClient(i_Client))
		return Plugin_Handled
		
	i_Weapon = GetEntDataEnt2(i_Client, g_ActiveWeaponOffset)
	
	if (i_Weapon != -1)
		SetPlayerWeaponModel(i_Client, i_Weapon)
		
	g_b_InAction[i_Client] = false
	
	return Plugin_Continue
}

public ThrowMolotov(i_Client)
{
	decl Float:f_Origin[3], Float:f_Angles[3], Float:f_Velocity[3], Float:f_Speed
	
	GetClientEyePosition(i_Client, f_Origin)
	GetClientEyeAngles(i_Client, f_Angles)
	GetAngleVectors(f_Angles, f_Velocity, NULL_VECTOR, NULL_VECTOR)
	f_Speed = GetConVarFloat(h_CvarMolotovSpeed)
	
	f_Velocity[0] *= f_Speed
	f_Velocity[1] *= f_Speed
	f_Velocity[2] *= f_Speed
	
	SDKCall(g_h_CreateMolotov, f_Origin, f_Angles, f_Velocity, { 0.0, 0.0, 0.0 }, i_Client)
}

public ThrowVomitjar(i_Client)
{
	decl Float:f_Origin[3], Float:f_Angles[3], Float:f_Velocity[3], Float:f_Speed
	
	GetClientEyePosition(i_Client, f_Origin)
	GetClientEyeAngles(i_Client, f_Angles)
	GetAngleVectors(f_Angles, f_Velocity, NULL_VECTOR, NULL_VECTOR)
	f_Speed = GetConVarFloat(h_CvarVomitjarSpeed)
	
	f_Velocity[0] *= f_Speed
	f_Velocity[1] *= f_Speed
	f_Velocity[2] *= f_Speed
	
	SDKCall(g_h_CreateVomitjar, f_Origin, f_Angles, f_Velocity, { 0.0, 0.0, 0.0 }, i_Client)
}

public ThrowPipebomb(i_Client)
{
	decl Float:f_Origin[3], Float:f_Angles[3], Float:f_Velocity[3], Float:f_Speed, i_Grenade, String:s_TargetName[16]
	
	GetClientEyePosition(i_Client, f_Origin)
	GetClientEyeAngles(i_Client, f_Angles)
	GetAngleVectors(f_Angles, f_Velocity, NULL_VECTOR, NULL_VECTOR)
	f_Speed = GetConVarFloat(h_CvarPipebombSpeed)
	
	f_Velocity[0] *= f_Speed
	f_Velocity[1] *= f_Speed
	f_Velocity[2] *= f_Speed
	
	i_Grenade = SDKCall(g_h_CreatePipebomb, f_Origin, f_Angles, f_Velocity, { 0.0, 0.0, 0.0 }, i_Client, GetConVarFloat(h_CvarPipebombDuration))
	
	FormatEx(s_TargetName, sizeof(s_TargetName), "pipebomb%d", i_Grenade)
	DispatchKeyValue(i_Grenade, "targetname", s_TargetName)
	AttachParticle(i_Grenade, "weapon_pipebomb_blinking_light")
	AttachParticle(i_Grenade, "weapon_pipebomb_fuse")
}

public OnMapStart()
{
	g_PipebombModel = PrecacheModel(MODEL_V_PIPEBOMB, true)
	g_MolotovModel = PrecacheModel(MODEL_V_MOLOTOV, true)
					
	if (g_Mod == LEFT4DEAD2)
	{
		g_PistolModel = PrecacheModel(MODEL_V_PISTOL_2, true)
		g_DualPistolModel = PrecacheModel(MODEL_V_DUALPISTOL_2, true)
		g_MagnumModel = PrecacheModel(MODEL_V_MAGNUM, true)
		g_VomitjarModel = PrecacheModel(MODEL_V_VOMITJAR, true)
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
		
	g_b_InAction[i_Client] = false
	g_PlayerGameTime[i_Client] = 0.0
}

public Action:EventPlayerIncapacitated(Handle:h_Event, const String:s_Name[], bool:b_DontBroadcast)
{
	decl i_UserID, i_Client, i_Grenade

	i_UserID = GetEventInt(h_Event, "userid")
	i_Client = GetClientOfUserId(i_UserID)
	
	if (IsFakeClient(i_Client))
		return Plugin_Continue
		
	i_Grenade = GetPlayerWeaponSlot(i_Client, 2)
		
	if (GetClientTeam(i_Client) == TEAM_SURVIVOR)
	{	
		if (i_Grenade > 0)
		{
			g_PlayerGameTime[i_Client] = GetGameTime() + 2.0
			switch (GetConVarInt(h_CvarMessageType))
			{
				case 1: PrintToChat(i_Client, "\x03[%t]\x01 %t.", "Information", "Throw a grenade")
				case 2: PrintHintText(i_Client, "%t", "Throw a grenade")
				case 3: 
				{
					ClientCommand(i_Client, "gameinstructor_enable 1")
					CreateTimer(0.3, DisplayInstructorHint, i_Client)
				}
			}
		}
	}
	
	return Plugin_Continue
}

public Action:OnPlayerRunCmd(i_Client, &i_Buttons, &i_Impulse, Float:f_Velocity[3], Float:f_Angles[3], &i_Weapon)
{
	if (IsFakeClient(i_Client))
		return Plugin_Continue
		
	if (!IsPlayerAlive(i_Client))
		return Plugin_Continue

	decl i_Grenade, String:s_ModelName[64], i_GrenadeType
	
	i_GrenadeType = 0
	i_Grenade = GetPlayerWeaponSlot(i_Client, 2)
	
	if (!IsValidEdict(i_Grenade))
		return Plugin_Continue
		
	if (!GetEntProp(i_Client, Prop_Send, "m_isIncapacitated"))
		return Plugin_Continue
		
	if (GetEntProp(i_Client, Prop_Send, "m_pounceAttacker") > 0)
		return Plugin_Continue
		
	if (GetEntProp(i_Client, Prop_Send, "m_tongueOwner") > 0)
		return Plugin_Continue
		
	if (g_Mod == LEFT4DEAD2 && GetEntProp(i_Client, Prop_Send, "m_pummelAttacker") > 0)
		return Plugin_Continue
		
	if (g_Mod == LEFT4DEAD2 && GetEntProp(i_Client, Prop_Send, "m_carryAttacker") > 0)
		return Plugin_Continue
		
	if (GetEntProp(i_Client, Prop_Send, "m_reviveOwner") > 0)
		return Plugin_Continue
		
	GetEntPropString(i_Grenade, Prop_Data, "m_ModelName", s_ModelName, sizeof(s_ModelName))
		
	if (StrEqual(s_ModelName, MODEL_V_PIPEBOMB))
		i_GrenadeType = g_PipebombModel
	else if (StrEqual(s_ModelName, MODEL_V_MOLOTOV))
		i_GrenadeType = g_MolotovModel
	else if (StrEqual(s_ModelName, MODEL_V_VOMITJAR))
		i_GrenadeType = g_VomitjarModel
	
	if (g_b_InAction[i_Client] && (i_Buttons & IN_ATTACK))
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
		decl i_Viewmodel

		i_Viewmodel = GetEntPropEnt(i_Client, Prop_Send, "m_hViewModel")
		g_Mod == LEFT4DEAD ? SetEntProp(i_Viewmodel, Prop_Send, "m_nLayerSequence", 9) : SetEntProp(i_Viewmodel, Prop_Send, "m_nLayerSequence", 6)
		SetEntPropFloat(i_Viewmodel, Prop_Send, "m_flLayerStartTime", GetGameTime())
		
		if (i_GrenadeType == g_PipebombModel)
		{
			PlayScene(i_Client, PIPEBOMB)
			ThrowPipebomb(i_Client)
		}
		else if (i_GrenadeType == g_MolotovModel)
		{
			PlayScene(i_Client, MOLOTOV)
			ThrowMolotov(i_Client)
		}
		else if (i_GrenadeType == g_VomitjarModel)
		{
			PlayScene(i_Client, VOMITJAR)
			ThrowVomitjar(i_Client)
		}
		
		RemoveEdict(i_Grenade)
		
		i_Weapon = GetEntDataEnt2(i_Client, g_ActiveWeaponOffset)
		
		if (i_Weapon != -1)
			SetEntPropFloat(i_Weapon, Prop_Send, "m_flNextPrimaryAttack", GetGameTime() + 2.0)	
		
		CreateTimer(1.0, ReturnPistolDelay, i_Client)
			
		return Plugin_Continue
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
		else if (i_Buttons & IN_ATTACK2)
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
	
	if (!i_Client || !IsClientInGame(i_Client))
		return Plugin_Handled

	i_Viewmodel = GetEntPropEnt(i_Client, Prop_Send, "m_hViewModel")
	i_Weapon = GetEntDataEnt2(i_Client, g_ActiveWeaponOffset)
	g_Mod == LEFT4DEAD ? SetEntProp(i_Viewmodel, Prop_Send, "m_nLayerSequence", 15) : SetEntProp(i_Viewmodel, Prop_Send, "m_nLayerSequence", 2)
	
	if (i_Weapon != -1)
		SetPlayerWeaponModel(i_Client, i_Weapon)
		
	SetEntPropFloat(i_Viewmodel, Prop_Send, "m_flLayerStartTime", GetGameTime())
	
	return Plugin_Continue
}

public AttachParticle(i_Ent, String:s_Effect[])
{
	decl i_Particle, String:s_TargetName[32], Float:f_Origin[3]
	
	GetEntPropVector(i_Ent, Prop_Send, "m_vecOrigin", f_Origin)
	i_Particle = CreateEntityByName("info_particle_system")
	
	if (IsValidEdict(i_Particle))
	{
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
		if (StrEqual(s_Effect, "weapon_pipebomb_fuse"))
			CreateTimer(0.1, DeleteEntity, i_Particle)
	}

	return i_Particle
}

public PlayScene(i_Client, GRENADE_TYPE:i_Grenade)
{
	decl i_Ent, String:s_Model[128], String:s_SceneFile[32], i_Random
	
	GetEntPropString(i_Client, Prop_Data, "m_ModelName", s_Model, sizeof(s_Model))
	
	if (g_Mod == LEFT4DEAD)
	{
		if (StrContains(s_Model, "biker") != -1)
		{
			i_Random = GetRandomInt(0, sizeof(g_VoiceFrancisBill)-1)
			FormatEx(s_SceneFile, sizeof(s_SceneFile), "scenes/biker/%s.vcd", g_VoiceFrancisBill[i_Random])
		}
		else if (StrContains(s_Model, "manager") != -1)
		{
			i_Random = GetRandomInt(0, sizeof(g_VoiceLouis)-1)
			FormatEx(s_SceneFile, sizeof(s_SceneFile), "scenes/manager/%s.vcd", g_VoiceLouis[i_Random])
		}
		else if (StrContains(s_Model, "namvet") != -1)
		{
			i_Random = GetRandomInt(0, sizeof(g_VoiceFrancisBill)-1)
			FormatEx(s_SceneFile, sizeof(s_SceneFile), "scenes/namvet/%s.vcd", g_VoiceFrancisBill[i_Random])
		}
		else if (StrContains(s_Model, "teenangst") != -1)
		{
			i_Random = GetRandomInt(0, sizeof(g_VoiceZoey)-1)
			FormatEx(s_SceneFile, sizeof(s_SceneFile), "scenes/teengirl/%s.vcd", g_VoiceZoey[i_Random])
		}	
	}
	else if (g_Mod == LEFT4DEAD2)
	{
		if (StrContains(s_Model, "gambler") != -1)
		{
			switch (i_Grenade)
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
			switch (i_Grenade)
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
			switch (i_Grenade)
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
			switch (i_Grenade)
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
	if (!IsClientInGame(i_Client))
		return Plugin_Handled
		
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
	
	return Plugin_Continue
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
		
	DispatchKeyValue(i_Client, "targetname", "")
	
	if (IsValidEntity(i_Ent))
			RemoveEdict(i_Ent)
	
	ClientCommand(i_Client, "gameinstructor_enable 0")
		
	return Plugin_Continue
}

public Action:DeleteEntity(Handle:h_Timer, any:i_Ent)
{
	if (IsValidEntity(i_Ent))
			RemoveEdict(i_Ent)
}