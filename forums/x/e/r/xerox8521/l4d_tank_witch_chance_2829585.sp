#include <sourcemod>
#include <left4dhooks>

#define PLUGIN_VERSION "1.0.0"

ConVar sm_tank_chance = null;
ConVar sm_witch_chance = null;

ConVar sm_boss_spawn_pos_min = null;
ConVar sm_boss_spawn_pos_max = null;

public Plugin myinfo = 
{
	name = "L4D Tank / Witch Chance modifier",
	author = "XeroX",
	description = "Modifiy the chance of tanks and witches",
	version = PLUGIN_VERSION,
	url = "https://soldiersofdemise.com"
};

public void OnPluginStart()
{
    sm_tank_chance = CreateConVar("sm_tank_chance", "0.75", "Chance of a tank spawning on the current map. (0-1)", FCVAR_NONE, true, 0.0, true, 1.0);
    sm_witch_chance = CreateConVar("sm_witch_chance", "0.5", "Chance of a witch spawning on the current map. (0-1)", FCVAR_NONE, true, 0.0, true, 1.0);
    sm_boss_spawn_pos_min = CreateConVar("sm_boss_spawn_pos_min", "0.10", "Minimum spawn position (percent of flow distance) for bosses. (0-1)", FCVAR_NONE, true, 0.0, true, 1.0);
    sm_boss_spawn_pos_max = CreateConVar("sm_boss_spawn_pos_max", "0.75", "Maximum spawn position (percent of flow distance) for bosses. (0-1)", FCVAR_NONE, true, 0.0, true, 1.0);

    AutoExecConfig();

}

public Action L4D_OnGetMissionVSBossSpawning(float &spawn_pos_min, float &spawn_pos_max, float &tank_chance, float &witch_chance)
{
    tank_chance = sm_tank_chance.FloatValue;
    witch_chance = sm_witch_chance.FloatValue;
    spawn_pos_min = sm_boss_spawn_pos_min.FloatValue;
    spawn_pos_max = sm_boss_spawn_pos_max.FloatValue;
    return Plugin_Continue;
}