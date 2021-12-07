#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <tf2_stocks>
#include <psyrtd>

#define atof(%1) StringToFloat(%1)
#define PRECACHESOUND(%1);\
if (!IsSoundPrecached(%1))\
{\
	PrecacheSound(%1, true);\
}

public Plugin:myinfo = 
{
	name = "psyRTD TF2 Effects",
	author = "psychonic",
	description = "TF2 effects module for psyRTD",
	version = "1.0",
	url = "http://www.nicholashastings.com"
}

new const String:g_szOtSounds[][] = {
	"vo/announcer_overtime.wav",
	"vo/announcer_overtime2.wav",
	"vo/announcer_overtime3.wav",
	"vo/announcer_overtime4.wav"
};

enum clientOT
{
	Handle:clientOT_Timer = INVALID_HANDLE,
	clientOT_OTLeft = 0
};

new Handle:g_EffectTimers[MAXPLAYERS+1] = INVALID_HANDLE;

// powerplay
new Handle:g_cvPowerPlayEnable;
new Handle:g_cvPowerPlayDuration;
new g_eidPowerPlay = -1;

// Ubercharge
new Handle:g_cvUberChargeEnable;
new Handle:g_cvUberChargeDuration;

// Buffed
new Handle:g_cvMiniCritBuffEnable;
new Handle:g_cvMiniCritBuffDuration;

// Crits
new Handle:g_cvCritsEnable;
new Handle:g_cvCritsDuration;

// overtime!
new Handle:g_cvOvertimeEnable;
new Handle:g_cvOvertimeDuration;
new g_eidOvertime = -1;

// Drainage (buff meter, ubercharge meter, cloak meter, stun meter, charge meter/heads, remove all good conds)
new Handle:g_cvDrainageEnable;

// Forced taunt
new Handle:g_cvTauntEnable;
new Handle:g_cvTauntDuration;
new g_eidTaunt = -1;

// Jarate
new Handle:g_cvJarateEnable;
new Handle:g_cvJarateDuration;

// Bonk'd
new Handle:g_cvBonkdEnable;
new Handle:g_cvBonkdDuration;

// Scared
new Handle:g_cvScaredEnable;
new Handle:g_cvScaredDuration;

public OnPluginStart()
{
	g_cvPowerPlayEnable = CreateConVar("psyrtd_powerplay_enable", "1", "Enable rolling PowerPlay", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_cvPowerPlayDuration = CreateConVar("psyrtd_powerplay_duration", "8", "Duration of PowerPlay effect", FCVAR_PLUGIN, true, 1.0);
	HookConVarChange(g_cvPowerPlayDuration, OnPowerPlayDurationChanged);
	
	g_cvUberChargeEnable = CreateConVar("psyrtd_ubercharge_enable", "1", "Enable rolling UberCharge", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_cvUberChargeDuration = CreateConVar("psyrtd_ubercharge_duration", "9", "Duration of UberCharge effect", FCVAR_PLUGIN, true, 1.0);
	
	g_cvMiniCritBuffEnable = CreateConVar("psyrtd_minicritbuff_enable", "1", "Enable rolling MiniCrit Buff", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_cvMiniCritBuffDuration = CreateConVar("psyrtd_minicritbuff_duration", "10", "Duration of MiniCrit Buff effect", FCVAR_PLUGIN, true, 1.0);
	
	g_cvCritsEnable = CreateConVar("psyrtd_crits_enable", "1", "Enable rolling All Crits", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_cvCritsDuration = CreateConVar("psyrtd_crits_duration", "10", "Duration of All Crits effect", FCVAR_PLUGIN, true, 1.0);
	
	g_cvOvertimeEnable = CreateConVar("psyrtd_overtime_enable", "1", "Enable rolling Overtime", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_cvOvertimeDuration = CreateConVar("psyrtd_overtime_duration", "14", "Duration of Overtime Spam effect", FCVAR_PLUGIN, true, 1.0);
	HookConVarChange(g_cvOvertimeDuration, OnOvertimeDurationChanged);
	
	g_cvJarateEnable = CreateConVar("psyrtd_jarate_enable", "1", "Enable rolling Jarate", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_cvJarateDuration = CreateConVar("psyrtd_jarate_duration", "14", "Duration of Jarate effect", FCVAR_PLUGIN, true, 1.0);
	
	g_cvBonkdEnable = CreateConVar("psyrtd_bonkd_enable", "1", "Enable rolling Bonk'd", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_cvBonkdDuration = CreateConVar("psyrtd_bonkd_duration", "10", "Duration of Bonk'd effect", FCVAR_PLUGIN, true, 1.0);
	
	g_cvScaredEnable = CreateConVar("psyrtd_scared_enable", "1", "Enable rolling Fear", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_cvScaredDuration = CreateConVar("psyrtd_scared_duration", "12", "Duration of Fear effect", FCVAR_PLUGIN, true, 1.0);
	
	g_cvTauntEnable = CreateConVar("psyrtd_taunt_enable", "1", "Enable rolling Force Taunt", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_cvTauntDuration = CreateConVar("psyrtd_taunt_duration", "12", "Duration of Force Taunt effect", FCVAR_PLUGIN, true, 1.0);
	HookConVarChange(g_cvTauntDuration, OnTauntDurationChanged);
	
	g_cvDrainageEnable = CreateConVar("psyrtd_drainage_enable", "1", "Enable rolling Drainage", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	
	AutoExecConfig(true, "psyrtd_tf2");
}

public OnAllPluginsLoaded()
{
	if (!LibraryExists("psyrtd"))
	{
		SetFailState("psyRTD Not Found!");
	}
	
	if (psyRTD_GetGame() != psyRTDGame_TF)
	{
		SetFailState("This module only supports TF2");
	}
	
	g_eidPowerPlay = psyRTD_RegisterTimedEffect(psyRTDEffectType_Good, "PowerPlay", GetConVarFloat(g_cvPowerPlayDuration), DoPowerPlay, EndPowerPlay);
	psyRTD_RegisterEffect(psyRTDEffectType_Good, "UberCharge", DoUberCharge);
	psyRTD_RegisterEffect(psyRTDEffectType_Good, "MiniCrit Buff", DoMiniCritBuff);
	psyRTD_RegisterEffect(psyRTDEffectType_Good, "All Crits", DoCrits);
	g_eidOvertime = psyRTD_RegisterTimedEffect(psyRTDEffectType_Bad, "Overtime Spam", GetConVarFloat(g_cvOvertimeDuration), DoOvertime, EndOvertime);
	psyRTD_RegisterEffect(psyRTDEffectType_Bad, "Jarate", DoJarate);
	psyRTD_RegisterEffect(psyRTDEffectType_Bad, "Bonk'd", DoBonkd);
	psyRTD_RegisterEffect(psyRTDEffectType_Bad, "Fear", DoScared);
	g_eidTaunt = psyRTD_RegisterTimedEffect(psyRTDEffectType_Bad, "Force Taunt", GetConVarFloat(g_cvTauntDuration), DoTaunt, EndTaunt);
	psyRTD_RegisterEffect(psyRTDEffectType_Bad, "Drainage", DoDrainage);
}

public OnPluginUnload()
{
	psyRTD_UnregisterAllEffects();
}

public OnMapStart()
{
	for (new i = 0; i < sizeof(g_szOtSounds); i++)
	{
		PRECACHESOUND(g_szOtSounds[i]);
	}
}

public psyRTDAction:DoPowerPlay(client)
{
	if (!GetConVarBool(g_cvPowerPlayEnable))
	{
		return psyRTD_Reroll;
	}
	
	TF2_SetPlayerPowerPlay(client, true);
	
	return psyRTD_Continue;
}

public EndPowerPlay(client, psyRTDEffectEndReason:reason)
{
	if (IsClientInGame(client))
	{
		TF2_SetPlayerPowerPlay(client, false);
	}
}

public psyRTDAction:DoUberCharge(client)
{
	if (!GetConVarBool(g_cvUberChargeEnable))
	{
		return psyRTD_Reroll;
	}
	
	TF2_AddCondition(client, TFCond_Ubercharged, GetConVarFloat(g_cvUberChargeDuration));
	
	return psyRTD_Continue;
}

public psyRTDAction:DoMiniCritBuff(client)
{
	if (!GetConVarBool(g_cvMiniCritBuffEnable))
	{
		return psyRTD_Reroll;
	}
	
	TF2_AddCondition(client, TFCond_Buffed, GetConVarFloat(g_cvMiniCritBuffDuration));
	
	return psyRTD_Continue;
}

public psyRTDAction:DoCrits(client)
{
	if (!GetConVarBool(g_cvCritsEnable))
	{
		return psyRTD_Reroll;
	}
	
	TF2_AddCondition(client, TFCond_Kritzkrieged, GetConVarFloat(g_cvCritsDuration));
	
	return psyRTD_Continue;
}

public psyRTDAction:DoOvertime(client)
{
	if (!GetConVarBool(g_cvOvertimeEnable))
	{
		return psyRTD_Reroll;
	}
	
	new userid = GetClientUserId(client);
	
	Timer_Overtime(INVALID_HANDLE, userid);
	g_EffectTimers[client] = CreateTimer(1.0, Timer_Overtime, userid, TIMER_REPEAT);
	
	return psyRTD_Continue;
}

public EndOvertime(client, psyRTDEffectEndReason:reason)
{
	if (g_EffectTimers[client] != INVALID_HANDLE)
	{
		CloseHandle(g_EffectTimers[client]);
	}
	g_EffectTimers[client] = INVALID_HANDLE;
}

public psyRTDAction:DoJarate(client)
{
	if (!GetConVarBool(g_cvJarateEnable))
	{
		return psyRTD_Reroll;
	}
	
	TF2_AddCondition(client, TFCond_Jarated, GetConVarFloat(g_cvJarateDuration));
	
	return psyRTD_Continue;
}

public psyRTDAction:DoBonkd(client)
{
	if (!GetConVarBool(g_cvBonkdEnable))
	{
		return psyRTD_Reroll;
	}
	
	TF2_StunPlayer(client, GetConVarFloat(g_cvBonkdDuration), _, TF_STUNFLAGS_BIGBONK);
	
	return psyRTD_Continue;
}

public psyRTDAction:DoScared(client)
{
	if (!GetConVarBool(g_cvScaredEnable))
	{
		return psyRTD_Reroll;
	}
	
	TF2_StunPlayer(client, GetConVarFloat(g_cvScaredDuration), 0.65, TF_STUNFLAGS_LOSERSTATE);
	
	return psyRTD_Continue;
}

public psyRTDAction:DoTaunt(client)
{
	if (!GetConVarBool(g_cvTauntEnable))
	{
		return psyRTD_Reroll;
	}
	
	new userid = GetClientUserId(client);
	
	Timer_Taunt(INVALID_HANDLE, userid);
	g_EffectTimers[client] = CreateTimer(1.0, Timer_Taunt, userid, TIMER_REPEAT);
	
	return psyRTD_Continue;
}

public EndTaunt(client, psyRTDEffectEndReason:reason)
{
	if (g_EffectTimers[client] != INVALID_HANDLE)
	{
		CloseHandle(g_EffectTimers[client]);
	}
	g_EffectTimers[client] = INVALID_HANDLE;
}

public psyRTDAction:DoDrainage(client)
{
	if (!GetConVarBool(g_cvDrainageEnable))
	{
		return psyRTD_Reroll;
	}
	
	new TFClassType:class = TF2_GetPlayerClass(client);
	switch (class)
	{
	case TFClass_Sniper:
		return psyRTD_NotApplicable;
	case TFClass_Heavy:
		return psyRTD_NotApplicable;
	case TFClass_Pyro:
		return psyRTD_NotApplicable;
	case TFClass_Engineer:
		return psyRTD_NotApplicable;
	}
	
	SetEntProp(client, Prop_Send, "m_iDecapitations", 0);
	SetEntPropFloat(client, Prop_Send, "m_flRageMeter", 0.0);
	SetEntPropFloat(client, Prop_Send, "m_flEnergyDrinkMeter", 0.0);
	SetEntPropFloat(client, Prop_Send, "m_flCloakMeter", 0.0);
	SetEntPropFloat(client, Prop_Send, "m_flChargeLevel", 0.0);
	
	TF2_RemovePlayerDisguise(client);
	TF2_RemoveCondition(client, TFCond_Cloaked);
	TF2_RemoveCondition(client, TFCond_Disguised);
	TF2_RemoveCondition(client, TFCond_Ubercharged);
	TF2_RemoveCondition(client, TFCond_Kritzkrieged);
	TF2_RemoveCondition(client, TFCond_Buffed);
	
	return psyRTD_Continue;
}

public Action:Timer_Overtime(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	if (client == 0 || !IsClientInGame(client))
	{
		g_EffectTimers[client] = INVALID_HANDLE;
		return Plugin_Stop;
	}
	
	EmitSoundToClient(client, g_szOtSounds[GetURandomIntRange(0,3)]);
	
	return Plugin_Continue;
}

public Action:Timer_Taunt(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	if (client == 0 || !IsClientInGame(client))
	{
		g_EffectTimers[client] = INVALID_HANDLE;
		return Plugin_Stop;
	}
	
	FakeClientCommand(client, "taunt");
	
	return Plugin_Continue;
}

public OnPowerPlayDurationChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	psyRTD_ChangeEffectDuration(g_eidPowerPlay, psyRTDEffectType_Good, atof(newValue));
}

public OnOvertimeDurationChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	psyRTD_ChangeEffectDuration(g_eidOvertime, psyRTDEffectType_Bad, atof(newValue));
}

public OnTauntDurationChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	psyRTD_ChangeEffectDuration(g_eidTaunt, psyRTDEffectType_Bad, atof(newValue));
}

stock GetURandomIntRange(min, max)
{
	return (GetURandomInt() % (max-min+1)) + min;
}