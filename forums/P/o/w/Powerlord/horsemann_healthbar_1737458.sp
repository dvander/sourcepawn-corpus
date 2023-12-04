#include <sourcemod>
#include <sdkhooks>
#include <sdktools>

// Require TF2 module to make it fail when loading any non-TF2 (or TF2 Beta) game
#include <tf2>

#pragma semicolon 1

#define VERSION "1.3.2"

#define HORSEMANN "headless_hatman"
#define MONOCULUS "eyeball_boss"

#define HEALTHBAR_CLASS "monster_resource"
#define HEALTHBAR_PROPERTY "m_iBossHealthPercentageByte"
#define HEALTHBAR_MAX 255
#define FF2 "freak_fortress_2"

new Handle:cvarHealthBar;
new Handle:cvarOtherHealthBar;
new Handle:cvarOtherEnabled;

new g_trackEntity = -1;
new g_healthBar = -1;
new g_Monoculus = -1;

public Plugin:myinfo = 
{
	name = "Horsemann Health Bar",
	author = "Powerlord",
	description = "Give the Horseless Headless Horsemann the Monoculus health bar",
	version = VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=188543"
}

public OnPluginStart()
{
	CreateConVar("horsemann_healthbar_version", VERSION, "Horsemann Healthbar Version", FCVAR_DONTRECORD | FCVAR_NOTIFY);
	cvarHealthBar = CreateConVar("horsemann_healthbar_enabled", "1", "Enabled Horsemann Healthbar?", FCVAR_NONE, true, 0.0, true, 1.0);
	HookConVarChange(cvarHealthBar, EnableChanged);
}

public OnAllPluginsLoaded()
{
	cvarOtherEnabled = FindConVar("ff2_enabled");
	cvarOtherHealthBar = FindConVar("ff2_health_bar");
}

public EnableChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	// Easier than checking newvalue and oldvalue
	if (GetConVarBool(cvarHealthBar))
	{
		g_Monoculus = FindEntityByClassname(-1, MONOCULUS);
		g_trackEntity = FindEntityByClassname(-1, HORSEMANN);

		if (g_trackEntity > -1)
		{
			SDKHook(g_trackEntity, SDKHook_SpawnPost, UpdateBossHealth);
			SDKHook(g_trackEntity, SDKHook_OnTakeDamagePost, OnHorsemannDamaged);
		}
	}
	else
	{
		if (g_trackEntity > -1)
		{
			SDKUnhook(g_trackEntity, SDKHook_SpawnPost, UpdateBossHealth);
			SDKUnhook(g_trackEntity, SDKHook_OnTakeDamagePost, OnHorsemannDamaged);
		}
		
		if (g_Monoculus == -1)
		{
			UpdateBossHealth(-1);
		}
	}
}


public OnMapStart()
{
	FindHealthBar();
}

public OnLibraryAdded(const String:name[])
{
	if (StrEqual(name, FF2))
	{
		cvarOtherEnabled = FindConVar("ff2_enabled");
		cvarOtherHealthBar = FindConVar("ff2_health_bar");
	}
}

public OnLibraryRemoved(const String:name[])
{
	if (StrEqual(name, FF2))
	{
		cvarOtherEnabled = INVALID_HANDLE;
		cvarOtherHealthBar = INVALID_HANDLE;
	}
}

public OnEntityCreated(entity, const String:classname[])
{
	if (!GetConVarBool(cvarHealthBar))
	{
		return;
	}

	if (StrEqual(classname, HEALTHBAR_CLASS))
	{
		g_healthBar = entity;
	}
	else if (g_Monoculus == -1 && StrEqual(classname, MONOCULUS))
	{
		g_Monoculus = entity;
	}
	else if (g_trackEntity == -1 && StrEqual(classname, HORSEMANN))
	{
		g_trackEntity = entity;
		SDKHook(entity, SDKHook_SpawnPost, UpdateBossHealth);
		SDKHook(entity, SDKHook_OnTakeDamagePost, OnHorsemannDamaged);
	}
}

public OnEntityDestroyed(entity)
{
	// This assumes entity never equals -1
	
	if (entity == -1)
	{
		return;
	}
	
	if (entity == g_Monoculus)
	{
		g_Monoculus = FindEntityByClassname(-1, MONOCULUS);
		if (g_Monoculus == entity)
		{
			g_Monoculus = FindEntityByClassname(entity, MONOCULUS);
		}
	}
	else if (entity == g_trackEntity)
	{
		g_trackEntity = FindEntityByClassname(-1, HORSEMANN);
		if (g_trackEntity == entity)
		{
			g_trackEntity = FindEntityByClassname(entity, HORSEMANN);
		}
			
		if (g_trackEntity > -1)
		{
			SDKHook(g_trackEntity, SDKHook_OnTakeDamagePost, OnHorsemannDamaged);
		}
		UpdateBossHealth(g_trackEntity);
	}
	
}

public OnHorsemannDamaged(victim, attacker, inflictor, Float:damage, damagetype)
{
	UpdateBossHealth(victim);
}

public UpdateBossHealth(entity)
{
	if (g_healthBar == -1)
	{
		return;
	}
	
	if (!GetConVarBool(cvarHealthBar) || g_Monoculus != -1)
	{
		return;
	}

	if (cvarOtherEnabled != INVALID_HANDLE && cvarOtherHealthBar != INVALID_HANDLE && GetConVarBool(cvarOtherEnabled) && GetConVarBool(cvarOtherHealthBar))
	{
		return;
	}
	
	new percentage;
	if (IsValidEntity(entity))
	{
		new iMaxHealth = GetEntProp(entity, Prop_Data, "m_iMaxHealth");
		new iHealth = GetEntProp(entity, Prop_Data, "m_iHealth");
		
		if (iMaxHealth <= 0)
		{
			percentage = 0;
		}
		else
		{
			percentage = RoundToCeil(float(iHealth) / iMaxHealth * HEALTHBAR_MAX);
		}
	}
	else
	{
		percentage = 0;
	}
	
	SetEntProp(g_healthBar, Prop_Send, HEALTHBAR_PROPERTY, percentage);
}

FindHealthBar()
{
	g_healthBar = FindEntityByClassname(-1, HEALTHBAR_CLASS);
	
	if (g_healthBar == -1)
	{
		g_healthBar = CreateEntityByName(HEALTHBAR_CLASS);
		if (g_healthBar != -1)
		{
			DispatchSpawn(g_healthBar);
		}
	}
}
