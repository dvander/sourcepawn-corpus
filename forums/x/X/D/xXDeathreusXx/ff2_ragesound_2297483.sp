#pragma semicolon 1

#include <sourcemod>
#include <tf2_stocks>
#include <freak_fortress_2>
#include <freak_fortress_2_subplugin>

public Plugin:myinfo = {
	name	= "Freak Fortress 2: Server Wide Rage Sound",
	author	= "Deathreus",
	version = "1.1",
};

#define MAX_SOUND_FILE_LENGTH 80
#define MAX_RAGE_SOUNDS 5

new String:g_sRageSound[MAX_RAGE_SOUNDS][MAX_SOUND_FILE_LENGTH];
new BossTeam=_:TFTeam_Blue;

public OnPluginStart2()
{
	// Y u no let me compile without this
}

public Action:FF2_OnAbility2(client, const String:plugin_name[], const String:ability_name[], status)
{
	if (!strcmp(ability_name, "rage_sound"))
		Rage_Sound(client, ability_name);
	return Plugin_Continue;
}

Rage_Sound(client, const String:ability_name[])
{
	new Boss = GetClientOfUserId(FF2_GetBossUserId(client));
	ReadSounds(Boss, ability_name, 1);
	if(GetClientTeam(Boss) == BossTeam && IsValidClient(Boss))
		EmitRandomSound();
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

EmitRandomSound()
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
		EmitSoundToAll(g_sRageSound[rand]);
		EmitSoundToAll(g_sRageSound[rand]);
	}
}