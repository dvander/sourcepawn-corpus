#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.06"

int IsInfectedOffset = -1;
ConVar InfProt;
ConVar SlapZom;
ConVar AllowCarrier;
bool LastMan = false;

public Plugin myinfo = 
{
	name = "ZPS Infection Protection",
	author = "Will2Tango",
	description = "ZPS Protection for Infected Survivors",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
}

public void OnPluginStart()
{
	CreateConVar("sm_infection_protection_ver", PLUGIN_VERSION, "ZPS Infection Protection", FCVAR_NOTIFY|FCVAR_SPONLY|FCVAR_DONTRECORD);	
	InfProt = CreateConVar("sm_infection_protection", "10", "Infected Survivor Protection Time in Seconds. (default=10, 0=disabled)", FCVAR_NOTIFY, true, 0.0);
	SlapZom = CreateConVar("sm_infection_protection_punishment", "50", "Punish Bad Zombies with a Slap for trying to kill Infected Survivors, set damage. (default=50, 0=disabled)", FCVAR_NOTIFY, true, 0.0);
	AllowCarrier = CreateConVar("sm_infection_protection_carrier", "1", "Allow Carrier to Kill Infected Survivors. (1=Yes 0=No)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	IsInfectedOffset = FindSendPropInfo("CHL2MP_Player", "m_IsInfected");	//Thank you Sammy-ROCK (Pills Cure)
	HookEvent("player_hurt", PlayerHurt);
	HookEvent("player_death", PlayerDeath);
	HookEvent("game_round_restart", NewRound);
}

public Action PlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));		//Thank you Mike + R_Hehl (eloStats)
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	float iptime = GetConVarFloat(InfProt);

	if(iptime > 0 && LastMan == false && attacker > 0 && !IsFakeClient(attacker))
	{
		if(GetClientTeam(attacker) == 3 && GetEntData(client, IsInfectedOffset))
		{
			int ProValue = GetEntProp(client, Prop_Data, "m_takedamage", 1);
			int attHP = GetEntProp(attacker, Prop_Data, "m_iHealth", 1);
			int SlapDamage = GetConVarInt(SlapZom);

			if (GetConVarBool(AllowCarrier))	//Is Carrier
			{
				char attWeapon[32];
				GetClientWeapon(attacker, attWeapon, sizeof(attWeapon));
				if (StrEqual("weapon_carrierarms",attWeapon))
				{
					if (ProValue == 1)
					{
						SetEntProp(client, Prop_Data, "m_takedamage", 2, 1);
					}
				}
				else							//Not Carrier
				{
					PrintToChat(attacker, "\x01[Infection Protection] \x04Bad Zombie!\x01 dont kill infected.");	//Shout at Zombie
					if (SlapDamage > 0 && attHP > SlapDamage) { SlapPlayer(attacker, SlapDamage, true); }				//Slap Bad Zombie
					if(ProValue != 1)
					{
						CreateTimer(iptime,Unprotect,client);
						SetEntProp(client, Prop_Data, "m_takedamage", 1, 1);
					}
				}
			}
			else
			{
				if(ProValue != 1)	//Not Protected
				{
					CreateTimer(iptime,Unprotect,client);
					SetEntProp(client, Prop_Data, "m_takedamage", 1, 1);
					PrintToChat(attacker, "Hes \x04Infected\x01, dont kill him!");
				}
				else				//Already Protected
				{
					PrintToChat(attacker, "\x01[Infection Protection] \x04Bad Zombie!\x01 dont kill infected.");	//Shout at Zombie	
					if (SlapDamage > 0 && attHP > SlapDamage) {SlapPlayer(attacker, SlapDamage, true);}				//Slap Bad Zombie
				}
			}
		}
	}
}

public Action Unprotect(Handle timer, any client)	//Thank you X@IDER (Advanced Commands)
{
	if (IsClientInGame(client) && IsPlayerAlive(client))
	{
		SetEntProp(client, Prop_Data, "m_takedamage", 2, 1);
	}
	return Plugin_Stop;
}

public void PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int iptime = GetConVarInt(InfProt);
	if(iptime > 0 && LastMan == false )
	{
		int lastManId = 0;

		//Lets count the survivors //Thanks to Ferret (Last Man Standing)
		for (int i = 1; i < MaxClients; i++)
		if(IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
		{
			if(lastManId)
			{
				lastManId = -1;
			}
			else
			{
				lastManId = i;
			}
		}
		if(lastManId > 0)
		{
			CreateTimer(0.0, Unprotect, lastManId);
			LastMan = true;
		}
	}
}

public void NewRound(Event event, const char[] name, bool dontBroadcast)
{
	LastMan = false;
}
