#include <sourcemod>
#include <sdkhooks>

#pragma semicolon 1
#pragma newdecls required

bool bLateLoad;
Handle hTempDecayRate;

public Plugin myinfo =
{
    name = "[L4D/L4D2] Damage Temp Before Full Health",
    author = "MasterMind420",
    description = "Damage Temp Health Before Full Health",
    version = "1.0",
    url = ""
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	bLateLoad = late;
	return APLRes_Success;
}

public void OnPluginStart()
{
	hTempDecayRate = FindConVar("pain_pills_decay_rate");

	if (bLateLoad)
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i))
				OnClientPutInServer(i);
		}
	}
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3])
{
	if (IsValidClient(victim) && IsClientInGame(victim) && GetClientTeam(victim) == 2 && IsPlayerAlive(victim) && !IsClientIncap(victim))
	{
		float fTempHealth = GetTempHealth(victim);

		if (fTempHealth > 0)
		{
			if (damage > fTempHealth)
			{
				SetEntPropFloat(victim, Prop_Send, "m_healthBuffer", 0.0);
				SetEntPropFloat(victim, Prop_Send, "m_healthBufferTime", GetGameTime());
				damage = damage - fTempHealth;
			}
			else
			{
				SetEntPropFloat(victim, Prop_Send, "m_healthBuffer", fTempHealth - damage);
				SetEntPropFloat(victim, Prop_Send, "m_healthBufferTime", GetGameTime());
				damage = 0.0;
			}

			return Plugin_Changed;
		}
	}

	return Plugin_Continue;
}

stock bool IsValidClient(int client)
{
	return (client > 0 && client <= MaxClients);
}

stock bool IsClientIncap(int client)
{
	return (GetEntProp(client, Prop_Send, "m_isIncapacitated", 1) && GetEntProp(client, Prop_Send, "m_isHangingFromLedge") != 1);
}

stock float GetTempHealth(int client)
{
	return (GetEntPropFloat(client, Prop_Send, "m_healthBuffer") - (GetGameTime() - GetEntPropFloat(client, Prop_Send, "m_healthBufferTime")) * GetConVarFloat(hTempDecayRate));
}