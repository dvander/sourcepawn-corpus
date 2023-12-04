#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>
#pragma semicolon 1
#pragma newdecls required

#define Check_Jogadores(%1) for(int %1 = 1;%1 <= MaxClients;%1++) if(IsValidClient(%1))

bool Registar[MAXPLAYERS + 1] = { false, ... };

public void OnPluginStart()
{
	HookEvent("player_hurt", Hitar, EventHookMode_Pre);
	AddTempEntHook("Blood Sprite", TE_OnWorldDecal);
	AddTempEntHook("Entity Decal", TE_OnWorldDecal);
	AddTempEntHook("EffectDispatch", TE_OnEffectDispatch);
	AddTempEntHook("World Decal", TE_OnWorldDecal);
	AddTempEntHook("Impact", TE_OnWorldDecal);
}
public void OnClientPutInServer(int client) {
	SDKHook(client, SDKHook_OnTakeDamage, EventSDK_OnTakeDamage);
	SDKHook(client, SDKHook_TraceAttack, OnTraceAttack);
}
public Action EventSDK_OnTakeDamage(int Vitima, int &Atacante, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3])
{
	if (IsValidClient(Vitima))
	{
		if (IsValidClient(Atacante))
		{
			if (inflictor > MaxClients)
			{
				char inflictorClass[64];
				GetEdictClassname(inflictor, inflictorClass, sizeof(inflictorClass));
				
				if (StrEqual(inflictorClass, "planted_c4") || StrEqual(inflictorClass, "inferno"))
				{
					return Plugin_Continue;
				}
			}
			if (GetClientTeam(Atacante) == GetClientTeam(Vitima))
			{
				
				Registar[Atacante] = true;
				Registar[Vitima] = true;
				return Plugin_Stop;
			}
			else
			{
				Registar[Atacante] = false;
				Registar[Vitima] = false;
				return Plugin_Continue;
			}
			
		}
	}
	return Plugin_Changed;
}
public Action OnTraceAttack(int Vitima, int &Atacante, int &inflictor, float &damage, int &damagetype, int &ammotype, int hitbox, int hitgroup) {
	
	if (IsValidClient(Vitima))
	{
		if (IsValidClient(Atacante))
		{
			if (GetClientTeam(Atacante) == GetClientTeam(Vitima))
			{
				Registar[Atacante] = true;
				Registar[Vitima] = true;
				return Plugin_Stop;
			}
			else
			{
				Registar[Atacante] = false;
				Registar[Vitima] = false;
			}
			
		}
	}
	
	return Plugin_Continue;
}

public void Hitar(Event event, const char[] name, bool dontbroadcast)
{
	int Vitima = GetClientOfUserId(event.GetInt("userid"));
	int Atacante = GetClientOfUserId(event.GetInt("attacker"));
	if (IsValidClient(Vitima))
	{
		if (IsValidClient(Atacante))
		{
			if (GetClientTeam(Atacante) == GetClientTeam(Vitima))
			{
				Registar[Atacante] = true;
				Registar[Vitima] = true;
			}
			else
			{
				Registar[Atacante] = false;
				Registar[Vitima] = false;
			}
			
		}
	}
}

public Action TE_OnEffectDispatch(const char[] te_name, const int[] Players, int numClients, float delay)
{
	int iEffectIndex = TE_ReadNum("m_iEffectName");
	int nHitBox = TE_ReadNum("m_nHitBox");
	char sEffectName[64];
	Check_Jogadores(cliente)
	{
		if (Registar[cliente])
		{
			GetEffectName(iEffectIndex, sEffectName, sizeof(sEffectName));
			
			if (StrEqual(sEffectName, "csblood") || StrEqual(sEffectName, "Impact") || StrContains(sEffectName, "blood") || StrContains(sEffectName, "Impact"))
			{
				return Plugin_Handled;
			}
			
			if (StrEqual(sEffectName, "ParticleEffect"))
			{
				char sParticleEffectName[64];
				GetParticleEffectName(nHitBox, sParticleEffectName, sizeof(sParticleEffectName));
				if (StrEqual(sParticleEffectName, "impact_helmet_headshot") || StrContains(sEffectName, "blood") || StrContains(sEffectName, "Impact"))
				{
					return Plugin_Handled;
				}
			}
		}
	}
	return Plugin_Continue;
}

public Action TE_OnWorldDecal(const char[] te_name, const int[] Players, int numClients, float delay)
{
	
	float vecOrigin[3];
	int nIndex = TE_ReadNum("m_nIndex");
	char sDecalName[64];
	Check_Jogadores(cliente)
	{
		if (Registar[cliente])
		{
			TE_ReadVector("m_vecOrigin", vecOrigin);
			GetDecalName(nIndex, sDecalName, sizeof(sDecalName));
			
			if (StrContains(sDecalName, "decals/blood") == 0 && StrContains(sDecalName, "_subrect") != -1 || StrContains(sDecalName, "blood") || StrContains(sDecalName, "Impact"))
			{
				return Plugin_Handled;
			}
		}
	}
	return Plugin_Continue;
}

stock int GetParticleEffectName(int index, char[] sEffectName, int maxlen)
{
	int table = INVALID_STRING_TABLE;
	
	if (table == INVALID_STRING_TABLE)
	{
		table = FindStringTable("ParticleEffectNames");
	}
	
	return ReadStringTable(table, index, sEffectName, maxlen);
}

stock int GetEffectName(int index, char[] sEffectName, int maxlen)
{
	int table = INVALID_STRING_TABLE;
	
	if (table == INVALID_STRING_TABLE)
	{
		table = FindStringTable("EffectDispatch");
	}
	
	return ReadStringTable(table, index, sEffectName, maxlen);
}

stock int GetDecalName(int index, char[] sDecalName, int maxlen)
{
	int table = INVALID_STRING_TABLE;
	
	if (table == INVALID_STRING_TABLE)
	{
		table = FindStringTable("decalprecache");
	}
	
	return ReadStringTable(table, index, sDecalName, maxlen);
}


stock bool IsValidClient(int client, bool alive = false)
{
	if (0 < client && client <= MaxClients && IsClientInGame(client) && IsFakeClient(client) == false && (alive == false || IsPlayerAlive(client)))
	{
		return true;
	}
	return false;
} 