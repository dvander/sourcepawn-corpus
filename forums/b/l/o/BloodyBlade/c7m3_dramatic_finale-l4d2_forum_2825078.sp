#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>

#define CVAR_FLAGS FCVAR_NOTIFY

ConVar hPluginOn, hDesiredTimeScale, hAcceleration, hMinBlendRate, hBlendDeltaMultiplier;
bool IsTheSacrificeFinale = false, IsDramaticFinaleNeeded = false;
char cDesiredTimeScale[8], cAcceleration[8], cMinBlendRate[8], cBlendDeltaMultiplier[8];

public Plugin myinfo =
{
	name = "[L4D2] The Sacrifice Dramatic Finale",
	author = "cravenge",
	description = "Adds Dramatic Effects To The Sacrifice Finale.",
	version = "1.1",
	url = ""
};

public void OnPluginStart()
{
	CreateConVar("c7m3_dramatic_finale-l4d2_version", "1.0", "The Sacrifice Dramatic Finale Version", CVAR_FLAGS|FCVAR_DONTRECORD);
	hPluginOn = CreateConVar("c7m3_dramatic_finale_on", "1.0", "Plugin On/Off", CVAR_FLAGS);
	hDesiredTimeScale = CreateConVar("c7m3_desired_time_scale", "0.2", "Desired time scale of slow motion effect", CVAR_FLAGS);
	hAcceleration = CreateConVar("c7m3_acceleration", "2.0", "Acceleration of slow motion effect", CVAR_FLAGS);
	hMinBlendRate = CreateConVar("c7m3_ min_blend_rate", "1.0", "Minimum blend rate of slow motion effect", CVAR_FLAGS);
	hBlendDeltaMultiplier = CreateConVar("c7m3_blend_delta_multiplier", "2.0", "Blend delta multiplier of slow motion effect", CVAR_FLAGS);

	hPluginOn.AddChangeHook(ConVarPluginOnChanged);
	hDesiredTimeScale.AddChangeHook(ConVarDesiredTimeScaleChanged);
	hAcceleration.AddChangeHook(ConVarDesiredTimeScaleChanged);
	hMinBlendRate.AddChangeHook(ConVarDesiredTimeScaleChanged);
	hBlendDeltaMultiplier.AddChangeHook(ConVarDesiredTimeScaleChanged);

	AutoExecConfig(true, "l4d2_TheSacrificeDramaticFinale");
}

public void OnMapStart()
{
	char mapname[64];
	GetCurrentMap(mapname, sizeof(mapname));
	if(StrEqual(mapname, "c7m3_port")) IsTheSacrificeFinale = true;
	else IsTheSacrificeFinale = false;
}

public void OnConfigsExecuted()
{
	IsAllowed();
}

void IsAllowed()
{
	bool PluginOn = hPluginOn.BoolValue;
	if(PluginOn)
	{
		HookEvent("finale_escape_start", OnFinaleEscapeStart);
		HookEvent("tank_spawn", OnEffectsAdded);
		HookEvent("finale_win", OnEffectsRemoved);
		HookEvent("mission_lost", OnEffectsRemoved);
		HookEvent("round_end", OnEffectsRemoved);
	}
	else
	{
		UnhookEvent("finale_escape_start", OnFinaleEscapeStart);
		UnhookEvent("tank_spawn", OnEffectsAdded);
		UnhookEvent("finale_win", OnEffectsRemoved);
		UnhookEvent("mission_lost", OnEffectsRemoved);
		UnhookEvent("round_end", OnEffectsRemoved);
	}
}

void GetCvars()
{
	hDesiredTimeScale.GetString(cDesiredTimeScale, sizeof(cDesiredTimeScale));
	hAcceleration.GetString(cAcceleration, sizeof(cAcceleration));
	hMinBlendRate.GetString(cMinBlendRate, sizeof(cMinBlendRate));
	hBlendDeltaMultiplier.GetString(cBlendDeltaMultiplier, sizeof(cBlendDeltaMultiplier));
}

void ConVarPluginOnChanged(ConVar cvar, const char[] oldVal, const char[] newVal)
{
	if (StringToInt(newVal) != StringToInt(oldVal)) IsAllowed();
}

void ConVarDesiredTimeScaleChanged(ConVar cvar, const char[] oldVal, const char[] newVal)
{
	if (StringToFloat(newVal) != StringToFloat(oldVal)) GetCvars();
}

Action OnFinaleEscapeStart(Event event, const char[] name, bool dontBroadcast)
{
	if(IsTheSacrificeFinale) IsDramaticFinaleNeeded = true;
	else IsDramaticFinaleNeeded = false;
	return Plugin_Continue;
}

Action OnEffectsAdded(Event event, const char[] name, bool dontBroadcast)
{
	if(IsTheSacrificeFinale && IsDramaticFinaleNeeded) SlowMotionEffects();
	return Plugin_Continue;
}

Action OnEffectsRemoved(Event event, const char[] name, bool dontBroadcast)
{
	if(IsTheSacrificeFinale) IsDramaticFinaleNeeded = false;
	return Plugin_Continue;
}

stock void SlowMotionEffects(const char[] desiredTimeScale = cDesiredTimeScale, const char[] re_Acceleration = cAcceleration, const char[] minBlendRate = cMinBlendRate, const char[] blendDeltaMultiplier = cBlendDeltaMultiplier)
{
	int ent = CreateEntityByName("func_timescale");
	DispatchKeyValue(ent, "desiredTimescale", desiredTimeScale);
	DispatchKeyValue(ent, "acceleration", re_Acceleration);
	DispatchKeyValue(ent, "minBlendRate", minBlendRate);
	DispatchKeyValue(ent, "blendDeltaMultiplier", blendDeltaMultiplier);
	DispatchSpawn(ent);
	AcceptEntityInput(ent, "Start");
	CreateTimer(1.0, RevertBackToNormal, ent, TIMER_REPEAT);
}

Action RevertBackToNormal(Handle timer, any ent)
{
	if(!IsDramaticFinaleNeeded && IsValidEdict(ent))
	{
		AcceptEntityInput(ent, "Stop");
		return Plugin_Stop;
	}
	return Plugin_Continue;
}
