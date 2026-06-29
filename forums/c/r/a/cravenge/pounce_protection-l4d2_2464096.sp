#pragma semicolon 1
#include <sourcemod>
#include <sdkhooks>

#define PLUGIN_VERSION "1.2"
#define PLUGIN_AUTHOR "dcx2, cravenge"
#define PLUGIN_NAME "[L4D2] Pounce Protection"

new Handle:ppEnable = INVALID_HANDLE;
new Handle:ppSmokerDamage = INVALID_HANDLE;
new Handle:ppSmokerDamageIncap = INVALID_HANDLE;

new g_ProtectPin[MAXPLAYERS+1] = 0;

public Plugin:myinfo =
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = "Allows jockeys and smokers to protect their pin from other infected by pressing crouch",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?p=1973444"
};

public OnPluginStart()
{
	CreateConVar("pounce_protection_version", PLUGIN_VERSION, "Pounce Protection Version", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	ppEnable = CreateConVar("pounce_protection_enable", "1", "Enable/Disable Plugin", FCVAR_NOTIFY);
	ppSmokerDamage = CreateConVar("pounce_protection_smoker_damage", "10.0", "Damage Dealt To Smoker Protected Victims", FCVAR_NOTIFY);
	ppSmokerDamageIncap = CreateConVar("pounce_protection_smoker_damage_incap", "20.0", "Damage Dealt To Smoker Protected Incapacitated Victims", FCVAR_NOTIFY);
	
	HookEvent("tongue_grab", OnEnableProtection);
	HookEvent("jockey_ride", OnEnableProtection);
	HookEvent("tongue_release", OnDisableProtection);
	HookEvent("jockey_ride_end", OnDisableProtection);
	HookEvent("player_bot_replace", OnProtectionCheck);
	HookEvent("bot_player_replace", OnProtectionCheck);
}

public OnClientPostAdminCheck(client)
{
	SDKHook(client, SDKHook_OnTakeDamage, ProtectedDamageFix);
}

public Action:OnEnableProtection(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!GetConVarBool(ppEnable))
	{
		return Plugin_Continue;
	}
	
	new attacker = GetClientOfUserId(GetEventInt(event, "userid"));
	new victim = GetClientOfUserId(GetEventInt(event, "victim"));
	if (!attacker || !victim)
	{
		return Plugin_Continue;
	}
	
	g_ProtectPin[attacker] = victim;
	SetEntPropEnt(victim, Prop_Send, "m_pounceAttacker", attacker);
	if (StrEqual(name, "jockey_ride"))
	{
		SetEntityMoveType(attacker, MOVETYPE_ISOMETRIC);
	}
	
	return Plugin_Continue;
}

public Action:OnDisableProtection(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!GetConVarBool(ppEnable))
	{
		return Plugin_Continue;
	}
	
	new attacker = GetClientOfUserId(GetEventInt(event, "userid"));
	new victim = GetClientOfUserId(GetEventInt(event, "victim"));
	if (!attacker || !victim)
	{
		return Plugin_Continue;
	}
	
	g_ProtectPin[attacker] = 0;
	SetEntPropEnt(victim, Prop_Send, "m_pounceAttacker", -1);
	SetEntPropEnt(attacker, Prop_Send, "m_pounceVictim", -1);
	if (StrEqual(name, "jockey_ride_end"))
	{
		SetEntityMoveType(attacker, MOVETYPE_CUSTOM);
	}
	
	return Plugin_Continue;
}

public Action:OnProtectionCheck(Handle:event, const String:name[], bool:dontBroadcast)
{
	new bot = GetClientOfUserId(GetEventInt(event, "bot"));
	if (GetActualAttacker(bot) == 0)
	{
		return Plugin_Continue;
	}
	
	g_ProtectPin[GetActualAttacker(bot)] = 0;
	SetEntPropEnt(bot, Prop_Send, "m_pounceAttacker", -1);
	SetEntPropEnt(GetActualAttacker(bot), Prop_Send, "m_pounceVictim", -1);
	
	new player = GetClientOfUserId(GetEventInt(event, "player"));
	if (player <= 0 || !IsClientInGame(player) || IsFakeClient(player))
	{
		return Plugin_Continue;
	}
	
	if (GetActualAttacker(player) == 0)
	{
		return Plugin_Continue;
	}
	
	g_ProtectPin[GetActualAttacker(player)] = 0;
	SetEntPropEnt(player, Prop_Send, "m_pounceAttacker", -1);
	SetEntPropEnt(GetActualAttacker(player), Prop_Send, "m_pounceVictim", -1);
}

public Action:ProtectedDamageFix(victim, &attacker, &inflictor, &Float:damage, &damageType, &weapon, Float:damageForce[3], Float:damagePosition[3])
{
	if (!GetConVarBool(ppEnable))
	{
		return Plugin_Continue;
	}
	
	if (!IsSurvivor(victim) || !IsInfected(attacker) || GetEntProp(attacker, Prop_Send, "m_zombieClass") != 1)
	{
		return Plugin_Continue;
	}
	
	damage = (IsIncapacitated(victim)) ? GetConVarFloat(ppSmokerDamageIncap) : GetConVarFloat(ppSmokerDamage);
	return Plugin_Changed;
}

GetActualAttacker(victim)
{
	new attacker = 0;
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 3 && IsPlayerAlive(i) && g_ProtectPin[i] == victim) 
		{
			attacker = i;
			break;
		}
	}
	
	return attacker;
}

stock bool:IsSurvivor(client)
{
	return (client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2);
}

stock bool:IsIncapacitated(client)
{
	if (GetEntProp(client, Prop_Send, "m_isIncapacitated", 1))
	{
		return true;
	}
	
	return false;
}

stock bool:IsInfected(client)
{
	return (client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 3);
}

