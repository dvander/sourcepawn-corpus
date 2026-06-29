#pragma semicolon 1
#include <sourcemod>
#include <sdkhooks>

#define PLUGIN_VERSION "3.0"

ConVar l4d_nff;
bool b_l4d_nff;

public Plugin myinfo =
{
	name = "[L4D & L4D2] No Friendly Fire",
	author = "Psykotik and cravenge",
	description = "Disables friendly fire.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=302822"
}

public void OnPluginStart()
{
	CreateConVar("l4d_nff_version", PLUGIN_VERSION, "Version of the plugin.", FCVAR_SPONLY|FCVAR_DONTRECORD);
	
	l4d_nff = CreateConVar("l4d_nff", "0", "Friendly Fire status: 0 = Disabled, 1 = Enabled");
	b_l4d_nff = l4d_nff.BoolValue;
	l4d_nff.AddChangeHook(OnNFFCVarChanged);
	
	AutoExecConfig(true, "l4d_nofriendlyfire");
}

public void OnNFFCVarChanged(ConVar cvar, const char[] sOldValue, const char[] sNewValue)
{
	b_l4d_nff = l4d_nff.BoolValue;
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if (b_l4d_nff || entity <= 0 || entity > 2048)
	{
		return;
	}
	
	if (StrContains(classname, "prop_fuel_barrel", false) > 0)
	{
		HookSingleEntityOutput(entity, "OnBreak", OnExplosiveBarrelExplosion);
	}
}

public void OnExplosiveBarrelExplosion(const char[] output, int caller, int activator, float delay)
{
	if (b_l4d_nff)
	{
		return;
	}
	
	if (IsSurvivor(activator) || (activator != 0 && (!IsClientInGame(activator) || GetClientTeam(activator) != 2)))
	{
		ModifyConVar(activator, "god", "1");
		CreateTimer(0.25, RevertChanges, GetClientUserId(activator));
	}
}

public Action RevertChanges(Handle timer, any userid)
{
	int client = GetClientOfUserId(userid);
	if (IsSurvivor(client) || (client != 0 && (!IsClientInGame(client) || GetClientTeam(client) != 2)))
	{
		return Plugin_Stop;
	}
	
	ModifyConVar(client, "god", "0");
	return Plugin_Stop;
}

public void OnEntityDestroyed(int entity)
{
	if (b_l4d_nff || entity <= 0 || entity > 2048 || !IsValidEdict(entity))
	{
		return;
	}
	
	char sEntityClass[64];
	GetEdictClassname(entity, sEntityClass, sizeof(sEntityClass));
	if (StrContains(sEntityClass, "prop_fuel_barrel", false) <= 0)
	{
		return;
	}
	
	UnhookSingleEntityOutput(entity, "OnBreak", OnExplosiveBarrelExplosion);
}

public void OnClientPostAdminCheck(int client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public void OnClientDisconnect(int client)
{
	SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3])
{
	if (!b_l4d_nff)
	{
		if (IsSurvivor(victim) && IsSurvivor(attacker))
		{
			damage = 0.0;
			return Plugin_Changed;
		}
		else if (damagetype == 8 || damagetype == 2056 || damagetype == 268435464)
		{
			if ((IsSurvivor(victim) && IsSurvivor(attacker)) || (attacker != 0 && (!IsClientInGame(attacker) || GetClientTeam(attacker) != 2)))
			{
				damage = 0.0;
				return Plugin_Changed;
			}
		}
		else if (IsValidEnt(inflictor))
		{
			char sInflictorClass[64];
			GetEdictClassname(inflictor, sInflictorClass, sizeof(sInflictorClass));
			if (StrContains(sInflictorClass, "prop_fuel_barrel", false) > 0 && (IsSurvivor(attacker) || (attacker != 0 && (!IsClientInGame(attacker) || GetClientTeam(attacker) != 2))))
			{
				damage = 0.0;
				return Plugin_Changed;
			}
		}
	}

	return Plugin_Continue;
}

void ModifyConVar(int client, char[] sConVar, char[] sValue)
{
	if (FindConVar(sConVar) == null)
	{
		return;
	}
	
	int iFlags = FindConVar(sConVar).Flags;
	FindConVar(sConVar).Flags = iFlags & ~FCVAR_CHEAT;
	FakeClientCommand(client, "%s %s", sConVar, sValue);
	FindConVar(sConVar).Flags = iFlags;
}

stock bool IsSurvivor(int client)
{
	return (client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2);
}

stock bool IsValidEnt(int entity)
{
	return (entity > 0 && IsValidEntity(entity) && IsValidEdict(entity));
}