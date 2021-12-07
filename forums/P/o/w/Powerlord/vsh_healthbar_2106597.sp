#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

// Require TF2 module to make it fail when loading any non-TF2 (or TF2 Beta) game
#include <tf2>
#include <saxtonhale>

#pragma semicolon 1

#define VERSION "1.1"

#define RESOURCE 				"monster_resource"
#define RESOURCE_PROP			"m_iBossHealthPercentageByte"
#define HEALTHBAR_MAX			255.0

public Plugin:myinfo = 
{
	name = "VSH Health Bar",
	author = "Powerlord",
	description = "Track Saxton's Health using the boss health bar",
	version = VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=146884"
}

new Handle:g_Cvar_Enabled = INVALID_HANDLE;
new g_HealthBar = -1;
new g_Saxton = -1;

public OnPluginStart()
{
	CreateConVar("vsh_healthbar_version", VERSION, "Vs. Saxton Hale Healthbar Version", FCVAR_DONTRECORD | FCVAR_NOTIFY | FCVAR_PLUGIN);
	g_Cvar_Enabled = CreateConVar("vsh_healthbar_enabled", "1", "Enable VSH Healthbar?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	HookConVarChange(g_Cvar_Enabled, Cvar_Enabled);
	
	HookEvent("teamplay_round_start", Event_RoundStart);
	HookEvent("teamplay_round_win", Event_RoundEnd);
	HookEvent("player_hurt", Event_PlayerHurt);
}

public OnMapStart()
{
	g_Saxton = -1;
}

public Cvar_Enabled(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (!GetConVarBool(convar))
	{
		SetHealthBar(0.0);
	}
}

public OnEntityCreated(entity, const String:classname[])
{
	if (StrEqual(classname, RESOURCE))
	{
		g_HealthBar = EntIndexToEntRef(entity);
	}
}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!VSH_IsSaxtonHaleModeEnabled())
	{
		return;
	}
	
	CreateTimer(0.1, Timer_Hale, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action:Timer_Hale(Handle:timer)
{
	g_Saxton = VSH_GetSaxtonHaleUserId();
	SetHealthBar(100.0);
}

public Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!VSH_IsSaxtonHaleModeEnabled())
	{
		return;
	}
	g_Saxton = -1;
	SetHealthBar(0.0);
}

public Event_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!VSH_IsSaxtonHaleModeEnabled() || g_Saxton == -1)
	{
		return;
	}
	
	new userid = GetEventInt(event, "userid");
	
	if (userid != g_Saxton)
	{
		return;
	}
	
	new maxHealth = VSH_GetSaxtonHaleHealthMax();
	new health = VSH_GetSaxtonHaleHealth();
	
	new Float:newPercent = float(health) / float(maxHealth) * 100.0;
	SetHealthBar(newPercent);
}

SetHealthBar(Float:percent)
{
	new healthBar = EntRefToEntIndex(g_HealthBar);
	if (healthBar == -1 || !IsValidEntity(healthBar))
	{
		return;
	}
	// In practice, the multiplier is 2.55
	new Float:value = percent * (HEALTHBAR_MAX / 100.0);

	SetEntProp(healthBar, Prop_Send, RESOURCE_PROP, RoundToNearest(value));
}
