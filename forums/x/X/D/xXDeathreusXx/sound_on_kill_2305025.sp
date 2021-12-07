#pragma semicolon 1

#include <sourcemod>
#include <freak_fortress_2>
#include <freak_fortress_2_subplugin>
#include <tf2_stocks>

public Plugin:myinfo=
{
	name        = "Freak Fortress 2: Sound On Kill",
	author      = "Deathreus",
	description = "Emits the sound to only the recipient",
	version     = "1.0",
};

#define MAX_SOUND_FILE_LENGTH 80
#define MAX_RAGE_SOUNDS 5

new String:g_sRageSound[MAX_RAGE_SOUNDS][MAX_SOUND_FILE_LENGTH];
new BossTeam=_:TFTeam_Blue;

public OnPluginStart2()
{
	HookEvent("player_death", event_player_death);
}

public Action:FF2_OnAbility2(client, const String:plugin_name[], const String:ability_name[], status)
{
	// Will do nothing, but compiler needs it
	return Plugin_Continue;
}

public Action:event_player_death(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetEventInt(event, "death_flags") & TF_DEATHFLAG_DEADRINGER)
		return Plugin_Continue;
	new attacker = GetClientOfUserId(GetEventInt(event,"attacker"));
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	new a_index = FF2_GetBossIndex(attacker);
	if(victim != -1)
	{
		if(FF2_HasAbility(a_index, this_plugin_name, "kill_sound"))
		{
			ReadSounds(a_index, "kill_sound", 1);
			if(GetClientTeam(victim) != BossTeam && IsValidClient(victim))
				EmitRandomClientSound(victim);
		}
	}
	return Plugin_Continue;
}

stock bool:IsValidClient(client)
{
	if(client <= 0
	|| client > MaxClients
	|| !IsClientInGame(client))
		return false;

	if(IsClientSourceTV(client)
	|| IsClientReplay(client))
		return false;

	return true;
}

ReadSounds(client, const String:abilityname[], arg)
{
	static String:readStr[(MAX_SOUND_FILE_LENGTH + 1) * MAX_RAGE_SOUNDS];
	FF2_GetAbilityArgumentString(client, this_plugin_name, abilityname, arg, readStr, sizeof(readStr));
	ExplodeString(readStr, ";", g_sRageSound, MAX_RAGE_SOUNDS, MAX_SOUND_FILE_LENGTH);
	for (new i = 0; i < MAX_RAGE_SOUNDS; i++)
		if (strlen(g_sRageSound[i]) > 3)
			PrecacheSound(g_sRageSound[i]);
}

EmitRandomClientSound(client)
{
	new count = 0;
	for (new i = 0; i < MAX_RAGE_SOUNDS; i++)
		if (strlen(g_sRageSound[i]) > 3)
			count++;
			
	if (count == 0)
		return;
		
	new rand = GetRandomInt(0, count-1);
	if (strlen(g_sRageSound[rand]) > 3)
	{
		EmitSoundToClient(client, g_sRageSound[rand]);
	}
}