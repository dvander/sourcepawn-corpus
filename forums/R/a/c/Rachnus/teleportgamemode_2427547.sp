#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "Rachnus"
#define PLUGIN_VERSION "1.00"

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#undef REQUIRE_EXTENSIONS
#include <cstrike>

#pragma newdecls required

//EngineVersion g_Game;

ConVar g_cvEnabled;
ConVar g_cvFriendlyFire;
ConVar g_cvHeadShotOnly;
ConVar g_cvAimLock;

public Plugin myinfo = 
{
	name = "Teleportgamemode",
	author = PLUGIN_AUTHOR,
	description = "Switches positions of the target you shoot",
	version = PLUGIN_VERSION,
	url = "http://rachnus.blogspot.fi/"
};

public void OnPluginStart()
{
	g_cvEnabled = CreateConVar("teleportgm_enabled", "1", "Turns the gamemode on or off (1 or 0)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cvFriendlyFire = CreateConVar("teleportgm_ff", "0", "Allows teleporting on shooting teammates (1 or 0)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cvHeadShotOnly = CreateConVar("teleportgm_headshot", "0", "Teleports only on headshot (1 or 0)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cvAimLock = CreateConVar("teleportgm_aimlock", "1", "Lock aim onto target after teleport (1 or 0)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
		}
	}
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	if(g_cvEnabled.IntValue == 1)
	{
		if((victim > 0 && victim <= MaxClients) && (attacker > 0 && attacker <= MaxClients))
		{
			if(IsClientInGame(attacker) && IsClientInGame(victim))
			{
				
				
				float attackerPos[3];
				float victimPos[3];
				
				float victimAimDir[3];
				float attackerAimDir[3];
				
				GetClientAbsAngles(victim, victimAimDir);
				GetClientAbsAngles(attacker, attackerAimDir);
				
				GetClientAbsOrigin(victim, victimPos);
				GetClientAbsOrigin(attacker, attackerPos);
				
				if(g_cvAimLock.IntValue == 1)
				{
					float attackerEyePos[3];
					float victimEyePos[3];
		
		
					GetClientEyePosition(attacker, attackerEyePos);
					GetClientEyePosition(victim, victimEyePos);
					
					MakeVectorFromPoints(attackerEyePos, victimPos, victimAimDir);
					MakeVectorFromPoints(victimEyePos, attackerPos, attackerAimDir);
					
					GetVectorAngles(victimAimDir, victimAimDir);
					GetVectorAngles(attackerAimDir, attackerAimDir);
				}
				if(g_cvHeadShotOnly.IntValue == 1)
				{
					if(g_cvFriendlyFire.IntValue == 0)
					{
						if(((damagetype & CS_DMG_HEADSHOT) || (damagetype & DMG_CRIT)) && (GetClientTeam(attacker) != GetClientTeam(victim)))
						{
							TeleportEntity(attacker, victimPos, attackerAimDir, NULL_VECTOR);
							TeleportEntity(victim, attackerPos, victimAimDir, NULL_VECTOR);
						}
					}
					else
					{
						if((damagetype & CS_DMG_HEADSHOT) || (damagetype & DMG_CRIT))
						{
							TeleportEntity(attacker, victimPos, attackerAimDir, NULL_VECTOR);
							TeleportEntity(victim, attackerPos, victimAimDir, NULL_VECTOR);
						}
					}
				}
				else
				{
					if(g_cvFriendlyFire.IntValue == 0)
					{
						if(GetClientTeam(attacker) != GetClientTeam(victim))
						{
							TeleportEntity(attacker, victimPos, attackerAimDir, NULL_VECTOR);
							TeleportEntity(victim, attackerPos, victimAimDir, NULL_VECTOR);
						}
					}
					else
					{
							TeleportEntity(attacker, victimPos, attackerAimDir, NULL_VECTOR);
							TeleportEntity(victim, attackerPos, victimAimDir, NULL_VECTOR);
					}
				}
			}
		}
	}
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public void OnClientDisconnect(int client)
{
	SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}