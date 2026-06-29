#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.4"

public Plugin myinfo = 
{
	name = "[L4D] Difficulty Regulator",
	author = "chinagreenelvis, TANK Killer ТАНКИ™",
	description = "",
	version = PLUGIN_VERSION,
	url = ""
}

ConVar NSS_ad, z_difficulty;
bool bHooked = false;

public void OnPluginStart() 
{
	NSS_ad = CreateConVar("NSS_ad", "1", "Вкл/Выкл плагин", FCVAR_NOTIFY|FCVAR_SPONLY);

	z_difficulty = FindConVar("z_difficulty");
	NSS_ad.AddChangeHook(ConVarPluginOnChanged);

	AutoExecConfig(true, "NSS_autodiff4");
}

public void OnConfigsExecuted()
{
    IsAllowed();
}

void ConVarPluginOnChanged(ConVar cvar, const char[] OldValue, const char[] NewValue)
{
    IsAllowed();
}

void IsAllowed()
{
    bool bPluginOn = NSS_ad.BoolValue;
    if(bPluginOn && !bHooked)
    {
    	bHooked = true;
    	HookEvent("player_first_spawn", Event_PlayerSpawn);
    	HookEvent("player_spawn", Event_PlayerSpawn);
    	HookEvent("player_death", DifficultySet);
    	HookEvent("difficulty_changed", DifficultySet);
    	HookEvent("survivor_rescued", DifficultySet);
    	HookEvent("player_team", DifficultySet);
    }
    else if(!bPluginOn && bHooked)
    {
    	bHooked = false;
    	UnhookEvent("player_first_spawn", Event_PlayerSpawn);
    	UnhookEvent("player_spawn", Event_PlayerSpawn);
    	UnhookEvent("player_death", DifficultySet);
    	UnhookEvent("difficulty_changed", DifficultySet);
    	UnhookEvent("survivor_rescued", DifficultySet);
    	UnhookEvent("player_team", DifficultySet);
    }
}

Action Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (client > 0 && IsClientInGame(client) && !IsFakeClient(client) && GetClientTeam(client) == 2)
	{
		CreateTimer(5.0, Timer_DifficultySet);
	}
	return Plugin_Handled;
}

void DifficultySet(Event event, const char[] name, bool dontBroadcast)
{
	CreateTimer(5.0, Timer_DifficultySet);
}

Action Timer_DifficultySet(Handle timer)
{
	if (bHooked)
	{
		int alivesurvivors = 0;
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
			{
				alivesurvivors++;
			}
		}

		if (alivesurvivors > 0)
		{
			char sGameDifficulty[16];
			z_difficulty.GetString(sGameDifficulty, sizeof(sGameDifficulty));
			if (StrEqual(sGameDifficulty, "Easy", false))
			{
				SetDifficulty_Easy(alivesurvivors);
			}
			else if (StrEqual(sGameDifficulty, "Normal", false))
			{
				SetDifficulty_Normal(alivesurvivors);
			}
			else if (StrEqual(sGameDifficulty, "Hard", false))
			{
				SetDifficulty_Hard(alivesurvivors);
			}
			else if (StrEqual(sGameDifficulty, "Impossible", false))
			{
				SetDifficulty_Impossible(alivesurvivors);
			}
		}
	}
}

void SetDifficulty_Easy(int survivors)
{
	switch(survivors)
	{
    	case 1:
    	{
    		FindConVar("survivor_limp_health").SetInt(35);
    		FindConVar("first_aid_kit_use_duration").SetInt(4);
    		FindConVar("z_witch_health").SetInt(1050);
    		FindConVar("z_witch_burn_time").SetInt(15);
    		FindConVar("z_tank_speed").SetInt(211);
    		FindConVar("tongue_hit_delay").SetInt(20);
    		FindConVar("tongue_range").SetInt(800);
    		FindConVar("z_vomit_interval").SetInt(25);
    		FindConVar("director_force_background").SetInt(0);
    		FindConVar("z_background_limit").SetInt(26);
    		FindConVar("z_common_limit").SetInt(31);
    		FindConVar("z_mob_spawn_min_size").SetInt(10);
    		FindConVar("z_mob_spawn_finale_size").SetInt(20);
    		FindConVar("z_mob_spawn_max_size").SetInt(30);
    		FindConVar("z_mega_mob_size").SetInt(50);
    		FindConVar("z_mob_spawn_min_interval_easy").SetInt(70);
    		FindConVar("z_mob_spawn_max_interval_easy").SetInt(120);
    	}
    	case 2:
    	{
    		FindConVar("survivor_crawl_speed").SetInt(15);
    		FindConVar("survivor_revive_duration").SetInt(4);
    		FindConVar("survivor_revive_health").SetInt(41);
    		FindConVar("survivor_limp_health").SetInt(39);
    		FindConVar("first_aid_kit_use_duration").SetInt(4);
    		FindConVar("z_witch_health").SetInt(1100);
    		FindConVar("z_witch_burn_time").SetInt(16);
    		FindConVar("z_tank_speed").SetInt(212);
    		FindConVar("tongue_hit_delay").SetInt(18);
    		FindConVar("tongue_range").SetInt(950);
    		FindConVar("tongue_victim_max_speed").SetInt(180);
    		FindConVar("z_vomit_interval").SetInt(23);
    		FindConVar("director_force_background").SetInt(0);
    		FindConVar("z_background_limit").SetInt(27);
    		FindConVar("z_common_limit").SetInt(32);
    		FindConVar("z_mob_spawn_min_size").SetInt(12);
    		FindConVar("z_mob_spawn_finale_size").SetInt(24);
    		FindConVar("z_mob_spawn_max_size").SetInt(36);
    		FindConVar("z_mega_mob_size").SetInt(60);
    		FindConVar("z_mob_spawn_min_interval_easy").SetInt(70);
    		FindConVar("z_mob_spawn_max_interval_easy").SetInt(110);
    	}
    	case 3:
    	{
    		FindConVar("survivor_crawl_speed").SetInt(15);
    		FindConVar("survivor_revive_duration").SetInt(5);
    		FindConVar("survivor_revive_health").SetInt(43);
    		FindConVar("survivor_limp_health").SetInt(38);
    		FindConVar("first_aid_kit_use_duration").SetInt(5);
    		FindConVar("z_witch_health").SetInt(1150);
    		FindConVar("z_witch_burn_time").SetInt(17);
    		FindConVar("z_tank_speed").SetInt(213);
    		FindConVar("tongue_hit_delay").SetInt(17);
    		FindConVar("tongue_range").SetInt(1100);
    		FindConVar("tongue_victim_max_speed").SetInt(185);
    		FindConVar("z_vomit_interval").SetInt(22);
    		FindConVar("director_force_background").SetInt(0);
    		FindConVar("z_background_limit").SetInt(28);
    		FindConVar("z_common_limit").SetInt(33);
    		FindConVar("z_mob_spawn_min_size").SetInt(14);
    		FindConVar("z_mob_spawn_finale_size").SetInt(28);
    		FindConVar("z_mob_spawn_max_size").SetInt(42);
    		FindConVar("z_mega_mob_size").SetInt(70);
    		FindConVar("z_mob_spawn_min_interval_easy").SetInt(70);
    		FindConVar("z_mob_spawn_max_interval_easy").SetInt(100);
    	}
    	case 4:
    	{
    		FindConVar("survivor_crawl_speed").SetInt(20);
    		FindConVar("survivor_revive_duration").SetInt(5);
    		FindConVar("survivor_revive_health").SetInt(44);
    		FindConVar("survivor_limp_health").SetInt(37);
    		FindConVar("first_aid_kit_use_duration").SetInt(5);
    		FindConVar("z_witch_health").SetInt(1200);
    		FindConVar("z_witch_burn_time").SetInt(18);
    		FindConVar("z_tank_speed").SetInt(214);
    		FindConVar("tongue_hit_delay").SetInt(16);
    		FindConVar("tongue_range").SetInt(1250);
    		FindConVar("tongue_victim_max_speed").SetInt(190);
    		FindConVar("z_vomit_interval").SetInt(21);
    		FindConVar("director_force_background").SetInt(0);
    		FindConVar("z_background_limit").SetInt(29);
    		FindConVar("z_common_limit").SetInt(34);
    		FindConVar("z_mob_spawn_min_size").SetInt(16);
    		FindConVar("z_mob_spawn_finale_size").SetInt(32);
    		FindConVar("z_mob_spawn_max_size").SetInt(48);
    		FindConVar("z_mega_mob_size").SetInt(80);
    		FindConVar("z_mob_spawn_min_interval_easy").SetInt(70);
    		FindConVar("z_mob_spawn_max_interval_easy").SetInt(90);
    	}
    	case 5:
    	{
    		FindConVar("survivor_crawl_speed").SetInt(25);
    		FindConVar("survivor_revive_duration").SetInt(6);
    		FindConVar("survivor_revive_health").SetInt(45);
    		FindConVar("survivor_limp_health").SetInt(36);
    		FindConVar("first_aid_kit_use_duration").SetInt(6);
    		FindConVar("z_witch_health").SetInt(1250);
    		FindConVar("z_witch_burn_time").SetInt(19);
    		FindConVar("z_tank_speed").SetInt(215);
    		FindConVar("tongue_hit_delay").SetInt(15);
    		FindConVar("tongue_range").SetInt(1400);
    		FindConVar("tongue_victim_max_speed").SetInt(195);
    		FindConVar("z_vomit_interval").SetInt(20);
    		FindConVar("director_force_background").SetInt(0);
    		FindConVar("z_background_limit").SetInt(30);
    		FindConVar("z_common_limit").SetInt(35);
    		FindConVar("z_mob_spawn_min_size").SetInt(18);
    		FindConVar("z_mob_spawn_finale_size").SetInt(36);
    		FindConVar("z_mob_spawn_max_size").SetInt(54);
    		FindConVar("z_mega_mob_size").SetInt(90);
    		FindConVar("z_mob_spawn_min_interval_easy").SetInt(65);
    		FindConVar("z_mob_spawn_max_interval_easy").SetInt(90);
    	}
    	case 6:
    	{
    		FindConVar("survivor_crawl_speed").SetInt(30);
    		FindConVar("survivor_revive_duration").SetInt(6);
    		FindConVar("survivor_revive_health").SetInt(44);
    		FindConVar("survivor_limp_health").SetInt(35);
    		FindConVar("first_aid_kit_use_duration").SetInt(6);
    		FindConVar("z_witch_health").SetInt(1300);
    		FindConVar("z_witch_burn_time").SetInt(20);
    		FindConVar("z_tank_speed").SetInt(216);
    		FindConVar("tongue_hit_delay").SetInt(14);
    		FindConVar("tongue_range").SetInt(1550);
    		FindConVar("tongue_victim_max_speed").SetInt(195);
    		FindConVar("z_vomit_interval").SetInt(19);
    		FindConVar("director_force_background").SetInt(0);
    		FindConVar("z_background_limit").SetInt(31);
    		FindConVar("z_common_limit").SetInt(36);
    		FindConVar("z_mob_spawn_min_size").SetInt(20);
    		FindConVar("z_mob_spawn_finale_size").SetInt(40);
    		FindConVar("z_mob_spawn_max_size").SetInt(60);
    		FindConVar("z_mega_mob_size").SetInt(100);
    		FindConVar("z_mob_spawn_min_interval_easy").SetInt(65);
    		FindConVar("z_mob_spawn_max_interval_easy").SetInt(85);
    	}
    	case 7:
    	{
    		FindConVar("survivor_crawl_speed").SetInt(35);
    		FindConVar("survivor_revive_duration").SetInt(6);
    		FindConVar("survivor_revive_health").SetInt(43);
    		FindConVar("survivor_limp_health").SetInt(35);
    		FindConVar("first_aid_kit_use_duration").SetInt(6);
    		FindConVar("z_witch_health").SetInt(1350);
    		FindConVar("z_witch_burn_time").SetInt(21);
    		FindConVar("z_tank_speed").SetInt(217);
    		FindConVar("tongue_hit_delay").SetInt(13);
    		FindConVar("tongue_range").SetInt(1700);
    		FindConVar("tongue_victim_max_speed").SetInt(195);
    		FindConVar("z_vomit_interval").SetInt(18);
    		FindConVar("director_force_background").SetInt(0);
    		FindConVar("z_background_limit").SetInt(32);
    		FindConVar("z_common_limit").SetInt(37);
    		FindConVar("z_mob_spawn_min_size").SetInt(22);
    		FindConVar("z_mob_spawn_finale_size").SetInt(44);
    		FindConVar("z_mob_spawn_max_size").SetInt(66);
    		FindConVar("z_mega_mob_size").SetInt(110);
    		FindConVar("z_mob_spawn_min_interval_easy").SetInt(65);
    		FindConVar("z_mob_spawn_max_interval_easy").SetInt(85);
    	}
    	case 8:
    	{
    		FindConVar("survivor_crawl_speed").SetInt(40);
    		FindConVar("survivor_revive_duration").SetInt(6);
    		FindConVar("survivor_revive_health").SetInt(42);
    		FindConVar("survivor_limp_health").SetInt(35);
    		FindConVar("first_aid_kit_use_duration").SetInt(6);
    		FindConVar("z_witch_health").SetInt(1400);
    		FindConVar("z_witch_burn_time").SetInt(22);
    		FindConVar("z_tank_speed").SetInt(218);
    		FindConVar("tongue_hit_delay").SetInt(12);
    		FindConVar("tongue_range").SetInt(1850);
    		FindConVar("tongue_victim_max_speed").SetInt(195);
    		FindConVar("z_vomit_interval").SetInt(17);
    		FindConVar("director_force_background").SetInt(0);
    		FindConVar("z_background_limit").SetInt(33);
    		FindConVar("z_common_limit").SetInt(45);
    		FindConVar("z_mob_spawn_min_size").SetInt(24);
    		FindConVar("z_mob_spawn_finale_size").SetInt(48);
    		FindConVar("z_mob_spawn_max_size").SetInt(72);
    		FindConVar("z_mega_mob_size").SetInt(120);
    		FindConVar("z_mob_spawn_min_interval_easy").SetInt(60);
    		FindConVar("z_mob_spawn_max_interval_easy").SetInt(85);
    	}
    	case 9:
    	{
    		FindConVar("survivor_crawl_speed").SetInt(40);
    		FindConVar("survivor_revive_duration").SetInt(6);
    		FindConVar("survivor_revive_health").SetInt(41);
    		FindConVar("survivor_limp_health").SetInt(35);
    		FindConVar("first_aid_kit_use_duration").SetInt(6);
    		FindConVar("z_witch_health").SetInt(1450);
    		FindConVar("z_witch_burn_time").SetInt(23);
    		FindConVar("z_tank_speed").SetInt(219);
    		FindConVar("tongue_hit_delay").SetInt(11);
    		FindConVar("tongue_range").SetInt(2000);
    		FindConVar("tongue_victim_max_speed").SetInt(195);
    		FindConVar("z_vomit_interval").SetInt(16);
    		FindConVar("director_force_background").SetInt(0);
    		FindConVar("z_background_limit").SetInt(34);
    		FindConVar("z_common_limit").SetInt(39);
    		FindConVar("z_mob_spawn_min_size").SetInt(26);
    		FindConVar("z_mob_spawn_finale_size").SetInt(52);
    		FindConVar("z_mob_spawn_max_size").SetInt(78);
    		FindConVar("z_mega_mob_size").SetInt(130);
    		FindConVar("z_mob_spawn_min_interval_easy").SetInt(60);
    		FindConVar("z_mob_spawn_max_interval_easy").SetInt(85);
    	}
    	case 10:
    	{
    		FindConVar("survivor_crawl_speed").SetInt(40);
    		FindConVar("survivor_revive_duration").SetInt(7);
    		FindConVar("survivor_revive_health").SetInt(40);
    		FindConVar("survivor_limp_health").SetInt(35);
    		FindConVar("first_aid_kit_use_duration").SetInt(6);
    		FindConVar("z_witch_health").SetInt(1500);
    		FindConVar("z_witch_burn_time").SetInt(24);
    		FindConVar("z_tank_speed").SetInt(220);
    		FindConVar("tongue_hit_delay").SetInt(10);
    		FindConVar("tongue_range").SetInt(2500);
    		FindConVar("tongue_victim_max_speed").SetInt(195);
    		FindConVar("z_vomit_interval").SetInt(15);
    		FindConVar("director_force_background").SetInt(30);
    		FindConVar("z_background_limit").SetInt(5);
    		FindConVar("z_common_limit").SetInt(35);
    		FindConVar("z_mob_spawn_min_size").SetInt(28);
    		FindConVar("z_mob_spawn_finale_size").SetInt(56);
    		FindConVar("z_mob_spawn_max_size").SetInt(84);
    		FindConVar("z_mega_mob_size").SetInt(140);
    		FindConVar("z_mob_spawn_min_interval_easy").SetInt(60);
    		FindConVar("z_mob_spawn_max_interval_easy").SetInt(80);
    	}
	}
}

void SetDifficulty_Normal(int survivors)
{
	switch(survivors)
	{
    	case 1:
    	{
    		FindConVar("l4d_together_loner_punish").SetInt(0);
    		FindConVar("survivor_limp_health").SetInt(35);
    		FindConVar("first_aid_kit_use_duration").SetInt(4);
    		FindConVar("z_witch_health").SetInt(1050);
    		FindConVar("z_witch_burn_time").SetInt(15);
    		FindConVar("z_tank_speed").SetInt(211);
    		FindConVar("tongue_hit_delay").SetInt(20);
    		FindConVar("tongue_range").SetInt(800);
    		FindConVar("z_vomit_interval").SetInt(19);
    		FindConVar("director_force_background").SetInt(0);
    		FindConVar("z_background_limit").SetInt(26);
    		FindConVar("z_common_limit").SetInt(38);
    		FindConVar("z_mob_spawn_min_size").SetInt(10);
    		FindConVar("z_mob_spawn_finale_size").SetInt(20);
    		FindConVar("z_mob_spawn_max_size").SetInt(30);
    		FindConVar("z_mega_mob_size").SetInt(50);
    		FindConVar("z_mob_spawn_min_interval_normal").SetInt(50);
    		FindConVar("z_mob_spawn_max_interval_normal").SetInt(80);
    	}
    	case 2:
    	{
    		FindConVar("l4d_together_loner_punish").SetInt(1);
    		FindConVar("survivor_crawl_speed").SetInt(15);
    		FindConVar("survivor_revive_duration").SetInt(4);
    		FindConVar("survivor_revive_health").SetInt(48);
    		FindConVar("survivor_limp_health").SetInt(35);
    		FindConVar("first_aid_kit_use_duration").SetInt(4);
    		FindConVar("z_witch_health").SetInt(1100);
    		FindConVar("z_witch_burn_time").SetInt(16);
    		FindConVar("z_tank_speed").SetInt(212);
    		FindConVar("tongue_hit_delay").SetInt(18);
    		FindConVar("tongue_range").SetInt(950);
    		FindConVar("tongue_victim_max_speed").SetInt(175);
    		FindConVar("z_vomit_interval").SetInt(18);
    		FindConVar("director_force_background").SetInt(0);
    		FindConVar("z_background_limit").SetInt(27);
    		FindConVar("z_common_limit").SetInt(39);
    		FindConVar("z_mob_spawn_min_size").SetInt(12);
    		FindConVar("z_mob_spawn_finale_size").SetInt(24);
    		FindConVar("z_mob_spawn_max_size").SetInt(36);
    		FindConVar("z_mega_mob_size").SetInt(60);
    		FindConVar("z_mob_spawn_min_interval_normal").SetInt(50);
    		FindConVar("z_mob_spawn_max_interval_normal").SetInt(75);
    	}
    	case 3:
    	{
    		FindConVar("l4d_together_loner_punish").SetInt(1);
    		FindConVar("survivor_crawl_speed").SetInt(15);
    		FindConVar("survivor_revive_duration").SetInt(4);
    		FindConVar("survivor_revive_health").SetInt(47);
    		FindConVar("survivor_limp_health").SetInt(36);
    		FindConVar("first_aid_kit_use_duration").SetInt(4);
    		FindConVar("z_witch_health").SetInt(1150);
    		FindConVar("z_witch_burn_time").SetInt(17);
    		FindConVar("z_tank_speed").SetInt(213);
    		FindConVar("tongue_hit_delay").SetInt(17);
    		FindConVar("tongue_range").SetInt(1050);
    		FindConVar("tongue_victim_max_speed").SetInt(178);
    		FindConVar("z_vomit_interval").SetInt(17);
    		FindConVar("director_force_background").SetInt(0);
    		FindConVar("z_background_limit").SetInt(28);
    		FindConVar("z_common_limit").SetInt(40);
    		FindConVar("z_mob_spawn_min_size").SetInt(14);
    		FindConVar("z_mob_spawn_finale_size").SetInt(28);
    		FindConVar("z_mob_spawn_max_size").SetInt(42);
    		FindConVar("z_mega_mob_size").SetInt(70);
    		FindConVar("z_mob_spawn_min_interval_normal").SetInt(45);
    		FindConVar("z_mob_spawn_max_interval_normal").SetInt(75);
    	}
    	case 4:
    	{
    		FindConVar("l4d_together_loner_punish").SetInt(1);
    		FindConVar("survivor_crawl_speed").SetInt(20);
    		FindConVar("survivor_revive_duration").SetInt(5);
    		FindConVar("survivor_revive_health").SetInt(46);
    		FindConVar("survivor_limp_health").SetInt(36);
    		FindConVar("first_aid_kit_use_duration").SetInt(5);
    		FindConVar("z_witch_health").SetInt(1200);
    		FindConVar("z_witch_burn_time").SetInt(18);
    		FindConVar("z_tank_speed").SetInt(214);
    		FindConVar("tongue_hit_delay").SetInt(16);
    		FindConVar("tongue_range").SetInt(1200);
    		FindConVar("tongue_victim_max_speed").SetInt(181);
    		FindConVar("z_vomit_interval").SetInt(16);
    		FindConVar("director_force_background").SetInt(0);
    		FindConVar("z_background_limit").SetInt(29);
    		FindConVar("z_common_limit").SetInt(41);
    		FindConVar("z_mob_spawn_min_size").SetInt(16);
    		FindConVar("z_mob_spawn_finale_size").SetInt(32);
    		FindConVar("z_mob_spawn_max_size").SetInt(48);
    		FindConVar("z_mega_mob_size").SetInt(80);
    		FindConVar("z_mob_spawn_min_interval_normal").SetInt(45);
    		FindConVar("z_mob_spawn_max_interval_normal").SetInt(70);
    	}
    	case 5:
    	{
    		FindConVar("l4d_together_loner_punish").SetInt(1);
    		FindConVar("survivor_crawl_speed").SetInt(25);
    		FindConVar("survivor_revive_duration").SetInt(5);
    		FindConVar("survivor_revive_health").SetInt(45);
    		FindConVar("survivor_limp_health").SetInt(37);
    		FindConVar("first_aid_kit_use_duration").SetInt(5);
    		FindConVar("z_witch_health").SetInt(1250);
    		FindConVar("z_witch_burn_time").SetInt(19);
    		FindConVar("z_tank_speed").SetInt(215);
    		FindConVar("tongue_hit_delay").SetInt(15);
    		FindConVar("tongue_range").SetInt(1400);
    		FindConVar("tongue_victim_max_speed").SetInt(184);
    		FindConVar("z_vomit_interval").SetInt(15);
    		FindConVar("director_force_background").SetInt(0);
    		FindConVar("z_background_limit").SetInt(30);
    		FindConVar("z_common_limit").SetInt(42);
    		FindConVar("z_mob_spawn_min_size").SetInt(18);
    		FindConVar("z_mob_spawn_finale_size").SetInt(36);
    		FindConVar("z_mob_spawn_max_size").SetInt(54);
    		FindConVar("z_mega_mob_size").SetInt(90);
    		FindConVar("z_mob_spawn_min_interval_normal").SetInt(40);
    		FindConVar("z_mob_spawn_max_interval_normal").SetInt(70);
    	}
    	case 6:
    	{
    		FindConVar("l4d_together_loner_punish").SetInt(1);
    		FindConVar("survivor_crawl_speed").SetInt(30);
    		FindConVar("survivor_revive_duration").SetInt(6);
    		FindConVar("survivor_revive_health").SetInt(44);
    		FindConVar("survivor_limp_health").SetInt(37);
    		FindConVar("first_aid_kit_use_duration").SetInt(6);
    		FindConVar("z_witch_health").SetInt(1300);
    		FindConVar("z_witch_burn_time").SetInt(20);
    		FindConVar("z_tank_speed").SetInt(216);
    		FindConVar("tongue_hit_delay").SetInt(14);
    		FindConVar("tongue_range").SetInt(1600);
    		FindConVar("tongue_victim_max_speed").SetInt(187);
    		FindConVar("z_vomit_interval").SetInt(14);
    		FindConVar("director_force_background").SetInt(0);
    		FindConVar("z_background_limit").SetInt(31);
    		FindConVar("z_common_limit").SetInt(43);
    		FindConVar("z_mob_spawn_min_size").SetInt(20);
    		FindConVar("z_mob_spawn_finale_size").SetInt(40);
    		FindConVar("z_mob_spawn_max_size").SetInt(60);
    		FindConVar("z_mega_mob_size").SetInt(100);
    		FindConVar("z_mob_spawn_min_interval_normal").SetInt(40);
    		FindConVar("z_mob_spawn_max_interval_normal").SetInt(65);
    	}
    	case 7:
    	{
    		FindConVar("l4d_together_loner_punish").SetInt(1);
    		FindConVar("survivor_crawl_speed").SetInt(35);
    		FindConVar("survivor_revive_duration").SetInt(6);
    		FindConVar("survivor_revive_health").SetInt(43);
    		FindConVar("survivor_limp_health").SetInt(38);
    		FindConVar("first_aid_kit_use_duration").SetInt(6);
    		FindConVar("z_witch_health").SetInt(1350);
    		FindConVar("z_witch_burn_time").SetInt(21);
    		FindConVar("z_tank_speed").SetInt(217);
    		FindConVar("tongue_hit_delay").SetInt(13);
    		FindConVar("tongue_range").SetInt(1800);
    		FindConVar("tongue_victim_max_speed").SetInt(190);
    		FindConVar("z_vomit_interval").SetInt(13);
    		FindConVar("director_force_background").SetInt(0);
    		FindConVar("z_background_limit").SetInt(32);
    		FindConVar("z_common_limit").SetInt(44);
    		FindConVar("z_mob_spawn_min_size").SetInt(22);
    		FindConVar("z_mob_spawn_finale_size").SetInt(44);
    		FindConVar("z_mob_spawn_max_size").SetInt(66);
    		FindConVar("z_mega_mob_size").SetInt(110);
    		FindConVar("z_mob_spawn_min_interval_normal").SetInt(35);
    		FindConVar("z_mob_spawn_max_interval_normal").SetInt(65);
    	}
    	case 8:
    	{
    		FindConVar("l4d_together_loner_punish").SetInt(1);
    		FindConVar("survivor_crawl_speed").SetInt(40);
    		FindConVar("survivor_revive_duration").SetInt(7);
    		FindConVar("survivor_revive_health").SetInt(42);
    		FindConVar("survivor_limp_health").SetInt(38);
    		FindConVar("first_aid_kit_use_duration").SetInt(7);
    		FindConVar("z_witch_health").SetInt(1400);
    		FindConVar("z_witch_burn_time").SetInt(22);
    		FindConVar("z_tank_speed").SetInt(218);
    		FindConVar("tongue_hit_delay").SetInt(12);
    		FindConVar("tongue_range").SetInt(2000);
    		FindConVar("tongue_victim_max_speed").SetInt(193);
    		FindConVar("z_vomit_interval").SetInt(12);
    		FindConVar("director_force_background").SetInt(0);
    		FindConVar("z_background_limit").SetInt(33);
    		FindConVar("z_common_limit").SetInt(45);
    		FindConVar("z_mob_spawn_min_size").SetInt(24);
    		FindConVar("z_mob_spawn_finale_size").SetInt(48);
    		FindConVar("z_mob_spawn_max_size").SetInt(72);
    		FindConVar("z_mega_mob_size").SetInt(120);
    		FindConVar("z_mob_spawn_min_interval_normal").SetInt(35);
    		FindConVar("z_mob_spawn_max_interval_normal").SetInt(60);
    	}
    	case 9:
    	{
    		FindConVar("l4d_together_loner_punish").SetInt(1);
    		FindConVar("survivor_crawl_speed").SetInt(40);
    		FindConVar("survivor_revive_duration").SetInt(7);
    		FindConVar("survivor_revive_health").SetInt(41);
    		FindConVar("survivor_limp_health").SetInt(39);
    		FindConVar("first_aid_kit_use_duration").SetInt(7);
    		FindConVar("z_witch_health").SetInt(1450);
    		FindConVar("z_witch_burn_time").SetInt(23);
    		FindConVar("z_tank_speed").SetInt(219);
    		FindConVar("tongue_hit_delay").SetInt(11);
    		FindConVar("tongue_range").SetInt(2200);
    		FindConVar("tongue_victim_max_speed").SetInt(196);
    		FindConVar("z_vomit_interval").SetInt(11);
    		FindConVar("director_force_background").SetInt(40);
    		FindConVar("z_background_limit").SetInt(5);
    		FindConVar("z_common_limit").SetInt(45);
    		FindConVar("z_mob_spawn_min_size").SetInt(26);
    		FindConVar("z_mob_spawn_finale_size").SetInt(52);
    		FindConVar("z_mob_spawn_max_size").SetInt(78);
    		FindConVar("z_mega_mob_size").SetInt(130);
    		FindConVar("z_mob_spawn_min_interval_normal").SetInt(30);
    		FindConVar("z_mob_spawn_max_interval_normal").SetInt(60);
    	}
    	case 10:
    	{
    		FindConVar("l4d_together_loner_punish").SetInt(1);
    		FindConVar("survivor_crawl_speed").SetInt(40);
    		FindConVar("survivor_revive_duration").SetInt(7);
    		FindConVar("survivor_revive_health").SetInt(40);
    		FindConVar("survivor_limp_health").SetInt(40);
    		FindConVar("first_aid_kit_use_duration").SetInt(7);
    		FindConVar("z_witch_health").SetInt(1500);
    		FindConVar("z_witch_burn_time").SetInt(24);
    		FindConVar("z_tank_speed").SetInt(220);
    		FindConVar("tongue_hit_delay").SetInt(10);
    		FindConVar("tongue_range").SetInt(2400);
    		FindConVar("tongue_victim_max_speed").SetInt(199);
    		FindConVar("z_vomit_interval").SetInt(10);
    		FindConVar("director_force_background").SetInt(40);
    		FindConVar("z_background_limit").SetInt(5);
    		FindConVar("z_common_limit").SetInt(45);
    		FindConVar("z_mob_spawn_min_size").SetInt(28);
    		FindConVar("z_mob_spawn_finale_size").SetInt(56);
    		FindConVar("z_mob_spawn_max_size").SetInt(84);
    		FindConVar("z_mega_mob_size").SetInt(140);
    		FindConVar("z_mob_spawn_min_interval_normal").SetInt(30);
    		FindConVar("z_mob_spawn_max_interval_normal").SetInt(55);
    	}
	}
}

void SetDifficulty_Hard(int survivors)
{
	switch(survivors)
	{
    	case 1:
    	{
    		FindConVar("l4d_together_loner_punish").SetInt(0);
    		FindConVar("survivor_limp_health").SetInt(31);
    		FindConVar("first_aid_kit_use_duration").SetInt(4);
    		FindConVar("z_witch_health").SetInt(1050);
    		FindConVar("z_witch_burn_time").SetInt(15);
    		FindConVar("z_tank_speed").SetInt(211);
    		FindConVar("tongue_hit_delay").SetInt(20);
    		FindConVar("tongue_range").SetInt(900);
    		FindConVar("z_vomit_interval").SetInt(19);
    		FindConVar("director_force_background").SetInt(0);
    		FindConVar("z_background_limit").SetInt(26);
    		FindConVar("z_common_limit").SetInt(38);
    		FindConVar("z_mob_spawn_min_size").SetInt(10);
    		FindConVar("z_mob_spawn_finale_size").SetInt(20);
    		FindConVar("z_mob_spawn_max_size").SetInt(30);
    		FindConVar("z_mega_mob_size").SetInt(50);
    		FindConVar("z_mob_spawn_min_interval_hard").SetInt(40);
    		FindConVar("z_mob_spawn_max_interval_hard").SetInt(65);
    	}
    	case 2:
    	{
    		FindConVar("l4d_together_loner_punish").SetInt(1);
    		FindConVar("survivor_crawl_speed").SetInt(15);
    		FindConVar("survivor_revive_duration").SetInt(4);
    		FindConVar("survivor_revive_health").SetInt(48);
    		FindConVar("survivor_limp_health").SetInt(32);
    		FindConVar("first_aid_kit_use_duration").SetInt(4);
    		FindConVar("z_witch_health").SetInt(1100);
    		FindConVar("z_witch_burn_time").SetInt(16);
    		FindConVar("z_tank_speed").SetInt(212);
    		FindConVar("tongue_hit_delay").SetInt(18);
    		FindConVar("tongue_range").SetInt(1100);
    		FindConVar("tongue_victim_max_speed").SetInt(175);
    		FindConVar("z_vomit_interval").SetInt(18);
    		FindConVar("director_force_background").SetInt(0);
    		FindConVar("z_background_limit").SetInt(27);
    		FindConVar("z_common_limit").SetInt(39);
    		FindConVar("z_mob_spawn_min_size").SetInt(12);
    		FindConVar("z_mob_spawn_finale_size").SetInt(24);
    		FindConVar("z_mob_spawn_max_size").SetInt(36);
    		FindConVar("z_mega_mob_size").SetInt(60);
    		FindConVar("z_mob_spawn_min_interval_hard").SetInt(40);
    		FindConVar("z_mob_spawn_max_interval_hard").SetInt(60);
    	}
    	case 3:
    	{
    		FindConVar("l4d_together_loner_punish").SetInt(1);
    		FindConVar("survivor_crawl_speed").SetInt(15);
    		FindConVar("survivor_revive_duration").SetInt(4);
    		FindConVar("survivor_revive_health").SetInt(47);
    		FindConVar("survivor_limp_health").SetInt(33);
    		FindConVar("first_aid_kit_use_duration").SetInt(4);
    		FindConVar("z_witch_health").SetInt(1150);
    		FindConVar("z_witch_burn_time").SetInt(17);
    		FindConVar("z_tank_speed").SetInt(213);
    		FindConVar("tongue_hit_delay").SetInt(17);
    		FindConVar("tongue_range").SetInt(1350);
    		FindConVar("tongue_victim_max_speed").SetInt(178);
    		FindConVar("z_vomit_interval").SetInt(17);
    		FindConVar("director_force_background").SetInt(0);
    		FindConVar("z_background_limit").SetInt(28);
    		FindConVar("z_common_limit").SetInt(40);
    		FindConVar("z_mob_spawn_min_size").SetInt(14);
    		FindConVar("z_mob_spawn_finale_size").SetInt(28);
    		FindConVar("z_mob_spawn_max_size").SetInt(42);
    		FindConVar("z_mega_mob_size").SetInt(70);
    		FindConVar("z_mob_spawn_min_interval_hard").SetInt(35);
    		FindConVar("z_mob_spawn_max_interval_hard").SetInt(60);
    	}
    	case 4:
    	{
    		FindConVar("l4d_together_loner_punish").SetInt(1);
    		FindConVar("survivor_crawl_speed").SetInt(20);
    		FindConVar("survivor_revive_duration").SetInt(5);
    		FindConVar("survivor_revive_health").SetInt(46);
    		FindConVar("survivor_limp_health").SetInt(34);
    		FindConVar("first_aid_kit_use_duration").SetInt(5);
    		FindConVar("z_witch_health").SetInt(1200);
    		FindConVar("z_witch_burn_time").SetInt(18);
    		FindConVar("z_tank_speed").SetInt(214);
    		FindConVar("tongue_hit_delay").SetInt(16);
    		FindConVar("tongue_range").SetInt(1500);
    		FindConVar("tongue_victim_max_speed").SetInt(181);
    		FindConVar("z_vomit_interval").SetInt(16);
    		FindConVar("director_force_background").SetInt(0);
    		FindConVar("z_background_limit").SetInt(29);
    		FindConVar("z_common_limit").SetInt(41);
    		FindConVar("z_mob_spawn_min_size").SetInt(16);
    		FindConVar("z_mob_spawn_finale_size").SetInt(32);
    		FindConVar("z_mob_spawn_max_size").SetInt(48);
    		FindConVar("z_mega_mob_size").SetInt(80);
    		FindConVar("z_mob_spawn_min_interval_hard").SetInt(35);
    		FindConVar("z_mob_spawn_max_interval_hard").SetInt(55);
    	}
    	case 5:
    	{
    		FindConVar("l4d_together_loner_punish").SetInt(1);
    		FindConVar("survivor_crawl_speed").SetInt(25);
    		FindConVar("survivor_revive_duration").SetInt(5);
    		FindConVar("survivor_revive_health").SetInt(45);
    		FindConVar("survivor_limp_health").SetInt(35);
    		FindConVar("first_aid_kit_use_duration").SetInt(5);
    		FindConVar("z_witch_health").SetInt(1250);
    		FindConVar("z_witch_burn_time").SetInt(19);
    		FindConVar("z_tank_speed").SetInt(215);
    		FindConVar("tongue_hit_delay").SetInt(15);
    		FindConVar("tongue_range").SetInt(1750);
    		FindConVar("tongue_victim_max_speed").SetInt(184);
    		FindConVar("z_vomit_interval").SetInt(15);
    		FindConVar("director_force_background").SetInt(0);
    		FindConVar("z_background_limit").SetInt(30);
    		FindConVar("z_common_limit").SetInt(42);
    		FindConVar("z_mob_spawn_min_size").SetInt(18);
    		FindConVar("z_mob_spawn_finale_size").SetInt(36);
    		FindConVar("z_mob_spawn_max_size").SetInt(54);
    		FindConVar("z_mega_mob_size").SetInt(90);
    		FindConVar("z_mob_spawn_min_interval_hard").SetInt(30);
    		FindConVar("z_mob_spawn_max_interval_hard").SetInt(55);
    	}
    	case 6:
    	{
    		FindConVar("l4d_together_loner_punish").SetInt(1);
    		FindConVar("survivor_crawl_speed").SetInt(30);
    		FindConVar("survivor_revive_duration").SetInt(6);
    		FindConVar("survivor_revive_health").SetInt(44);
    		FindConVar("survivor_limp_health").SetInt(36);
    		FindConVar("first_aid_kit_use_duration").SetInt(6);
    		FindConVar("z_witch_health").SetInt(1300);
    		FindConVar("z_witch_burn_time").SetInt(20);
    		FindConVar("z_tank_speed").SetInt(216);
    		FindConVar("tongue_hit_delay").SetInt(14);
    		FindConVar("tongue_range").SetInt(2000);
    		FindConVar("tongue_victim_max_speed").SetInt(187);
    		FindConVar("z_vomit_interval").SetInt(14);
    		FindConVar("director_force_background").SetInt(0);
    		FindConVar("z_background_limit").SetInt(31);
    		FindConVar("z_common_limit").SetInt(43);
    		FindConVar("z_mob_spawn_min_size").SetInt(20);
    		FindConVar("z_mob_spawn_finale_size").SetInt(40);
    		FindConVar("z_mob_spawn_max_size").SetInt(60);
    		FindConVar("z_mega_mob_size").SetInt(100);
    		FindConVar("z_mob_spawn_min_interval_hard").SetInt(30);
    		FindConVar("z_mob_spawn_max_interval_hard").SetInt(50);
    	}
    	case 7:
    	{
    		FindConVar("l4d_together_loner_punish").SetInt(1);
    		FindConVar("survivor_crawl_speed").SetInt(35);
    		FindConVar("survivor_revive_duration").SetInt(6);
    		FindConVar("survivor_revive_health").SetInt(43);
    		FindConVar("survivor_limp_health").SetInt(37);
    		FindConVar("first_aid_kit_use_duration").SetInt(6);
    		FindConVar("z_witch_health").SetInt(1350);
    		FindConVar("z_witch_burn_time").SetInt(21);
    		FindConVar("z_tank_speed").SetInt(217);
    		FindConVar("tongue_hit_delay").SetInt(13);
    		FindConVar("tongue_range").SetInt(2250);
    		FindConVar("tongue_victim_max_speed").SetInt(190);
    		FindConVar("z_vomit_interval").SetInt(13);
    		FindConVar("director_force_background").SetInt(0);
    		FindConVar("z_background_limit").SetInt(32);
    		FindConVar("z_common_limit").SetInt(44);
    		FindConVar("z_mob_spawn_min_size").SetInt(22);
    		FindConVar("z_mob_spawn_finale_size").SetInt(44);
    		FindConVar("z_mob_spawn_max_size").SetInt(66);
    		FindConVar("z_mega_mob_size").SetInt(110);
    		FindConVar("z_mob_spawn_min_interval_hard").SetInt(25);
    		FindConVar("z_mob_spawn_max_interval_hard").SetInt(50);
    	}
    	case 8:
    	{
    		FindConVar("l4d_together_loner_punish").SetInt(1);
    		FindConVar("survivor_crawl_speed").SetInt(40);
    		FindConVar("survivor_revive_duration").SetInt(7);
    		FindConVar("survivor_revive_health").SetInt(42);
    		FindConVar("survivor_limp_health").SetInt(38);
    		FindConVar("first_aid_kit_use_duration").SetInt(7);
    		FindConVar("z_witch_health").SetInt(1400);
    		FindConVar("z_witch_burn_time").SetInt(22);
    		FindConVar("z_tank_speed").SetInt(218);
    		FindConVar("tongue_hit_delay").SetInt(12);
    		FindConVar("tongue_range").SetInt(2500);
    		FindConVar("tongue_victim_max_speed").SetInt(193);
    		FindConVar("z_vomit_interval").SetInt(12);
    		FindConVar("director_force_background").SetInt(0);
    		FindConVar("z_background_limit").SetInt(33);
    		FindConVar("z_common_limit").SetInt(45);
    		FindConVar("z_mob_spawn_min_size").SetInt(24);
    		FindConVar("z_mob_spawn_finale_size").SetInt(48);
    		FindConVar("z_mob_spawn_max_size").SetInt(72);
    		FindConVar("z_mega_mob_size").SetInt(120);
    		FindConVar("z_mob_spawn_min_interval_hard").SetInt(25);
    		FindConVar("z_mob_spawn_max_interval_hard").SetInt(45);
    	}
    	case 9:
    	{
    		FindConVar("l4d_together_loner_punish").SetInt(1);
    		FindConVar("survivor_crawl_speed").SetInt(40);
    		FindConVar("survivor_revive_duration").SetInt(7);
    		FindConVar("survivor_revive_health").SetInt(41);
    		FindConVar("survivor_limp_health").SetInt(39);
    		FindConVar("first_aid_kit_use_duration").SetInt(7);
    		FindConVar("z_witch_health").SetInt(1450);
    		FindConVar("z_witch_burn_time").SetInt(23);
    		FindConVar("z_tank_speed").SetInt(219);
    		FindConVar("tongue_hit_delay").SetInt(11);
    		FindConVar("tongue_range").SetInt(2800);
    		FindConVar("tongue_victim_max_speed").SetInt(196);
    		FindConVar("z_vomit_interval").SetInt(11);
    		FindConVar("director_force_background").SetInt(40);
    		FindConVar("z_background_limit").SetInt(5);
    		FindConVar("z_common_limit").SetInt(45);
    		FindConVar("z_mob_spawn_min_size").SetInt(26);
    		FindConVar("z_mob_spawn_finale_size").SetInt(52);
    		FindConVar("z_mob_spawn_max_size").SetInt(78);
    		FindConVar("z_mega_mob_size").SetInt(130);
    		FindConVar("z_mob_spawn_min_interval_hard").SetInt(20);
    		FindConVar("z_mob_spawn_max_interval_hard").SetInt(45);
    	}
    	case 10:
    	{
    		FindConVar("l4d_together_loner_punish").SetInt(1);
    		FindConVar("survivor_crawl_speed").SetInt(40);
    		FindConVar("survivor_revive_duration").SetInt(7);
    		FindConVar("survivor_revive_health").SetInt(40);
    		FindConVar("survivor_limp_health").SetInt(40);
    		FindConVar("first_aid_kit_use_duration").SetInt(7);
    		FindConVar("z_witch_health").SetInt(1500);
    		FindConVar("z_witch_burn_time").SetInt(24);
    		FindConVar("z_tank_speed").SetInt(220);
    		FindConVar("tongue_hit_delay").SetInt(10);
    		FindConVar("tongue_range").SetInt(3100);
    		FindConVar("tongue_victim_max_speed").SetInt(199);
    		FindConVar("z_vomit_interval").SetInt(10);
    		FindConVar("director_force_background").SetInt(40);
    		FindConVar("z_background_limit").SetInt(5);
    		FindConVar("z_common_limit").SetInt(45);
    		FindConVar("z_mob_spawn_min_size").SetInt(28);
    		FindConVar("z_mob_spawn_finale_size").SetInt(56);
    		FindConVar("z_mob_spawn_max_size").SetInt(84);
    		FindConVar("z_mega_mob_size").SetInt(140);
    		FindConVar("z_mob_spawn_min_interval_hard").SetInt(20);
    		FindConVar("z_mob_spawn_max_interval_hard").SetInt(40);
    	}
	}
}

void SetDifficulty_Impossible(int survivors)
{
	switch(survivors)
	{
	    case 1:
    	{
    		FindConVar("l4d_together_loner_punish").SetInt(0);
    		FindConVar("survivor_limp_health").SetInt(35);
    		FindConVar("first_aid_kit_use_duration").SetInt(4);
    		FindConVar("z_witch_health").SetInt(1050);
    		FindConVar("z_witch_burn_time").SetInt(15);
    		FindConVar("z_tank_speed").SetInt(211);
    		FindConVar("tongue_hit_delay").SetInt(20);
    		FindConVar("tongue_range").SetInt(1000);
    		FindConVar("z_vomit_interval").SetInt(19);
    		FindConVar("director_force_background").SetInt(0);
    		FindConVar("z_background_limit").SetInt(26);
    		FindConVar("z_common_limit").SetInt(38);
    		FindConVar("z_mob_spawn_min_size").SetInt(10);
    		FindConVar("z_mob_spawn_finale_size").SetInt(20);
    		FindConVar("z_mob_spawn_max_size").SetInt(30);
    		FindConVar("z_mega_mob_size").SetInt(50);
    		FindConVar("z_mob_spawn_min_interval_expert").SetInt(35);
    		FindConVar("z_mob_spawn_max_interval_expert").SetInt(60);
    	}
    	case 2:
    	{
    		FindConVar("l4d_together_loner_punish").SetInt(1);
    		FindConVar("survivor_crawl_speed").SetInt(15);
    		FindConVar("survivor_revive_duration").SetInt(4);
    		FindConVar("survivor_revive_health").SetInt(41);
    		FindConVar("survivor_limp_health").SetInt(39);
    		FindConVar("first_aid_kit_use_duration").SetInt(4);
    		FindConVar("z_witch_health").SetInt(1100);
    		FindConVar("z_witch_burn_time").SetInt(16);
    		FindConVar("z_tank_speed").SetInt(212);
    		FindConVar("tongue_hit_delay").SetInt(18);
    		FindConVar("tongue_range").SetInt(1300);
    		FindConVar("tongue_victim_max_speed").SetInt(175);
    		FindConVar("z_vomit_interval").SetInt(18);
    		FindConVar("director_force_background").SetInt(0);
    		FindConVar("z_background_limit").SetInt(27);
    		FindConVar("z_common_limit").SetInt(39);
    		FindConVar("z_mob_spawn_min_size").SetInt(12);
    		FindConVar("z_mob_spawn_finale_size").SetInt(24);
    		FindConVar("z_mob_spawn_max_size").SetInt(36);
    		FindConVar("z_mega_mob_size").SetInt(60);
    		FindConVar("z_mob_spawn_min_interval_expert").SetInt(35);
    		FindConVar("z_mob_spawn_max_interval_expert").SetInt(55);
    	}
    	case 3:
    	{
    		FindConVar("l4d_together_loner_punish").SetInt(1);
    		FindConVar("survivor_crawl_speed").SetInt(15);
    		FindConVar("survivor_revive_duration").SetInt(4);
    		FindConVar("survivor_revive_health").SetInt(43);
    		FindConVar("survivor_limp_health").SetInt(38);
    		FindConVar("first_aid_kit_use_duration").SetInt(4);
    		FindConVar("z_witch_health").SetInt(1150);
    		FindConVar("z_witch_burn_time").SetInt(17);
    		FindConVar("z_tank_speed").SetInt(213);
    		FindConVar("tongue_hit_delay").SetInt(17);
    		FindConVar("tongue_range").SetInt(1600);
    		FindConVar("tongue_victim_max_speed").SetInt(178);
    		FindConVar("z_vomit_interval").SetInt(17);
    		FindConVar("director_force_background").SetInt(0);
    		FindConVar("z_background_limit").SetInt(28);
    		FindConVar("z_common_limit").SetInt(40);
    		FindConVar("z_mob_spawn_min_size").SetInt(14);
    		FindConVar("z_mob_spawn_finale_size").SetInt(28);
    		FindConVar("z_mob_spawn_max_size").SetInt(42);
    		FindConVar("z_mega_mob_size").SetInt(70);
    		FindConVar("z_mob_spawn_min_interval_expert").SetInt(30);
    		FindConVar("z_mob_spawn_max_interval_expert").SetInt(55);
    	}
    	case 4:
    	{
    		FindConVar("l4d_together_loner_punish").SetInt(1);
    		FindConVar("survivor_crawl_speed").SetInt(20);
    		FindConVar("survivor_revive_duration").SetInt(5);
    		FindConVar("survivor_revive_health").SetInt(44);
    		FindConVar("survivor_limp_health").SetInt(37);
    		FindConVar("first_aid_kit_use_duration").SetInt(5);
    		FindConVar("z_witch_health").SetInt(1200);
    		FindConVar("z_witch_burn_time").SetInt(18);
    		FindConVar("z_tank_speed").SetInt(214);
    		FindConVar("tongue_hit_delay").SetInt(16);
    		FindConVar("tongue_range").SetInt(1900);
    		FindConVar("tongue_victim_max_speed").SetInt(181);
    		FindConVar("z_vomit_interval").SetInt(16);
    		FindConVar("director_force_background").SetInt(0);
    		FindConVar("z_background_limit").SetInt(29);
    		FindConVar("z_common_limit").SetInt(41);
    		FindConVar("z_mob_spawn_min_size").SetInt(16);
    		FindConVar("z_mob_spawn_finale_size").SetInt(32);
    		FindConVar("z_mob_spawn_max_size").SetInt(48);
    		FindConVar("z_mega_mob_size").SetInt(80);
    		FindConVar("z_mob_spawn_min_interval_expert").SetInt(30);
    		FindConVar("z_mob_spawn_max_interval_expert").SetInt(50);
    	}
    	case 5:
    	{
    		FindConVar("l4d_together_loner_punish").SetInt(1);
    		FindConVar("survivor_crawl_speed").SetInt(25);
    		FindConVar("survivor_revive_duration").SetInt(5);
    		FindConVar("survivor_revive_health").SetInt(45);
    		FindConVar("survivor_limp_health").SetInt(36);
    		FindConVar("first_aid_kit_use_duration").SetInt(5);
    		FindConVar("z_witch_health").SetInt(1250);
    		FindConVar("z_witch_burn_time").SetInt(19);
    		FindConVar("z_tank_speed").SetInt(215);
    		FindConVar("tongue_hit_delay").SetInt(15);
    		FindConVar("tongue_range").SetInt(2300);
    		FindConVar("tongue_victim_max_speed").SetInt(184);
    		FindConVar("z_vomit_interval").SetInt(15);
    		FindConVar("director_force_background").SetInt(0);
    		FindConVar("z_background_limit").SetInt(30);
    		FindConVar("z_common_limit").SetInt(42);
    		FindConVar("z_mob_spawn_min_size").SetInt(18);
    		FindConVar("z_mob_spawn_finale_size").SetInt(36);
    		FindConVar("z_mob_spawn_max_size").SetInt(54);
    		FindConVar("z_mega_mob_size").SetInt(90);
    		FindConVar("z_mob_spawn_min_interval_expert").SetInt(25);
    		FindConVar("z_mob_spawn_max_interval_expert").SetInt(50);
    	}
    	case 6:
    	{
    		FindConVar("l4d_together_loner_punish").SetInt(1);
    		FindConVar("survivor_crawl_speed").SetInt(30);
    		FindConVar("survivor_revive_duration").SetInt(6);
    		FindConVar("survivor_revive_health").SetInt(44);
    		FindConVar("survivor_limp_health").SetInt(35);
    		FindConVar("first_aid_kit_use_duration").SetInt(6);
    		FindConVar("z_witch_health").SetInt(1300);
    		FindConVar("z_witch_burn_time").SetInt(20);
    		FindConVar("z_tank_speed").SetInt(216);
    		FindConVar("tongue_hit_delay").SetInt(14);
    		FindConVar("tongue_range").SetInt(2700);
    		FindConVar("tongue_victim_max_speed").SetInt(187);
    		FindConVar("z_vomit_interval").SetInt(14);
    		FindConVar("director_force_background").SetInt(0);
    		FindConVar("z_background_limit").SetInt(31);
    		FindConVar("z_common_limit").SetInt(43);
    		FindConVar("z_mob_spawn_min_size").SetInt(20);
    		FindConVar("z_mob_spawn_finale_size").SetInt(40);
    		FindConVar("z_mob_spawn_max_size").SetInt(60);
    		FindConVar("z_mega_mob_size").SetInt(100);
    		FindConVar("z_mob_spawn_min_interval_expert").SetInt(25);
    		FindConVar("z_mob_spawn_max_interval_expert").SetInt(45);
    	}
    	case 7:
    	{
    		FindConVar("l4d_together_loner_punish").SetInt(1);
    		FindConVar("survivor_crawl_speed").SetInt(35);
    		FindConVar("survivor_revive_duration").SetInt(6);
    		FindConVar("survivor_revive_health").SetInt(43);
    		FindConVar("survivor_limp_health").SetInt(35);
    		FindConVar("first_aid_kit_use_duration").SetInt(6);
    		FindConVar("z_witch_health").SetInt(1350);
    		FindConVar("z_witch_burn_time").SetInt(21);
    		FindConVar("z_tank_speed").SetInt(217);
    		FindConVar("tongue_hit_delay").SetInt(13);
    		FindConVar("tongue_range").SetInt(3000);
    		FindConVar("tongue_victim_max_speed").SetInt(190);
    		FindConVar("z_vomit_interval").SetInt(13);
    		FindConVar("director_force_background").SetInt(0);
    		FindConVar("z_background_limit").SetInt(32);
    		FindConVar("z_common_limit").SetInt(44);
    		FindConVar("z_mob_spawn_min_size").SetInt(22);
    		FindConVar("z_mob_spawn_finale_size").SetInt(44);
    		FindConVar("z_mob_spawn_max_size").SetInt(66);
    		FindConVar("z_mega_mob_size").SetInt(110);
    		FindConVar("z_mob_spawn_min_interval_expert").SetInt(20);
    		FindConVar("z_mob_spawn_max_interval_expert").SetInt(45);
    	}
    	case 8:
    	{
    		FindConVar("l4d_together_loner_punish").SetInt(1);
    		FindConVar("survivor_crawl_speed").SetInt(40);
    		FindConVar("survivor_revive_duration").SetInt(7);
    		FindConVar("survivor_revive_health").SetInt(42);
    		FindConVar("survivor_limp_health").SetInt(35);
    		FindConVar("first_aid_kit_use_duration").SetInt(7);
    		FindConVar("z_witch_health").SetInt(1400);
    		FindConVar("z_witch_burn_time").SetInt(22);
    		FindConVar("z_tank_speed").SetInt(218);
    		FindConVar("tongue_hit_delay").SetInt(12);
    		FindConVar("tongue_range").SetInt(3500);
    		FindConVar("tongue_victim_max_speed").SetInt(193);
    		FindConVar("z_vomit_interval").SetInt(12);
    		FindConVar("director_force_background").SetInt(0);
    		FindConVar("z_background_limit").SetInt(33);
    		FindConVar("z_common_limit").SetInt(45);
    		FindConVar("z_mob_spawn_min_size").SetInt(24);
    		FindConVar("z_mob_spawn_finale_size").SetInt(48);
    		FindConVar("z_mob_spawn_max_size").SetInt(72);
    		FindConVar("z_mega_mob_size").SetInt(120);
    		FindConVar("z_mob_spawn_min_interval_expert").SetInt(20);
    		FindConVar("z_mob_spawn_max_interval_expert").SetInt(40);
    	}
    	case 9:
    	{
    		FindConVar("l4d_together_loner_punish").SetInt(1);
    		FindConVar("survivor_crawl_speed").SetInt(40);
    		FindConVar("survivor_revive_duration").SetInt(7);
    		FindConVar("survivor_revive_health").SetInt(41);
    		FindConVar("survivor_limp_health").SetInt(35);
    		FindConVar("first_aid_kit_use_duration").SetInt(7);
    		FindConVar("z_witch_health").SetInt(1450);
    		FindConVar("z_witch_burn_time").SetInt(23);
    		FindConVar("z_tank_speed").SetInt(219);
    		FindConVar("tongue_hit_delay").SetInt(11);
    		FindConVar("tongue_range").SetInt(4000);
    		FindConVar("tongue_victim_max_speed").SetInt(196);
    		FindConVar("z_vomit_interval").SetInt(11);
    		FindConVar("director_force_background").SetInt(40);
    		FindConVar("z_background_limit").SetInt(5);
    		FindConVar("z_common_limit").SetInt(45);
    		FindConVar("z_mob_spawn_min_size").SetInt(26);
    		FindConVar("z_mob_spawn_finale_size").SetInt(52);
    		FindConVar("z_mob_spawn_max_size").SetInt(78);
    		FindConVar("z_mega_mob_size").SetInt(130);
    		FindConVar("z_mob_spawn_min_interval_expert").SetInt(15);
    		FindConVar("z_mob_spawn_max_interval_expert").SetInt(40);
    	}
    	case 10:
    	{
    		FindConVar("l4d_together_loner_punish").SetInt(1);
    		FindConVar("survivor_crawl_speed").SetInt(40);
    		FindConVar("survivor_revive_duration").SetInt(7);
    		FindConVar("survivor_revive_health").SetInt(40);
    		FindConVar("survivor_limp_health").SetInt(35);
    		FindConVar("first_aid_kit_use_duration").SetInt(7);
    		FindConVar("z_witch_health").SetInt(1500);
    		FindConVar("z_witch_burn_time").SetInt(24);
    		FindConVar("z_tank_speed").SetInt(220);
    		FindConVar("tongue_hit_delay").SetInt(10);
    		FindConVar("tongue_range").SetInt(4500);
    		FindConVar("tongue_victim_max_speed").SetInt(199);
    		FindConVar("z_vomit_interval").SetInt(10);
    		FindConVar("director_force_background").SetInt(40);
    		FindConVar("z_background_limit").SetInt(5);
    		FindConVar("z_common_limit").SetInt(45);
    		FindConVar("z_mob_spawn_min_size").SetInt(28);
    		FindConVar("z_mob_spawn_finale_size").SetInt(56);
    		FindConVar("z_mob_spawn_max_size").SetInt(84);
    		FindConVar("z_mega_mob_size").SetInt(140);
    		FindConVar("z_mob_spawn_min_interval_expert").SetInt(15);
    		FindConVar("z_mob_spawn_max_interval_expert").SetInt(35);
    	}
	}
}
