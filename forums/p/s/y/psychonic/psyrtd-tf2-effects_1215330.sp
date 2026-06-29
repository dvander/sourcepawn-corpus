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

// overtime!
new Handle:g_cvOvertimeEnable;
new Handle:g_cvOvertimeDuration;
new g_eidOvertime = -1;

public OnPluginStart()
{
	g_cvPowerPlayEnable = CreateConVar("psyrtd_powerplay_enable", "1", "Enable rolling PowerPlay", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_cvPowerPlayDuration = CreateConVar("psyrtd_powerplay_duration", "6", "Duration of PowerPlay effect", FCVAR_PLUGIN, true, 1.0);
	HookConVarChange(g_cvPowerPlayDuration, OnPowerPlayDurationChanged);
	
	g_cvOvertimeEnable = CreateConVar("psyrtd_overtime_enable", "1", "Enable rolling Overtime", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_cvOvertimeDuration = CreateConVar("psyrtd_overtime_duration", "12", "Duration of Overtime Spam effect", FCVAR_PLUGIN, true, 1.0);
	HookConVarChange(g_cvOvertimeDuration, OnOvertimeDurationChanged);
	
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
	g_eidOvertime = psyRTD_RegisterTimedEffect(psyRTDEffectType_Bad, "Overtime Spam", GetConVarFloat(g_cvOvertimeDuration), DoOvertime, EndOvertime);
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

public psyRTDAction:DoOvertime(client)
{
	if (!GetConVarBool(g_cvOvertimeEnable))
	{
		return psyRTD_Reroll;
	}
	
	new userid = GetClientUserId(client);
	
	Timer_Overtime(INVALID_HANDLE, userid);
	g_EffectTimers[client] = CreateTimer(1.2, Timer_Overtime, userid, TIMER_REPEAT);
	
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

public OnPowerPlayDurationChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	psyRTD_ChangeEffectDuration(g_eidPowerPlay, psyRTDEffectType_Good, atof(newValue));
}

public OnOvertimeDurationChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	psyRTD_ChangeEffectDuration(g_eidOvertime, psyRTDEffectType_Bad, atof(newValue));
}

stock GetURandomIntRange(min, max)
{
	return (GetURandomInt() % (max-min+1)) + min;
}