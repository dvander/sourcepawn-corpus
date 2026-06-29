#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>

#define L4D2 Infected Seppuku
#define PLUGIN_VERSION "1.0"

#define ZOMBIECLASS_SMOKER 1
#define ZOMBIECLASS_BOOMER 2
#define ZOMBIECLASS_HUNTER 3
#define ZOMBIECLASS_SPITTER 4
#define ZOMBIECLASS_JOCKEY 5
#define ZOMBIECLASS_CHARGER 6
#define ZOMBIECLASS_TANK 8

ConVar cvarInfectedSeppukuSmoker;
ConVar cvarInfectedSeppukuBoomer;
ConVar cvarInfectedSeppukuHunter;
ConVar cvarInfectedSeppukuSpitter;
ConVar cvarInfectedSeppukuJockey;
ConVar cvarInfectedSeppukuCharger;
ConVar cvarInfectedSeppukuTank;

bool isSeppukuSmoker = false;
bool isSeppukuBoomer = false;
bool isSeppukuHunter = false;
bool isSeppukuSpitter = false;
bool isSeppukuJockey = false;
bool isSeppukuCharger = false;
bool isSeppukuTank = false;

public Plugin myinfo = 
{
    name = "[L4D2] Infected Seppuku",
    author = "Mortiegama",
    description = "Allows for the infected team to honourably end their life to affect survivors.",
    version = PLUGIN_VERSION,
    url = "https://forums.alliedmods.net/showthread.php?p=2093029#post2093029"
}

	//Special Thanks:
	//ne0cha0s - Infected Self Detonate:
	//https://forums.alliedmods.net/showthread.php?t=122546
	//This was the original plugin that has since been unapproved.
	
public void OnPluginStart()
{
	CreateConVar("l4d_seppuku_version", PLUGIN_VERSION, "Infected Seppuku Version", FCVAR_NONE|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	cvarInfectedSeppukuSmoker = CreateConVar("l4d_seppuku_smoker", "1", "Enables seppuku for the Smoker. (Def 1)", FCVAR_NONE, true, 0.0, false, _);
	cvarInfectedSeppukuBoomer = CreateConVar("l4d_seppuku_boomer", "1", "Enables seppuku for the Boomer. (Def 1)", FCVAR_NONE, true, 0.0, false, _);
	cvarInfectedSeppukuHunter = CreateConVar("l4d_seppuku_hunter", "1", "Enables seppuku for the Hunter. (Def 0)", FCVAR_NONE, true, 0.0, false, _);
	cvarInfectedSeppukuSpitter = CreateConVar("l4d_seppuku_spitter", "1", "Enables seppuku for the Spitter. (Def 1)", FCVAR_NONE, true, 0.0, false, _);
	cvarInfectedSeppukuJockey = CreateConVar("l4d_seppuku_jockey", "1", "Enables seppuku for the Jockey. (Def 0)", FCVAR_NONE, true, 0.0, false, _);
	cvarInfectedSeppukuCharger = CreateConVar("l4d_seppuku_charger", "1", "Enables seppuku for the Charger. (Def 0)", FCVAR_NONE, true, 0.0, false, _);
	cvarInfectedSeppukuTank = CreateConVar("l4d_seppuku_tank", "0", "Enables seppuku for the Tank. (Def 0)", FCVAR_NONE, true, 0.0, false, _);
	
	if (GetConVarInt(cvarInfectedSeppukuSmoker))
	{
		isSeppukuSmoker = true;
	}
	
	if (GetConVarInt(cvarInfectedSeppukuBoomer))
	{
		isSeppukuBoomer = true;
	}
	
	if (GetConVarInt(cvarInfectedSeppukuHunter))
	{
		isSeppukuHunter = true;
	}
	
	if (GetConVarInt(cvarInfectedSeppukuSpitter))
	{
		isSeppukuSpitter = true;
	}
	
	if (GetConVarInt(cvarInfectedSeppukuJockey))
	{
		isSeppukuJockey = true;
	}
	
	if (GetConVarInt(cvarInfectedSeppukuCharger))
	{
		isSeppukuCharger = true;
	}
	
	if (GetConVarInt(cvarInfectedSeppukuTank))
	{
		isSeppukuTank = true;
	}
	
	AutoExecConfig(true, "plugin.L4D2.InfectedSeppuku");
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	if(IsValidClient(client) && (buttons & IN_ZOOM))
	{
		int class = GetEntProp(client, Prop_Send, "m_zombieClass");
		switch (class)  
		{	
			case ZOMBIECLASS_BOOMER:
			{
				if(isSeppukuBoomer)
				{
					SetEntProp(client, Prop_Send, "m_iHealth", 1, true);
					IgniteEntity(client, 2.0);
				}
			}
			case ZOMBIECLASS_CHARGER:
			{
				if(isSeppukuCharger)
				{
					SetEntProp(client, Prop_Send, "m_iHealth", 1, true);
					IgniteEntity(client, 2.0);
				}
			}
			case ZOMBIECLASS_JOCKEY:
			{
				if(isSeppukuJockey)
				{
					SetEntProp(client, Prop_Send, "m_iHealth", 1, true);
					IgniteEntity(client, 2.0);
				}
			}
			case ZOMBIECLASS_HUNTER:
			{
				if(isSeppukuHunter)
				{
					SetEntProp(client, Prop_Send, "m_iHealth", 1, true);
					IgniteEntity(client, 2.0);
				}
			}
			case ZOMBIECLASS_SMOKER:
			{
				if(isSeppukuSmoker)
				{
					SetEntProp(client, Prop_Send, "m_iHealth", 1, true);
					IgniteEntity(client, 2.0);
				}
			}
			case ZOMBIECLASS_SPITTER:
			{
				if(isSeppukuSpitter)
				{
					SetEntProp(client, Prop_Send, "m_iHealth", 1, true);
					IgniteEntity(client, 2.0);
				}
			}
			case ZOMBIECLASS_TANK:
			{
				if(isSeppukuTank)
				{
					SetEntProp(client, Prop_Send, "m_iHealth", 1, true);
					IgniteEntity(client, 2.0);
				}
			}
		}
	}
}

public int IsValidClient(int client)
{
	if (client <= 0)
		return false;
		
	if (client > MaxClients)
		return false;

	if (!IsClientInGame(client))
		return false;
		
	if (GetClientTeam(client) != 3)
		return false;
		
	if (!IsPlayerAlive(client))
		return false;
		
	if (IsPlayerAGhost(client))
		return false;

	return true;
}

public int IsPlayerAGhost(int client)
{
	if (GetEntProp(client, Prop_Send, "m_isGhost")) 
		return true;
	return false;
}