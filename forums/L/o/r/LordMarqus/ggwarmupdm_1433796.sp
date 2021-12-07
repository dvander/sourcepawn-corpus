#include <sourcemod>
#include <gungame>

new Handle:g_hCvarDmEnabled = INVALID_HANDLE;
new Handle:g_hCvarRemoveRagdolls = INVALID_HANDLE;

new g_bCvarsLoaded = false;

public Plugin:myinfo = 
{
	name = "GGWarmupDM",
	author = "LordMarqus",
	description = "GunGame warmup Deathmatch",
	version = "1.0.0",
	url = "http://www.sourcemod.net/"
}

public OnPluginStart()
{
	HookEvent("round_start", EventRoundStart, EventHookMode_Pre);
}

public OnMapStart()
{
	g_bCvarsLoaded = false;
}

FindConVars()
{	
	g_hCvarDmEnabled = FindConVar("sm_ggdm_enable");
	if(g_hCvarDmEnabled == INVALID_HANDLE)
	{
		LogError("Cannot find 'sm_ggdm_enable' cvar!");
	}
	
	g_hCvarRemoveRagdolls = FindConVar("sm_ggdm_removeragdolls");
	if(g_hCvarRemoveRagdolls == INVALID_HANDLE)
	{
		LogError("Cannot find 'sm_ggdm_removeragdolls' cvar!");
	}
	
	g_bCvarsLoaded = true;
}	

public OnConfigsExecuted()
{
	FindConVars();

	StripConVarNotifyFlag(g_hCvarRemoveRagdolls);
	
	SwitchOnWarmup();
}

public GG_OnWarmupEnd()
{
	CreateTimer(2.5, DelayedWarmupEnd);
}

public Action:DelayedWarmupEnd(Handle:timer)
{
	if(g_bCvarsLoaded)
		SwitchOnWarmup();
}

public Action:EventRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_bCvarsLoaded)
		SwitchOnWarmup();
	
	return Plugin_Continue;
}

SwitchOnWarmup()
{
	new bool:isWarmup = GG_IsWarmupInProgress();

	Safe_SetConVarBool(g_hCvarDmEnabled, isWarmup);
	Safe_SetConVarBool(g_hCvarRemoveRagdolls, isWarmup);
}

stock Safe_SetConVarBool(Handle:convar, bool:value, bool:replicate = false, bool:notify = false)
{
	if(convar != INVALID_HANDLE)
	{
		SetConVarBool(convar, value, replicate, notify);
	}
}

stock StripConVarNotifyFlag(Handle:cvar)
{
	if(cvar != INVALID_HANDLE)
	{
		new flags = GetConVarFlags(cvar);
		flags &= ~FCVAR_NOTIFY;
		SetConVarFlags(cvar, flags);
	}
}

