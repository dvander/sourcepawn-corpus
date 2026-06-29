#include <sourcemod>
#include <sdkhooks>
#include <left4dhooks>

#define TEAM_SURVIVOR 2
ConVar 
survivor_incap_mult_easy, 
survivor_incap_mult_normal,
survivor_incap_mult_hard,
survivor_incap_mult_impossible;

public Plugin myinfo =
{
	name = "Extra incap cvars",
	author = "liquidplasma",
	description = "Adds multiple new cvars to change damage for incapped damage per difficulty",
	version = "1.0",
	url = ""
};

public int GetDifficultyIndex()
{
	int index;
	char cDifficulty[16];
	ConVar cvDifficulty = FindConVar("z_difficulty");
	cvDifficulty.GetString(cDifficulty, sizeof(cDifficulty));

	if (StrEqual(cDifficulty, "easy", true))
		index = 1;
	if (StrEqual(cDifficulty, "normal", true))
		index = 2;
	if (StrEqual(cDifficulty, "hard", true))
		index = 3;
	if (StrEqual(cDifficulty, "impossible", true))
		index = 4;

	return index;
}

bool IsValidClient(int iClient)
{
    if(iClient <= 0 || iClient > MaxClients || !IsClientInGame(iClient))
        return false;
    return true;
} 

public void OnPluginStart()
{
	survivor_incap_mult_easy = CreateConVar("survivor_incap_mult_easy", "1", "Damage multiplier for when a survivor is incapacitated on easy", FCVAR_NOTIFY, true, 0.0, true, 4096.0);
	survivor_incap_mult_normal = CreateConVar("survivor_incap_mult_normal", "1", "Damage multiplier for when a survivor is incapacitated on normal", FCVAR_NOTIFY, true, 0.0, true, 4096.0);
	survivor_incap_mult_hard = CreateConVar("survivor_incap_mult_hard", "1", "Damage multiplier for when a survivor is incapacitated on advanced", FCVAR_NOTIFY, true, 0.0, true, 4096.0);
	survivor_incap_mult_impossible = CreateConVar("survivor_incap_mult_impossible", "1", "Damage multiplier for when a survivor is incapacitated on expert", FCVAR_NOTIFY, true, 0.0, true, 4096.0);
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3])
{
	if (IsValidClient(inflictor) && IsValidClient(attacker) && IsClientInGame(victim) && GetClientTeam(victim) == TEAM_SURVIVOR && L4D_IsPlayerIncapacitated(victim))
	{			
        switch(GetDifficultyIndex())
		{
			case 1:
			{
				damage = damage * survivor_incap_mult_easy.FloatValue;
				return Plugin_Changed;
			}
			case 2:
			{
				damage = damage * survivor_incap_mult_normal.FloatValue;
				return Plugin_Changed;
			}
			case 3:
			{
				damage = damage * survivor_incap_mult_hard.FloatValue;
				return Plugin_Changed;
			}
			case 4:
			{
				damage = damage * survivor_incap_mult_impossible.FloatValue;
				return Plugin_Changed;
			}
		}
	}
	return Plugin_Continue;
}