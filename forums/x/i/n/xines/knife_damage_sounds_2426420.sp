#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>

char zombieSounds[][] = {
	"zombies/brains_1.wav",
	"zombies/brains_2.wav",
	"zombies/brains_3.wav",
	"zombies/brains_4.wav"
};

public void OnMapStart()
{
	for(int i = 0; i < sizeof(zombieSounds); i++)
	{
		char fullPath[PLATFORM_MAX_PATH];
		Format(fullPath, sizeof(fullPath), "sound/%s", zombieSounds[i]);
		AddFileToDownloadsTable(fullPath);
		PrecacheSound(zombieSounds[i], true);
	}
}

public void OnClientPostAdminCheck(int client)
{
	SDKHook(client, SDKHook_OnTakeDamage, onTakeDamage);
}

public Action onTakeDamage(int client, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	if(!IsValidClient(attacker) || !IsValidClient(client)) return Plugin_Continue;
	
	char weapon[32];
	GetClientWeapon(attacker, weapon, sizeof(weapon));
	if(GetClientTeam(attacker) == CS_TEAM_T && GetClientTeam(client) == CS_TEAM_CT)
	{
		if(StrEqual(weapon, "weapon_knife", false))
		{
			EmitSoundToAll(zombieSounds[GetRandomInt(0,3)], attacker, SNDCHAN_AUTO, SNDLEVEL_SCREAMING);
		}
	}
	return Plugin_Continue;
}

public IsValidClient(int client) 
{ 
	if (!(1 <= client <= MaxClients ) || !IsClientInGame(client)) 
		return false; 
	
	return true; 
}