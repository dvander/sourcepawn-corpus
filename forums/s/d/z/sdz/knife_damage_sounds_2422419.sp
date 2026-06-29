#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>

new String:zombieSounds[][] = {
	"sound/zombies/brains_1.wav",
	"sound/zombies/brains_2.wav",
	"sound/zombies/brains_3.wav",
	"sound/zombies/brains_4.wav"
};

new zombieSoundsIndex[4];

public OnMapStart()
{
	zombieSoundsIndex[0] = PrecacheSound("zombies/brains_1.wav", true);
	zombieSoundsIndex[1] = PrecacheSound("zombies/brains_2.wav", true);
	zombieSoundsIndex[2] = PrecacheSound("zombies/brains_3.wav", true);
	zombieSoundsIndex[3] = PrecacheSound("zombies/brains_4.wav", true);

	for(new i = 0; i < sizeof(zombieSounds); i++)
	{
		AddFileToDownloadsTable(zombieSounds[i]);
	}
}

public OnClientPostAdminCheck(client)
{
	SDKHook(client, SDKHook_OnTakeDamage, onTakeDamage);
}

public Action:onTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
	if(victim > 0 && victim <= MaxClients && victim != attacker && attacker > 0 && attacker <= MaxClients)
	{
		decl String:weapon[32];
		GetClientWeapon(attacker, weapon, sizeof(weapon));

		if(GetClientTeam(attacker) == CS_TEAM_T)
		{
			if(GetClientTeam(victim) == CS_TEAM_CT)
			{
				if(StrEqual(weapon, "weapon_knife", false))
				{
					new modnar = GetRandomInt(0, 3);
					EmitSoundToAll(zombieSounds[modnar], attacker, SNDCHAN_AUTO, SNDLEVEL_SCREAMING);
					return Plugin_Continue;
				}
			}
		}
	}
}