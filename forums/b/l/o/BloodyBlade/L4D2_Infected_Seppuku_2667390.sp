#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

#define L4D2 Infected Seppuku
#define PLUGIN_VERSION "1.0"
#define CVAR_FLAGS FCVAR_NOTIFY|FCVAR_SPONLY

#define ZOMBIECLASS_SMOKER 1
#define ZOMBIECLASS_BOOMER 2
#define ZOMBIECLASS_HUNTER 3
#define ZOMBIECLASS_SPITTER 4
#define ZOMBIECLASS_JOCKEY 5
#define ZOMBIECLASS_CHARGER 6
#define ZOMBIECLASS_TANK 8

ConVar cvarInfectedSeppukuEnable, cvarInfectedSeppukuSmoker, cvarInfectedSeppukuBoomer, cvarInfectedSeppukuHunter, cvarInfectedSeppukuSpitter, cvarInfectedSeppukuJockey, cvarInfectedSeppukuCharger, cvarInfectedSeppukuTank;
bool isSeppukuEnable = false, isSeppukuSmoker = false, isSeppukuBoomer = false, isSeppukuHunter = false, isSeppukuSpitter = false, isSeppukuJockey = false, isSeppukuCharger = false, isSeppukuTank = false;

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
	CreateConVar("l4d_seppuku_version", PLUGIN_VERSION, "Infected Seppuku Version", CVAR_FLAGS|FCVAR_DONTRECORD);

	cvarInfectedSeppukuEnable = CreateConVar("l4d_seppuku_enable", "1", "Enables/Disable plugin. (Def 1)", CVAR_FLAGS, true, 0.0, true, 1.0);
	cvarInfectedSeppukuSmoker = CreateConVar("l4d_seppuku_smoker", "1", "Enables seppuku for the Smoker. (Def 1)", CVAR_FLAGS, true, 0.0, true, 1.0);
	cvarInfectedSeppukuBoomer = CreateConVar("l4d_seppuku_boomer", "1", "Enables seppuku for the Boomer. (Def 1)", CVAR_FLAGS, true, 0.0, true, 1.0);
	cvarInfectedSeppukuHunter = CreateConVar("l4d_seppuku_hunter", "1", "Enables seppuku for the Hunter. (Def 0)", CVAR_FLAGS, true, 0.0, true, 1.0);
	cvarInfectedSeppukuSpitter = CreateConVar("l4d_seppuku_spitter", "1", "Enables seppuku for the Spitter. (Def 1)", CVAR_FLAGS, true, 0.0, true, 1.0);
	cvarInfectedSeppukuJockey = CreateConVar("l4d_seppuku_jockey", "1", "Enables seppuku for the Jockey. (Def 0)", CVAR_FLAGS, true, 0.0, true, 1.0);
	cvarInfectedSeppukuCharger = CreateConVar("l4d_seppuku_charger", "1", "Enables seppuku for the Charger. (Def 0)", CVAR_FLAGS, true, 0.0, true, 1.0);
	cvarInfectedSeppukuTank = CreateConVar("l4d_seppuku_tank", "0", "Enables seppuku for the Tank. (Def 0)", CVAR_FLAGS, true, 0.0, true, 1.0);

	AutoExecConfig(true, "plugin.L4D2.InfectedSeppuku");

	cvarInfectedSeppukuEnable.AddChangeHook(OnConVarsChanged);
	cvarInfectedSeppukuSmoker.AddChangeHook(OnConVarsChanged);
	cvarInfectedSeppukuBoomer.AddChangeHook(OnConVarsChanged);
	cvarInfectedSeppukuHunter.AddChangeHook(OnConVarsChanged);
	cvarInfectedSeppukuSpitter.AddChangeHook(OnConVarsChanged);
	cvarInfectedSeppukuJockey.AddChangeHook(OnConVarsChanged);
	cvarInfectedSeppukuCharger.AddChangeHook(OnConVarsChanged);
	cvarInfectedSeppukuTank.AddChangeHook(OnConVarsChanged);
}

public void OnConfigsExecuted()
{
	OnConVarsChanged(null, "", "");
}

void OnConVarsChanged(ConVar cvar, const char[] OldValue, const char[] NewValue)
{
	isSeppukuEnable = cvarInfectedSeppukuEnable.BoolValue;
	isSeppukuSmoker = cvarInfectedSeppukuSmoker.BoolValue;
	isSeppukuBoomer = cvarInfectedSeppukuBoomer.BoolValue;
	isSeppukuHunter = cvarInfectedSeppukuHunter.BoolValue;
	isSeppukuSpitter = cvarInfectedSeppukuSpitter.BoolValue;
	isSeppukuJockey = cvarInfectedSeppukuJockey.BoolValue;
	isSeppukuCharger = cvarInfectedSeppukuCharger.BoolValue;
	isSeppukuTank = cvarInfectedSeppukuTank.BoolValue;
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	if(isSeppukuEnable && IsValidClient(client) && (buttons & IN_ZOOM))
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
	return Plugin_Continue;
}

stock bool IsValidClient(int client)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 3 && IsPlayerAlive(client) && !view_as<bool>(GetEntProp(client, Prop_Send, "m_isGhost"));
}
