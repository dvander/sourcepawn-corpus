#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <left4dhooks>

#define CVAR_FLAGS FCVAR_NOTIFY
#define PLUGIN_VERSION "1.0"

ConVar g_hWhichSafe, g_hWhichTeam;

public Plugin myinfo =
{
	name = "[L4D1 & L4D2] Block FF Inside Safe Room",
	author = "KadabraZz",
	description = "Blocks FF inside the starting and ending safe room.",
	version = "PLUGIN_VERSION",
	url = "https://forums.alliedmods.net/showthread.php?p=2826306"
}

public void OnPluginStart()
{
	g_hWhichSafe = CreateConVar("l4d_ffsaferoom", "3", "0 = Disabled \n1 = First Safe room\n2 = Second Safe room\n3 = Both Safe room", CVAR_FLAGS, true, 0.0, true, 3.0);
	g_hWhichTeam = CreateConVar("l4d_ffsaferoom_team", "1", "1 = Both teams\n2 = Survivor team\n3 = Infected team", CVAR_FLAGS, true, 1.0, true, 3.0);
	CreateConVar("l4d_ffsaferoom_version",	PLUGIN_VERSION,	"FF Safe room version.",	CVAR_FLAGS|FCVAR_SPONLY|FCVAR_DONTRECORD);
	AutoExecConfig(true, "l4d_BlockSafeRoomFF");
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	if (IsValidClient(victim) && IsValidClient(attacker) && IsValidEntity(inflictor))
	{
		if (attacker != victim)
		{
			int attackerTeam = GetClientTeam(attacker);
			int victimTeam = GetClientTeam(victim);
			int saferoomvalue = g_hWhichSafe.IntValue;
			int saferoomteamvalue = g_hWhichTeam.IntValue;
			bool isAttackerInSafeRoom = (L4D_IsInFirstCheckpoint(attacker) || L4D_IsInLastCheckpoint(attacker));
			bool isVictimInSafeRoom = (L4D_IsInFirstCheckpoint(victim) || L4D_IsInLastCheckpoint(victim));
		
			switch (saferoomteamvalue)
			{
				case 1: //Both Teams
				{
					if ((attackerTeam == 2 && victimTeam == 2) || (attackerTeam == 3 && victimTeam == 3))
					{
						if (saferoomvalue == 1 && (L4D_IsInFirstCheckpoint(attacker) || L4D_IsInFirstCheckpoint(victim)))
						{
							damage = 0.0; //Infected team needs that maybe only tank idk
							return Plugin_Handled;
						}
						if (saferoomvalue == 2 && (L4D_IsInLastCheckpoint(attacker) || L4D_IsInLastCheckpoint(victim)))
						{
							damage = 0.0;
							return Plugin_Handled;
						}
						if (saferoomvalue == 3 && (isAttackerInSafeRoom || isVictimInSafeRoom))
						{
							damage = 0.0;
							return Plugin_Handled;
						}
					}
				}
				case 2: //Survivor Team
				{
					if ((attackerTeam == 2 && victimTeam == 2))
					{
						if (saferoomvalue == 1 && (L4D_IsInFirstCheckpoint(attacker) || L4D_IsInFirstCheckpoint(victim)))
						{
							damage = 0.0;
							return Plugin_Handled;
						}
						else if (saferoomvalue == 2 && (L4D_IsInLastCheckpoint(attacker) || L4D_IsInLastCheckpoint(victim)))
						{
							damage = 0.0;
							return Plugin_Handled;
						}
						else if (saferoomvalue == 3 && (isAttackerInSafeRoom || isVictimInSafeRoom))
						{
							damage = 0.0;
							return Plugin_Handled;
						}
					}
				}
				case 3: //Infected Team
				{
					if ((attackerTeam == 3 && victimTeam == 3))
					{
						if (saferoomvalue == 1 && (L4D_IsInFirstCheckpoint(attacker) || L4D_IsInFirstCheckpoint(victim)))
						{
							damage = 0.0;
							return Plugin_Handled;
						}
						else if (saferoomvalue == 2 && (L4D_IsInLastCheckpoint(attacker) || L4D_IsInLastCheckpoint(victim)))
						{
							damage = 0.0;
							return Plugin_Handled;
						}
						else if (saferoomvalue == 3 && (isAttackerInSafeRoom || isVictimInSafeRoom))
						{
							damage = 0.0;
							return Plugin_Handled;
						}
					}
				}
			}
		}
	}
	return Plugin_Continue;
}

bool IsValidClient(int client)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client) && IsPlayerAlive(client);
}
