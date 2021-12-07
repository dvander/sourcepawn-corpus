#pragma semicolon 1

#include <sourcemod>
#include <tf2_stocks>
#include <tf2items>
#include <sdkhooks>
#include <sdktools>

#define PLUGIN_VERSION "1.1.0"

new Handle:cvarEnabled;
new Handle:cvarAdmins;
new Handle:cvarUberTime;

#define HORSEMANN (1 << 0) // 1
#define MONOCULUS (1 << 1) // 2
#define MERASMUS (1 << 2) // 4

new Enabled;
new bool:Admins;
new g_Horsemann;
new g_Monoculus;
new g_Merasmus;
new Float:g_UberTime;

public Plugin:myinfo =
{
	name = "Halloween Boss Player Kill Block",
	author = "ReFlexPoison",
	description = "Blocks killing of the other team during a boss encounter",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net",
}

public OnPluginStart()
{
	CreateConVar("sm_hkillblock_version", PLUGIN_VERSION, "Halloween Boss Player Kill Block Version", FCVAR_REPLICATED | FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_DONTRECORD | FCVAR_NOTIFY);

	cvarEnabled = CreateConVar("sm_hkillblock_bosses", "7", "What bosses does this have effect on? (Add up the numbers to choose)\n0 = Disabled\n1 = Horsemann\n2 = Monoculus\n4 = Merasmus", FCVAR_PLUGIN, true, 0.0, true, 7.0);
	cvarAdmins = CreateConVar("sm_hkillblock_admin_override", "0", "Enable override (sm_hkillblock_override_flag) that allows admins to have the ability to kill\n0 = Disabled\n1 = Enabled", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvarUberTime = CreateConVar("sm_hkillblock_ubertime", "30", "Time UberCharge lasts after a boss kill\n0 = Disabled", FCVAR_PLUGIN, true, 0.0);

	Enabled = GetConVarInt(cvarEnabled);
	Admins = GetConVarBool(cvarAdmins);
	g_UberTime = GetConVarFloat(cvarUberTime);
	
	AutoExecConfig(true, "plugin.hkillblock");

	HookConVarChange(cvarEnabled, CVarChange);
	HookConVarChange(cvarAdmins, CVarChange);
	HookConVarChange(cvarUberTime, CVarChange);

	//Player Spawn
	HookEvent("player_spawn", OnPlayerSpawn);

	//Round Start|End
	HookEvent("teamplay_round_start", OnRoundChange);
	HookEvent("teamplay_round_win", OnRoundChange);

	//Spawn
	HookEvent("pumpkin_lord_summoned", OnHHHSpawned);
	HookEvent("eyeball_boss_summoned", OnMONOSpawned);
	HookEvent("merasmus_summoned", OnMERASpawned);

	//Despawn
	HookEvent("pumpkin_lord_killed", OnHHHKill);
	HookEvent("eyeball_boss_killed", OnMONOKill);
	HookEvent("eyeball_boss_escaped", OnMONODespawn);
	HookEvent("merasmus_killed", OnMERAKill);
	HookEvent("merasmus_escaped", OnMERADespawn);

	g_Horsemann = 0;
	g_Monoculus = 0;
	g_Merasmus = 0;
}

public CVarChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if(convar == cvarEnabled) Enabled = GetConVarInt(cvarEnabled);
	if(convar == cvarAdmins) Admins = GetConVarBool(cvarAdmins);
	if(convar == cvarUberTime) g_UberTime = GetConVarFloat(cvarUberTime);
}

public OnMapStart()
{
	g_Horsemann = 0;
	g_Monoculus = 0;
	g_Merasmus = 0;
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnClientTakeDamage);
}

public Action:TF2Items_OnGiveNamedItem(client, String:classname[], iItemDefinitionIndex, &Handle:hItem)
{
	if(!IsValidClient(client)) return Plugin_Continue;

	if(g_Horsemann > 0 || g_Monoculus > 0 || g_Merasmus > 0)
	{
		if(TF2_GetPlayerClass(client) == TFClass_Spy)
		{
			if(StrEqual(classname, "tf_weapon_builder") || StrEqual(classname, "tf_weapon_sapper")) return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}

public Action:OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if(g_Horsemann > 0 || g_Monoculus > 0 || g_Merasmus > 0)
	{
		if(IsValidClient(client)) SetEntityFlags(client, GetEntityFlags(client) | FL_NOTARGET);
	}
}

public Action:OnRoundChange(Handle:event, const String:name[], bool:dontBroadcast)
{
	g_Horsemann = 0;
	g_Monoculus = 0;
	g_Merasmus = 0;
	DeathSets();
}

public Action:OnHHHSpawned(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(Enabled & HORSEMANN)
	{
		g_Horsemann += 1;
		SpawnSets();
	}
}

public Action:OnMONOSpawned(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(Enabled & MONOCULUS)
	{
		g_Monoculus += 1;
		SpawnSets();
	}
}

public Action:OnMERASpawned(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(Enabled & MERASMUS)
	{
		g_Merasmus += 1;
		SpawnSets();
	}
}

public Action:OnHHHKill(Handle:event, const String:name[], bool:dontBroadcast)
{
	g_Horsemann -= 1;
	DeathSets();
	if(g_UberTime > 0.0)
	{
		for(new i = 1; i <= MaxClients; i++)
		{
			if(IsValidClient(i) && IsPlayerAlive(i)) TF2_AddCondition(i, TFCond_Ubercharged, g_UberTime);
		}
		PrintToChatAll("\x01[SM] UberCharge enabled on all players for \x03%f\x01 seconds!", g_UberTime);
	}
}

public Action:OnMONOKill(Handle:event, const String:name[], bool:dontBroadcast)
{
	g_Monoculus -= 1;
	DeathSets();
	if(g_UberTime > 0.0)
	{
		for(new i = 1; i <= MaxClients; i++)
		{
			if(IsValidClient(i) && IsPlayerAlive(i)) TF2_AddCondition(i, TFCond_Ubercharged, g_UberTime);
		}
		PrintToChatAll("\x01[SM] UberCharge enabled on all players for \x03%f\x01 seconds!", g_UberTime);
	}
}

public Action:OnMONODespawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	g_Monoculus -= 1;
	DeathSets();
}

public Action:OnMERAKill(Handle:event, const String:name[], bool:dontBroadcast)
{
	g_Merasmus -= 1;
	DeathSets();
	if(g_UberTime > 0.0)
	{
		for(new i = 1; i <= MaxClients; i++)
		{
			if(IsValidClient(i) && IsPlayerAlive(i)) TF2_AddCondition(i, TFCond_Ubercharged, g_UberTime);
		}
		PrintToChatAll("\x01[SM] UberCharge enabled on all players for \x03%f\x01 seconds!", g_UberTime);
	}
}

public Action:OnMERADespawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	g_Merasmus -= 1;
	DeathSets();
}

public OnEntityCreated(entity, const String:classname[])
{
	if(Enabled <= 0 || !IsValidEntity(entity)) return;
	if(g_Horsemann <= 0 && g_Monoculus <= 0 && g_Merasmus <= 0) return;

	if(StrEqual(classname, "obj_sentrygun", false))
	{
		SDKHook(entity, SDKHook_OnTakeDamage, OnEntityTakeDamage);
		SetEntityFlags(entity, GetEntityFlags(entity) | FL_NOTARGET);
	}
	if(StrEqual(classname, "obj_dispenser", false))
	{
		SDKHook(entity, SDKHook_OnTakeDamage, OnEntityTakeDamage);
		SetEntityFlags(entity, GetEntityFlags(entity) | FL_NOTARGET);
	}
	if(StrEqual(classname, "obj_teleporter", false))
	{
		SDKHook(entity, SDKHook_OnTakeDamage, OnEntityTakeDamage);
		SetEntityFlags(entity, GetEntityFlags(entity) | FL_NOTARGET);
	}
}

public Action:OnClientTakeDamage(client, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3])
{
	if(Enabled <= 0) return Plugin_Continue;
	if(!IsValidClient(client) || !IsValidClient(attacker)) return Plugin_Continue;
	if(client == attacker) return Plugin_Continue;
	if(Admins && CheckCommandAccess(attacker, "sm_hkillblock_override_flag", ADMFLAG_BAN)) return Plugin_Continue;

	if(GetClientTeam(client) > 1 && GetClientTeam(attacker) > 1)
	{
		if(g_Horsemann > 0 || g_Monoculus > 0 || g_Merasmus > 0)
		{
			damage = 0.0;
			return Plugin_Changed;
		}
	}
	return Plugin_Continue;
}

public Action:OnEntityTakeDamage(entity, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3])
{
	if(Enabled <= 0) return Plugin_Continue;
	if(!IsValidEntity(entity) || !IsValidClient(attacker)) return Plugin_Continue;
	if(GetEntPropEnt(entity, Prop_Send, "m_hBuilder") == attacker) return Plugin_Continue;
	if(Admins && CheckCommandAccess(attacker, "sm_hkillblock_override_flag", ADMFLAG_BAN)) return Plugin_Continue;

	if(g_Horsemann > 0 || g_Monoculus > 0 || g_Merasmus > 0)
	{
		damage = 0.0;
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

stock bool:IsValidClient(client, bool:replay = true)
{
	if(client <= 0 || client > MaxClients || !IsClientInGame(client) || GetEntProp(client, Prop_Send, "m_bIsCoaching")) return false;
	if(replay && (IsClientSourceTV(client) || IsClientReplay(client))) return false;
	return true;
}

stock SpawnSets()
{
	for(new i = 0; i <= MaxClients; i++)
	{
		if(IsValidClient(i)) SetEntityFlags(i, GetEntityFlags(i) | FL_NOTARGET);
	}

	new ent = -1;
	TargetSet(ent, true);
}

stock DeathSets()
{
	if(g_Horsemann > 0 || g_Monoculus > 0 || g_Merasmus > 0) return;

	for(new i = 0; i <= MaxClients; i++)
	{
		if(IsValidClient(i)) SetEntityFlags(i, GetEntityFlags(i) &~ FL_NOTARGET);
	}

	new ent = -1;
	TargetSet(ent, false);
}

stock TargetSet(ent, bool:enable)
{
	if(enable)
	{
		while((ent = FindEntityByClassname(ent, "obj_sentrygun")) != INVALID_ENT_REFERENCE)
		{
			if(IsValidEntity(ent))
			{
				SDKHook(ent, SDKHook_OnTakeDamage, OnEntityTakeDamage);
				SetEntityFlags(ent, GetEntityFlags(ent) | FL_NOTARGET);
			}
		}
		while((ent = FindEntityByClassname(ent, "obj_dispenser")) != INVALID_ENT_REFERENCE)
		{
			if(IsValidEntity(ent))
			{
				SDKHook(ent, SDKHook_OnTakeDamage, OnEntityTakeDamage);
				SetEntityFlags(ent, GetEntityFlags(ent) | FL_NOTARGET);
			}
		}
		while((ent = FindEntityByClassname(ent, "obj_teleporter")) != INVALID_ENT_REFERENCE)
		{
			if(IsValidEntity(ent))
			{
				SDKHook(ent, SDKHook_OnTakeDamage, OnEntityTakeDamage);
				SetEntityFlags(ent, GetEntityFlags(ent) | FL_NOTARGET);
			}
		}
	}
	else if(g_Horsemann <= 0 && g_Monoculus <= 0 && g_Merasmus <= 0)
	{
		while((ent = FindEntityByClassname(ent, "obj_sentrygun")) != INVALID_ENT_REFERENCE)
		{
			if(IsValidEntity(ent)) SetEntityFlags(ent, GetEntityFlags(ent) &~ FL_NOTARGET);
		}
		while((ent = FindEntityByClassname(ent, "obj_dispenser")) != INVALID_ENT_REFERENCE)
		{
			if(IsValidEntity(ent)) SetEntityFlags(ent, GetEntityFlags(ent) &~ FL_NOTARGET);
		}
		while((ent = FindEntityByClassname(ent, "obj_teleporter")) != INVALID_ENT_REFERENCE)
		{
			if(IsValidEntity(ent)) SetEntityFlags(ent, GetEntityFlags(ent) &~ FL_NOTARGET);
		}
	}
}