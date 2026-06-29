#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <left4dhooks>

#define PLUGIN_VERSION "1.0"
#define PLUGIN_NAME "L4D2 Witch Fire Fix"
#define CVAR_FLAGS FCVAR_NOTIFY|FCVAR_SPONLY

ConVar g_cvarEnable, g_cvarDebug;
bool g_bEnabled = false, g_bDebug = false, g_witchRespawnFlag = false;
int g_witchRespawnHP = 0;
float g_witchRespawnPos[3] = {0.0, ...};

public Plugin myinfo = 
{
	name = PLUGIN_NAME,
	author = "dcx2",
	description = "Fixes the Witch so she loses her target if she lights herself on fire",
	version = PLUGIN_VERSION,
	url = "www.AlliedMods.net"
}

public void OnPluginStart()
{
	CreateConVar("sm_witchfirefix_version", PLUGIN_VERSION, "Witch Fire Fix", CVAR_FLAGS|FCVAR_DONTRECORD);
	g_cvarEnable = CreateConVar("sm_witchfirefix_enable", "1.0", "Enables this plugin.", CVAR_FLAGS);
	g_cvarDebug = CreateConVar("sm_witchfirefix_debug", "0.0", "Print debug output.", CVAR_FLAGS);

	g_cvarEnable.AddChangeHook(OnConVarsChanged);
	g_cvarDebug.AddChangeHook(OnConVarsChanged);

	AutoExecConfig(true, "l4d2_witchfirefix");
	g_witchRespawnFlag = false;
}

public void OnConfigsExecuted()
{
	GetCvars();
}

void OnConVarsChanged(ConVar cvar, const char[] sOldValue, const char[] sNewValue)
{
	GetCvars();
}

void GetCvars()
{
	g_bEnabled = g_cvarEnable.BoolValue;
	g_bDebug = g_cvarDebug.BoolValue;
}

public void L4D_OnSpawnWitch_Post(int entity, const float vecPos[3], const float vecAng[3])
{
	if (g_bEnabled && IsValidWitch(entity) && IsServerProcessing())
	{
		if(g_witchRespawnFlag)
		{
			// Then restore her previous HP and position
			SetEntProp(entity, Prop_Data, "m_iHealth", g_witchRespawnHP);
			if (g_bDebug) PrintToChatAll("Witch %d (hp: %d, pos: %f, %f, %f) respawned", entity, g_witchRespawnHP, vecPos[0], vecPos[1], vecPos[2]);

			// Finally, reset all the respawn fields
			g_witchRespawnFlag = false;
			g_witchRespawnHP = 1000;
		}
		else
		{
			// Listen for this witch to take fire damage
			SDKHook(entity, SDKHook_OnTakeDamage, WitchOnTakeDamage);
			if (g_bDebug) PrintToChatAll("Hooking witch %d", entity);
		}
	}
}

Action WitchOnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3])
{
	if(g_bEnabled && IsValidWitch(victim))
	{
		bool playerIgnited = (attacker > 0 && attacker < MaxClients);
		if (g_bDebug)
		{
			char attackerName[MAX_NAME_LENGTH];
			if (playerIgnited) GetClientName(attacker, attackerName, sizeof(attackerName));
			else GetEntityClassname(attacker, attackerName, sizeof(attackerName));
			PrintToChatAll("Witch (%d) took %f damage (%x type) from %s (%d)", victim, damage, damagetype, attackerName, attacker);
		}

		if (damagetype & DMG_BURN)	
		{		
			// Once a witch has been hit with burning damage, unhook her, because she can only ignite once
			SDKUnhook(victim, SDKHook_OnTakeDamage, WitchOnTakeDamage);

			if (!playerIgnited)
			{
				// The witch should lose her target
				// So we will kill her and respawn a copy of her in the same place
				g_witchRespawnHP = GetEntProp(victim, Prop_Data, "m_iHealth");
				GetEntPropVector(victim, Prop_Send, "m_vecOrigin", g_witchRespawnPos);
				AcceptEntityInput(victim, "kill");
				g_witchRespawnFlag = true;
				if (g_bDebug) PrintToChatAll("Witch (%d) (hp: %d, pos: %f, %f, %f) self-ignited", victim, g_witchRespawnHP, g_witchRespawnPos[0], g_witchRespawnPos[1], g_witchRespawnPos[2]);
				L4D2_SpawnWitch(g_witchRespawnPos, NULL_VECTOR); // Respawn her (continue in Event_Witch_Spawn)
				g_witchRespawnPos[0] = 0.0;
				g_witchRespawnPos[1] = 0.0;
				g_witchRespawnPos[2] = 0.0;				
			}
			else if (g_bDebug)
			{
				PrintToChatAll("Witch (%d) burned, unhooking", victim);
			}
		}
	}
	return Plugin_Continue;
}

bool IsValidWitch(int witch)
{
	if(witch > 32 && witch <= 2048 && IsValidEdict(witch) && IsValidEntity(witch))
	{
		char classname[32];
		GetEdictClassname(witch, classname, sizeof(classname));
		if(StrEqual(classname, "witch")) return true;
	}
	return false;
}
