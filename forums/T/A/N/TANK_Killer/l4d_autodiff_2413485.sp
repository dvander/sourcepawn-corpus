#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.4"

public Plugin:myinfo = 
{
	name = "[L4D] Difficulty Regulator",
	author = "chinagreenelvis, TANK Killer ТАНКИ™",
	description = "",
	version = PLUGIN_VERSION,
	url = ""
}

new survivors = 0;

new Handle:NSS_ad = INVALID_HANDLE;
new Handle:z_difficulty;

public OnPluginStart() 
{
	NSS_ad = CreateConVar("NSS_ad", "1", "Вкл/Выкл плагин", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	z_difficulty = FindConVar("z_difficulty");
	
	AutoExecConfig(true, "NSS_autodiff4");

	HookEvent("player_first_spawn", Event_PlayerFirstSpawn);
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("player_death", DifficultySet);
	HookEvent("difficulty_changed", DifficultySet);
	HookEvent("survivor_rescued", DifficultySet);
	HookEvent("player_team", DifficultySet);
}

public Event_PlayerFirstSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IsClientConnected(client) && IsClientInGame(client) && !IsFakeClient(client))
	{
		if (GetConVarInt(NSS_ad) == 1)
		{
			CreateTimer(5.0, Timer_DifficultySet);
		}
	}
}

public Action:Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IsClientConnected(client) && IsClientInGame(client) && !IsFakeClient(client))
	{
		if (GetConVarInt(NSS_ad) == 1)
		{
			CreateTimer(5.0, Timer_DifficultyCheck);
			CreateTimer(5.0, Timer_DifficultySet);
		}
		else if (GetConVarInt(NSS_ad) == 0)
		{
			return Plugin_Handled;
		}
	}
	return Plugin_Handled;
}

public DifficultySet(Handle:event, const String:name[], bool:dontBroadcast)
{
	CreateTimer(5.0, Timer_DifficultySet);
}

public Action:Timer_DifficultyCheck(Handle:timer)
{
	if (GetConVarInt(NSS_ad) == 1)
	{
		survivors = 0;
		for (new i = 1; i <= MaxClients; i++)
		{
			if(i)
			{
				if (IsClientInGame(i) && GetClientTeam(i) == 2)
				{
					survivors++;
				}
			}
		}
		if (survivors)
		{
			decl String:sGameDifficulty[16];
			GetConVarString(z_difficulty, sGameDifficulty, sizeof(sGameDifficulty));
			if (StrEqual(sGameDifficulty, "Easy", false))
			{
				SetDifficulty_Easy();
			}
			else if (StrEqual(sGameDifficulty, "Normal", false))
			{
				SetDifficulty_Normal();
			}
			else if (StrEqual(sGameDifficulty, "Hard", false))
			{
				SetDifficulty_Hard();
			}
			else if (StrEqual(sGameDifficulty, "Impossible", false))
			{
				SetDifficulty_Impossible();
			}
		}
	}
}

public Action:Timer_DifficultySet(Handle:timer)
{
	if (GetConVarInt(NSS_ad) == 1)
	{
		new alivesurvivors = 0;
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && GetClientTeam(i) == 2) 
			{
				if (IsPlayerAlive(i))
				{
					alivesurvivors++;
				}
			}
		}
		if (alivesurvivors)
		{
			decl String:sGameDifficulty[16];
			GetConVarString(z_difficulty, sGameDifficulty, sizeof(sGameDifficulty));
			if (StrEqual(sGameDifficulty, "Easy", false))
			{
				SetDifficulty_Easy();
				survivors = alivesurvivors;
			}
			else if (StrEqual(sGameDifficulty, "Normal", false))
			{
				SetDifficulty_Normal();
				survivors = alivesurvivors;
			}
			else if (StrEqual(sGameDifficulty, "Hard", false))
			{
				SetDifficulty_Hard();
				survivors = alivesurvivors;
			}
			else if (StrEqual(sGameDifficulty, "Impossible", false))
			{
				SetDifficulty_Impossible();
				survivors = alivesurvivors;
			}
		}
	}
}

SetDifficulty_Easy()
{
	new count = survivors;
	if (count == 1)
	{
		SetConVarInt(FindConVar("survivor_limp_health"), 35);
		SetConVarInt(FindConVar("first_aid_kit_use_duration"), 4);
		SetConVarInt(FindConVar("z_witch_health"), 1050);
		SetConVarInt(FindConVar("z_witch_burn_time"), 15);
		SetConVarInt(FindConVar("z_tank_speed"), 211);
		SetConVarInt(FindConVar("tongue_hit_delay"), 20);
		SetConVarInt(FindConVar("tongue_range"), 800);
		SetConVarInt(FindConVar("z_vomit_interval"), 25);
		SetConVarInt(FindConVar("director_force_background"), 0);
		SetConVarInt(FindConVar("z_background_limit"), 26);
		SetConVarInt(FindConVar("z_common_limit"), 31);
		SetConVarInt(FindConVar("z_mob_spawn_min_size"), 10);
		SetConVarInt(FindConVar("z_mob_spawn_finale_size"), 20);
		SetConVarInt(FindConVar("z_mob_spawn_max_size"), 30);
		SetConVarInt(FindConVar("z_mega_mob_size"), 50);
		SetConVarInt(FindConVar("z_mob_spawn_min_interval_easy"), 70);
		SetConVarInt(FindConVar("z_mob_spawn_max_interval_easy"), 120);
	}
	else if (count == 2)
	{
		SetConVarInt(FindConVar("survivor_crawl_speed"), 15);
		SetConVarInt(FindConVar("survivor_revive_duration"), 4);
		SetConVarInt(FindConVar("survivor_revive_health"), 41);
		SetConVarInt(FindConVar("survivor_limp_health"), 39);
		SetConVarInt(FindConVar("first_aid_kit_use_duration"), 4);
		SetConVarInt(FindConVar("z_witch_health"), 1100);
		SetConVarInt(FindConVar("z_witch_burn_time"), 16);
		SetConVarInt(FindConVar("z_tank_speed"), 212);
		SetConVarInt(FindConVar("tongue_hit_delay"), 18);
		SetConVarInt(FindConVar("tongue_range"), 950);
		SetConVarInt(FindConVar("tongue_victim_max_speed"), 180);
		SetConVarInt(FindConVar("z_vomit_interval"), 23);
		SetConVarInt(FindConVar("director_force_background"), 0);
		SetConVarInt(FindConVar("z_background_limit"), 27);
		SetConVarInt(FindConVar("z_common_limit"), 32);
		SetConVarInt(FindConVar("z_mob_spawn_min_size"), 12);
		SetConVarInt(FindConVar("z_mob_spawn_finale_size"), 24);
		SetConVarInt(FindConVar("z_mob_spawn_max_size"), 36);
		SetConVarInt(FindConVar("z_mega_mob_size"), 60);
		SetConVarInt(FindConVar("z_mob_spawn_min_interval_easy"), 70);
		SetConVarInt(FindConVar("z_mob_spawn_max_interval_easy"), 110);
	}
	else if (count == 3)
	{
		SetConVarInt(FindConVar("survivor_crawl_speed"), 15);
		SetConVarInt(FindConVar("survivor_revive_duration"), 5);
		SetConVarInt(FindConVar("survivor_revive_health"), 43);
		SetConVarInt(FindConVar("survivor_limp_health"), 38);
		SetConVarInt(FindConVar("first_aid_kit_use_duration"), 5);
		SetConVarInt(FindConVar("z_witch_health"), 1150);
		SetConVarInt(FindConVar("z_witch_burn_time"), 17);
		SetConVarInt(FindConVar("z_tank_speed"), 213);
		SetConVarInt(FindConVar("tongue_hit_delay"), 17);
		SetConVarInt(FindConVar("tongue_range"), 1100);
		SetConVarInt(FindConVar("tongue_victim_max_speed"), 185);
		SetConVarInt(FindConVar("z_vomit_interval"), 22);
		SetConVarInt(FindConVar("director_force_background"), 0);
		SetConVarInt(FindConVar("z_background_limit"), 28);
		SetConVarInt(FindConVar("z_common_limit"), 33);
		SetConVarInt(FindConVar("z_mob_spawn_min_size"), 14);
		SetConVarInt(FindConVar("z_mob_spawn_finale_size"), 28);
		SetConVarInt(FindConVar("z_mob_spawn_max_size"), 42);
		SetConVarInt(FindConVar("z_mega_mob_size"), 70);
		SetConVarInt(FindConVar("z_mob_spawn_min_interval_easy"), 70);
		SetConVarInt(FindConVar("z_mob_spawn_max_interval_easy"), 100);
	}
	else if (count == 4)
	{
		SetConVarInt(FindConVar("survivor_crawl_speed"), 20);
		SetConVarInt(FindConVar("survivor_revive_duration"), 5);
		SetConVarInt(FindConVar("survivor_revive_health"), 44);
		SetConVarInt(FindConVar("survivor_limp_health"), 37);
		SetConVarInt(FindConVar("first_aid_kit_use_duration"), 5);
		SetConVarInt(FindConVar("z_witch_health"), 1200);
		SetConVarInt(FindConVar("z_witch_burn_time"), 18);
		SetConVarInt(FindConVar("z_tank_speed"), 214);
		SetConVarInt(FindConVar("tongue_hit_delay"), 16);
		SetConVarInt(FindConVar("tongue_range"), 1250);
		SetConVarInt(FindConVar("tongue_victim_max_speed"), 190);
		SetConVarInt(FindConVar("z_vomit_interval"), 21);
		SetConVarInt(FindConVar("director_force_background"), 0);
		SetConVarInt(FindConVar("z_background_limit"), 29);
		SetConVarInt(FindConVar("z_common_limit"), 34);
		SetConVarInt(FindConVar("z_mob_spawn_min_size"), 16);
		SetConVarInt(FindConVar("z_mob_spawn_finale_size"), 32);
		SetConVarInt(FindConVar("z_mob_spawn_max_size"), 48);
		SetConVarInt(FindConVar("z_mega_mob_size"), 80);
		SetConVarInt(FindConVar("z_mob_spawn_min_interval_easy"), 70);
		SetConVarInt(FindConVar("z_mob_spawn_max_interval_easy"), 90);
	}
	else if (count == 5)
	{
		SetConVarInt(FindConVar("survivor_crawl_speed"), 25);
		SetConVarInt(FindConVar("survivor_revive_duration"), 6);
		SetConVarInt(FindConVar("survivor_revive_health"), 45);
		SetConVarInt(FindConVar("survivor_limp_health"), 36);
		SetConVarInt(FindConVar("first_aid_kit_use_duration"), 6);
		SetConVarInt(FindConVar("z_witch_health"), 1250);
		SetConVarInt(FindConVar("z_witch_burn_time"), 19);
		SetConVarInt(FindConVar("z_tank_speed"), 215);
		SetConVarInt(FindConVar("tongue_hit_delay"), 15);
		SetConVarInt(FindConVar("tongue_range"), 1400);
		SetConVarInt(FindConVar("tongue_victim_max_speed"), 195);
		SetConVarInt(FindConVar("z_vomit_interval"), 20);
		SetConVarInt(FindConVar("director_force_background"), 0);
		SetConVarInt(FindConVar("z_background_limit"), 30);
		SetConVarInt(FindConVar("z_common_limit"), 35);
		SetConVarInt(FindConVar("z_mob_spawn_min_size"), 18);
		SetConVarInt(FindConVar("z_mob_spawn_finale_size"), 36);
		SetConVarInt(FindConVar("z_mob_spawn_max_size"), 54);
		SetConVarInt(FindConVar("z_mega_mob_size"), 90);
		SetConVarInt(FindConVar("z_mob_spawn_min_interval_easy"), 65);
		SetConVarInt(FindConVar("z_mob_spawn_max_interval_easy"), 90);
	}
	else if (count == 6)
	{
		SetConVarInt(FindConVar("survivor_crawl_speed"), 30);
		SetConVarInt(FindConVar("survivor_revive_duration"), 6);
		SetConVarInt(FindConVar("survivor_revive_health"), 44);
		SetConVarInt(FindConVar("survivor_limp_health"), 35);
		SetConVarInt(FindConVar("first_aid_kit_use_duration"), 6);
		SetConVarInt(FindConVar("z_witch_health"), 1300);
		SetConVarInt(FindConVar("z_witch_burn_time"), 20);
		SetConVarInt(FindConVar("z_tank_speed"), 216);
		SetConVarInt(FindConVar("tongue_hit_delay"), 14);
		SetConVarInt(FindConVar("tongue_range"), 1550);
		SetConVarInt(FindConVar("tongue_victim_max_speed"), 195);
		SetConVarInt(FindConVar("z_vomit_interval"), 19);
		SetConVarInt(FindConVar("director_force_background"), 0);
		SetConVarInt(FindConVar("z_background_limit"), 31);
		SetConVarInt(FindConVar("z_common_limit"), 36);
		SetConVarInt(FindConVar("z_mob_spawn_min_size"), 20);
		SetConVarInt(FindConVar("z_mob_spawn_finale_size"), 40);
		SetConVarInt(FindConVar("z_mob_spawn_max_size"), 60);
		SetConVarInt(FindConVar("z_mega_mob_size"), 100);
		SetConVarInt(FindConVar("z_mob_spawn_min_interval_easy"), 65);
		SetConVarInt(FindConVar("z_mob_spawn_max_interval_easy"), 85);
	}
	else if (count == 7)
	{
		SetConVarInt(FindConVar("survivor_crawl_speed"), 35);
		SetConVarInt(FindConVar("survivor_revive_duration"), 6);
		SetConVarInt(FindConVar("survivor_revive_health"), 43);
		SetConVarInt(FindConVar("survivor_limp_health"), 35);
		SetConVarInt(FindConVar("first_aid_kit_use_duration"), 6);
		SetConVarInt(FindConVar("z_witch_health"), 1350);
		SetConVarInt(FindConVar("z_witch_burn_time"), 21);
		SetConVarInt(FindConVar("z_tank_speed"), 217);
		SetConVarInt(FindConVar("tongue_hit_delay"), 13);
		SetConVarInt(FindConVar("tongue_range"), 1700);
		SetConVarInt(FindConVar("tongue_victim_max_speed"), 195);
		SetConVarInt(FindConVar("z_vomit_interval"), 18);
		SetConVarInt(FindConVar("director_force_background"), 0);
		SetConVarInt(FindConVar("z_background_limit"), 32);
		SetConVarInt(FindConVar("z_common_limit"), 37);
		SetConVarInt(FindConVar("z_mob_spawn_min_size"), 22);
		SetConVarInt(FindConVar("z_mob_spawn_finale_size"), 44);
		SetConVarInt(FindConVar("z_mob_spawn_max_size"), 66);
		SetConVarInt(FindConVar("z_mega_mob_size"), 110);
		SetConVarInt(FindConVar("z_mob_spawn_min_interval_easy"), 65);
		SetConVarInt(FindConVar("z_mob_spawn_max_interval_easy"), 85);
	}
	else if (count == 8)
	{
		SetConVarInt(FindConVar("survivor_crawl_speed"), 40);
		SetConVarInt(FindConVar("survivor_revive_duration"), 6);
		SetConVarInt(FindConVar("survivor_revive_health"), 42);
		SetConVarInt(FindConVar("survivor_limp_health"), 35);
		SetConVarInt(FindConVar("first_aid_kit_use_duration"), 6);
		SetConVarInt(FindConVar("z_witch_health"), 1400);
		SetConVarInt(FindConVar("z_witch_burn_time"), 22);
		SetConVarInt(FindConVar("z_tank_speed"), 218);
		SetConVarInt(FindConVar("tongue_hit_delay"), 12);
		SetConVarInt(FindConVar("tongue_range"), 1850);
		SetConVarInt(FindConVar("tongue_victim_max_speed"), 195);
		SetConVarInt(FindConVar("z_vomit_interval"), 17);
		SetConVarInt(FindConVar("director_force_background"), 0);
		SetConVarInt(FindConVar("z_background_limit"), 33);
		SetConVarInt(FindConVar("z_common_limit"), 45);
		SetConVarInt(FindConVar("z_mob_spawn_min_size"), 24);
		SetConVarInt(FindConVar("z_mob_spawn_finale_size"), 48);
		SetConVarInt(FindConVar("z_mob_spawn_max_size"), 72);
		SetConVarInt(FindConVar("z_mega_mob_size"), 120);
		SetConVarInt(FindConVar("z_mob_spawn_min_interval_easy"), 60);
		SetConVarInt(FindConVar("z_mob_spawn_max_interval_easy"), 85);
	}
	else if (count == 9)
	{
		SetConVarInt(FindConVar("survivor_crawl_speed"), 40);
		SetConVarInt(FindConVar("survivor_revive_duration"), 6);
		SetConVarInt(FindConVar("survivor_revive_health"), 41);
		SetConVarInt(FindConVar("survivor_limp_health"), 35);
		SetConVarInt(FindConVar("first_aid_kit_use_duration"), 6);
		SetConVarInt(FindConVar("z_witch_health"), 1450);
		SetConVarInt(FindConVar("z_witch_burn_time"), 23);
		SetConVarInt(FindConVar("z_tank_speed"), 219);
		SetConVarInt(FindConVar("tongue_hit_delay"), 11);
		SetConVarInt(FindConVar("tongue_range"), 2000);
		SetConVarInt(FindConVar("tongue_victim_max_speed"), 195);
		SetConVarInt(FindConVar("z_vomit_interval"), 16);
		SetConVarInt(FindConVar("director_force_background"), 0);
		SetConVarInt(FindConVar("z_background_limit"), 34);
		SetConVarInt(FindConVar("z_common_limit"), 39);
		SetConVarInt(FindConVar("z_mob_spawn_min_size"), 26);
		SetConVarInt(FindConVar("z_mob_spawn_finale_size"), 52);
		SetConVarInt(FindConVar("z_mob_spawn_max_size"), 78);
		SetConVarInt(FindConVar("z_mega_mob_size"), 130);
		SetConVarInt(FindConVar("z_mob_spawn_min_interval_easy"), 60);
		SetConVarInt(FindConVar("z_mob_spawn_max_interval_easy"), 85);
	}
	else if (count == 10)
	{
		SetConVarInt(FindConVar("survivor_crawl_speed"), 40);
		SetConVarInt(FindConVar("survivor_revive_duration"), 7);
		SetConVarInt(FindConVar("survivor_revive_health"), 40);
		SetConVarInt(FindConVar("survivor_limp_health"), 35);
		SetConVarInt(FindConVar("first_aid_kit_use_duration"), 6);
		SetConVarInt(FindConVar("z_witch_health"), 1500);
		SetConVarInt(FindConVar("z_witch_burn_time"), 24);
		SetConVarInt(FindConVar("z_tank_speed"), 220);
		SetConVarInt(FindConVar("tongue_hit_delay"), 10);
		SetConVarInt(FindConVar("tongue_range"), 2500);
		SetConVarInt(FindConVar("tongue_victim_max_speed"), 195);
		SetConVarInt(FindConVar("z_vomit_interval"), 15);
		SetConVarInt(FindConVar("director_force_background"), 30);
		SetConVarInt(FindConVar("z_background_limit"), 5);
		SetConVarInt(FindConVar("z_common_limit"), 35);
		SetConVarInt(FindConVar("z_mob_spawn_min_size"), 28);
		SetConVarInt(FindConVar("z_mob_spawn_finale_size"), 56);
		SetConVarInt(FindConVar("z_mob_spawn_max_size"), 84);
		SetConVarInt(FindConVar("z_mega_mob_size"), 140);
		SetConVarInt(FindConVar("z_mob_spawn_min_interval_easy"), 60);
		SetConVarInt(FindConVar("z_mob_spawn_max_interval_easy"), 80);
	}
	return true;
}

SetDifficulty_Normal()
{
	new count = survivors;
	if (count == 1)
	{
		SetConVarInt(FindConVar("l4d_together_loner_punish"), 0);
		SetConVarInt(FindConVar("survivor_limp_health"), 35);
		SetConVarInt(FindConVar("first_aid_kit_use_duration"), 4);
		SetConVarInt(FindConVar("z_witch_health"), 1050);
		SetConVarInt(FindConVar("z_witch_burn_time"), 15);
		SetConVarInt(FindConVar("z_tank_speed"), 211);
		SetConVarInt(FindConVar("tongue_hit_delay"), 20);		SetConVarInt(FindConVar("tongue_range"), 800);
		SetConVarInt(FindConVar("z_vomit_interval"), 19);		SetConVarInt(FindConVar("director_force_background"), 0);		SetConVarInt(FindConVar("z_background_limit"), 26);
		SetConVarInt(FindConVar("z_common_limit"), 38);
		SetConVarInt(FindConVar("z_mob_spawn_min_size"), 10);
		SetConVarInt(FindConVar("z_mob_spawn_finale_size"), 20);
		SetConVarInt(FindConVar("z_mob_spawn_max_size"), 30);
		SetConVarInt(FindConVar("z_mega_mob_size"), 50);
		SetConVarInt(FindConVar("z_mob_spawn_min_interval_normal"), 50);
		SetConVarInt(FindConVar("z_mob_spawn_max_interval_normal"), 80);
	}
	else if (count == 2)
	{
		SetConVarInt(FindConVar("l4d_together_loner_punish"), 1);
		SetConVarInt(FindConVar("survivor_crawl_speed"), 15);
		SetConVarInt(FindConVar("survivor_revive_duration"), 4);
		SetConVarInt(FindConVar("survivor_revive_health"), 48);
		SetConVarInt(FindConVar("survivor_limp_health"), 35);
		SetConVarInt(FindConVar("first_aid_kit_use_duration"), 4);
		SetConVarInt(FindConVar("z_witch_health"), 1100);
		SetConVarInt(FindConVar("z_witch_burn_time"), 16);
		SetConVarInt(FindConVar("z_tank_speed"), 212);
		SetConVarInt(FindConVar("tongue_hit_delay"), 18);
		SetConVarInt(FindConVar("tongue_range"), 950);
		SetConVarInt(FindConVar("tongue_victim_max_speed"), 175);
		SetConVarInt(FindConVar("z_vomit_interval"), 18);
		SetConVarInt(FindConVar("director_force_background"), 0);
		SetConVarInt(FindConVar("z_background_limit"), 27);
		SetConVarInt(FindConVar("z_common_limit"), 39);
		SetConVarInt(FindConVar("z_mob_spawn_min_size"), 12);
		SetConVarInt(FindConVar("z_mob_spawn_finale_size"), 24);
		SetConVarInt(FindConVar("z_mob_spawn_max_size"), 36);
		SetConVarInt(FindConVar("z_mega_mob_size"), 60);
		SetConVarInt(FindConVar("z_mob_spawn_min_interval_normal"), 50);
		SetConVarInt(FindConVar("z_mob_spawn_max_interval_normal"), 75);
	}
	else if (count == 3)
	{
		SetConVarInt(FindConVar("l4d_together_loner_punish"), 1);
		SetConVarInt(FindConVar("survivor_crawl_speed"), 15);
		SetConVarInt(FindConVar("survivor_revive_duration"), 4);
		SetConVarInt(FindConVar("survivor_revive_health"), 47);
		SetConVarInt(FindConVar("survivor_limp_health"), 36);
		SetConVarInt(FindConVar("first_aid_kit_use_duration"), 4);
		SetConVarInt(FindConVar("z_witch_health"), 1150);
		SetConVarInt(FindConVar("z_witch_burn_time"), 17);
		SetConVarInt(FindConVar("z_tank_speed"), 213);
		SetConVarInt(FindConVar("tongue_hit_delay"), 17);
		SetConVarInt(FindConVar("tongue_range"), 1050);
		SetConVarInt(FindConVar("tongue_victim_max_speed"), 178);
		SetConVarInt(FindConVar("z_vomit_interval"), 17);
		SetConVarInt(FindConVar("director_force_background"), 0);
		SetConVarInt(FindConVar("z_background_limit"), 28);
		SetConVarInt(FindConVar("z_common_limit"), 40);
		SetConVarInt(FindConVar("z_mob_spawn_min_size"), 14);
		SetConVarInt(FindConVar("z_mob_spawn_finale_size"), 28);
		SetConVarInt(FindConVar("z_mob_spawn_max_size"), 42);
		SetConVarInt(FindConVar("z_mega_mob_size"), 70);
		SetConVarInt(FindConVar("z_mob_spawn_min_interval_normal"), 45);
		SetConVarInt(FindConVar("z_mob_spawn_max_interval_normal"), 75);
	}
	else if (count == 4)
	{
		SetConVarInt(FindConVar("l4d_together_loner_punish"), 1);
		SetConVarInt(FindConVar("survivor_crawl_speed"), 20);
		SetConVarInt(FindConVar("survivor_revive_duration"), 5);
		SetConVarInt(FindConVar("survivor_revive_health"), 46);
		SetConVarInt(FindConVar("survivor_limp_health"), 36);
		SetConVarInt(FindConVar("first_aid_kit_use_duration"), 5);
		SetConVarInt(FindConVar("z_witch_health"), 1200);
		SetConVarInt(FindConVar("z_witch_burn_time"), 18);
		SetConVarInt(FindConVar("z_tank_speed"), 214);
		SetConVarInt(FindConVar("tongue_hit_delay"), 16);
		SetConVarInt(FindConVar("tongue_range"), 1200);
		SetConVarInt(FindConVar("tongue_victim_max_speed"), 181);
		SetConVarInt(FindConVar("z_vomit_interval"), 16);
		SetConVarInt(FindConVar("director_force_background"), 0);
		SetConVarInt(FindConVar("z_background_limit"), 29);
		SetConVarInt(FindConVar("z_common_limit"), 41);
		SetConVarInt(FindConVar("z_mob_spawn_min_size"), 16);
		SetConVarInt(FindConVar("z_mob_spawn_finale_size"), 32);
		SetConVarInt(FindConVar("z_mob_spawn_max_size"), 48);
		SetConVarInt(FindConVar("z_mega_mob_size"), 80);
		SetConVarInt(FindConVar("z_mob_spawn_min_interval_normal"), 45);
		SetConVarInt(FindConVar("z_mob_spawn_max_interval_normal"), 70);
	}
	else if (count == 5)
	{
		SetConVarInt(FindConVar("l4d_together_loner_punish"), 1);
		SetConVarInt(FindConVar("survivor_crawl_speed"), 25);
		SetConVarInt(FindConVar("survivor_revive_duration"), 5);
		SetConVarInt(FindConVar("survivor_revive_health"), 45);
		SetConVarInt(FindConVar("survivor_limp_health"), 37);
		SetConVarInt(FindConVar("first_aid_kit_use_duration"), 5);
		SetConVarInt(FindConVar("z_witch_health"), 1250);
		SetConVarInt(FindConVar("z_witch_burn_time"), 19);
		SetConVarInt(FindConVar("z_tank_speed"), 215);
		SetConVarInt(FindConVar("tongue_hit_delay"), 15);
		SetConVarInt(FindConVar("tongue_range"), 1400);
		SetConVarInt(FindConVar("tongue_victim_max_speed"), 184);
		SetConVarInt(FindConVar("z_vomit_interval"), 15);
		SetConVarInt(FindConVar("director_force_background"), 0);
		SetConVarInt(FindConVar("z_background_limit"), 30);
		SetConVarInt(FindConVar("z_common_limit"), 42);
		SetConVarInt(FindConVar("z_mob_spawn_min_size"), 18);
		SetConVarInt(FindConVar("z_mob_spawn_finale_size"), 36);
		SetConVarInt(FindConVar("z_mob_spawn_max_size"), 54);
		SetConVarInt(FindConVar("z_mega_mob_size"), 90);
		SetConVarInt(FindConVar("z_mob_spawn_min_interval_normal"), 40);
		SetConVarInt(FindConVar("z_mob_spawn_max_interval_normal"), 70);
	}
	else if (count == 6)
	{
		SetConVarInt(FindConVar("l4d_together_loner_punish"), 1);
		SetConVarInt(FindConVar("survivor_crawl_speed"), 30);
		SetConVarInt(FindConVar("survivor_revive_duration"), 6);
		SetConVarInt(FindConVar("survivor_revive_health"), 44);
		SetConVarInt(FindConVar("survivor_limp_health"), 37);
		SetConVarInt(FindConVar("first_aid_kit_use_duration"), 6);
		SetConVarInt(FindConVar("z_witch_health"), 1300);
		SetConVarInt(FindConVar("z_witch_burn_time"), 20);
		SetConVarInt(FindConVar("z_tank_speed"), 216);
		SetConVarInt(FindConVar("tongue_hit_delay"), 14);
		SetConVarInt(FindConVar("tongue_range"), 1600);
		SetConVarInt(FindConVar("tongue_victim_max_speed"), 187);
		SetConVarInt(FindConVar("z_vomit_interval"), 14);
		SetConVarInt(FindConVar("director_force_background"), 0);
		SetConVarInt(FindConVar("z_background_limit"), 31);
		SetConVarInt(FindConVar("z_common_limit"), 43);
		SetConVarInt(FindConVar("z_mob_spawn_min_size"), 20);
		SetConVarInt(FindConVar("z_mob_spawn_finale_size"), 40);
		SetConVarInt(FindConVar("z_mob_spawn_max_size"), 60);
		SetConVarInt(FindConVar("z_mega_mob_size"), 100);
		SetConVarInt(FindConVar("z_mob_spawn_min_interval_normal"), 40);
		SetConVarInt(FindConVar("z_mob_spawn_max_interval_normal"), 65);
	}
	else if (count == 7)
	{
		SetConVarInt(FindConVar("l4d_together_loner_punish"), 1);
		SetConVarInt(FindConVar("survivor_crawl_speed"), 35);
		SetConVarInt(FindConVar("survivor_revive_duration"), 6);
		SetConVarInt(FindConVar("survivor_revive_health"), 43);
		SetConVarInt(FindConVar("survivor_limp_health"), 38);
		SetConVarInt(FindConVar("first_aid_kit_use_duration"), 6);
		SetConVarInt(FindConVar("z_witch_health"), 1350);
		SetConVarInt(FindConVar("z_witch_burn_time"), 21);
		SetConVarInt(FindConVar("z_tank_speed"), 217);
		SetConVarInt(FindConVar("tongue_hit_delay"), 13);
		SetConVarInt(FindConVar("tongue_range"), 1800);
		SetConVarInt(FindConVar("tongue_victim_max_speed"), 190);
		SetConVarInt(FindConVar("z_vomit_interval"), 13);
		SetConVarInt(FindConVar("director_force_background"), 0);
		SetConVarInt(FindConVar("z_background_limit"), 32);
		SetConVarInt(FindConVar("z_common_limit"), 44);
		SetConVarInt(FindConVar("z_mob_spawn_min_size"), 22);
		SetConVarInt(FindConVar("z_mob_spawn_finale_size"), 44);
		SetConVarInt(FindConVar("z_mob_spawn_max_size"), 66);
		SetConVarInt(FindConVar("z_mega_mob_size"), 110);
		SetConVarInt(FindConVar("z_mob_spawn_min_interval_normal"), 35);
		SetConVarInt(FindConVar("z_mob_spawn_max_interval_normal"), 65);
	}
	else if (count == 8)
	{
		SetConVarInt(FindConVar("l4d_together_loner_punish"), 1);
		SetConVarInt(FindConVar("survivor_crawl_speed"), 40);
		SetConVarInt(FindConVar("survivor_revive_duration"), 7);
		SetConVarInt(FindConVar("survivor_revive_health"), 42);
		SetConVarInt(FindConVar("survivor_limp_health"), 38);
		SetConVarInt(FindConVar("first_aid_kit_use_duration"), 7);
		SetConVarInt(FindConVar("z_witch_health"), 1400);
		SetConVarInt(FindConVar("z_witch_burn_time"), 22);
		SetConVarInt(FindConVar("z_tank_speed"), 218);
		SetConVarInt(FindConVar("tongue_hit_delay"), 12);
		SetConVarInt(FindConVar("tongue_range"), 2000);
		SetConVarInt(FindConVar("tongue_victim_max_speed"), 193);
		SetConVarInt(FindConVar("z_vomit_interval"), 12);
		SetConVarInt(FindConVar("director_force_background"), 0);
		SetConVarInt(FindConVar("z_background_limit"), 33);
		SetConVarInt(FindConVar("z_common_limit"), 45);
		SetConVarInt(FindConVar("z_mob_spawn_min_size"), 24);
		SetConVarInt(FindConVar("z_mob_spawn_finale_size"), 48);
		SetConVarInt(FindConVar("z_mob_spawn_max_size"), 72);
		SetConVarInt(FindConVar("z_mega_mob_size"), 120);
		SetConVarInt(FindConVar("z_mob_spawn_min_interval_normal"), 35);
		SetConVarInt(FindConVar("z_mob_spawn_max_interval_normal"), 60);
	}
	else if (count == 9)
	{
		SetConVarInt(FindConVar("l4d_together_loner_punish"), 1);
		SetConVarInt(FindConVar("survivor_crawl_speed"), 40);
		SetConVarInt(FindConVar("survivor_revive_duration"), 7);
		SetConVarInt(FindConVar("survivor_revive_health"), 41);
		SetConVarInt(FindConVar("survivor_limp_health"), 39);
		SetConVarInt(FindConVar("first_aid_kit_use_duration"), 7);
		SetConVarInt(FindConVar("z_witch_health"), 1450);
		SetConVarInt(FindConVar("z_witch_burn_time"), 23);
		SetConVarInt(FindConVar("z_tank_speed"), 219);
		SetConVarInt(FindConVar("tongue_hit_delay"), 11);
		SetConVarInt(FindConVar("tongue_range"), 2200);
		SetConVarInt(FindConVar("tongue_victim_max_speed"), 196);
		SetConVarInt(FindConVar("z_vomit_interval"), 11);
		SetConVarInt(FindConVar("director_force_background"), 40);
		SetConVarInt(FindConVar("z_background_limit"), 5);
		SetConVarInt(FindConVar("z_common_limit"), 45);
		SetConVarInt(FindConVar("z_mob_spawn_min_size"), 26);
		SetConVarInt(FindConVar("z_mob_spawn_finale_size"), 52);
		SetConVarInt(FindConVar("z_mob_spawn_max_size"), 78);
		SetConVarInt(FindConVar("z_mega_mob_size"), 130);
		SetConVarInt(FindConVar("z_mob_spawn_min_interval_normal"), 30);
		SetConVarInt(FindConVar("z_mob_spawn_max_interval_normal"), 60);
	}
	else if (count == 10)
	{
		SetConVarInt(FindConVar("l4d_together_loner_punish"), 1);
		SetConVarInt(FindConVar("survivor_crawl_speed"), 40);
		SetConVarInt(FindConVar("survivor_revive_duration"), 7);
		SetConVarInt(FindConVar("survivor_revive_health"), 40);
		SetConVarInt(FindConVar("survivor_limp_health"), 40);
		SetConVarInt(FindConVar("first_aid_kit_use_duration"), 7);
		SetConVarInt(FindConVar("z_witch_health"), 1500);
		SetConVarInt(FindConVar("z_witch_burn_time"), 24);
		SetConVarInt(FindConVar("z_tank_speed"), 220);
		SetConVarInt(FindConVar("tongue_hit_delay"), 10);
		SetConVarInt(FindConVar("tongue_range"), 2400);
		SetConVarInt(FindConVar("tongue_victim_max_speed"), 199);
		SetConVarInt(FindConVar("z_vomit_interval"), 10);
		SetConVarInt(FindConVar("director_force_background"), 40);
		SetConVarInt(FindConVar("z_background_limit"), 5);
		SetConVarInt(FindConVar("z_common_limit"), 45);
		SetConVarInt(FindConVar("z_mob_spawn_min_size"), 28);
		SetConVarInt(FindConVar("z_mob_spawn_finale_size"), 56);
		SetConVarInt(FindConVar("z_mob_spawn_max_size"), 84);
		SetConVarInt(FindConVar("z_mega_mob_size"), 140);
		SetConVarInt(FindConVar("z_mob_spawn_min_interval_normal"), 30);
		SetConVarInt(FindConVar("z_mob_spawn_max_interval_normal"), 55);
	}
	return true;
}

SetDifficulty_Hard()
{
	new count = survivors;
	if (count == 1)
	{
		SetConVarInt(FindConVar("l4d_together_loner_punish"), 0);
		SetConVarInt(FindConVar("survivor_limp_health"), 31);
		SetConVarInt(FindConVar("first_aid_kit_use_duration"), 4);
		SetConVarInt(FindConVar("z_witch_health"), 1050);
		SetConVarInt(FindConVar("z_witch_burn_time"), 15);
		SetConVarInt(FindConVar("z_tank_speed"), 211);
		SetConVarInt(FindConVar("tongue_hit_delay"), 20);
		SetConVarInt(FindConVar("tongue_range"), 900);
		SetConVarInt(FindConVar("z_vomit_interval"), 19);
		SetConVarInt(FindConVar("director_force_background"), 0);
		SetConVarInt(FindConVar("z_background_limit"), 26);
		SetConVarInt(FindConVar("z_common_limit"), 38);
		SetConVarInt(FindConVar("z_mob_spawn_min_size"), 10);
		SetConVarInt(FindConVar("z_mob_spawn_finale_size"), 20);
		SetConVarInt(FindConVar("z_mob_spawn_max_size"), 30);
		SetConVarInt(FindConVar("z_mega_mob_size"), 50);
		SetConVarInt(FindConVar("z_mob_spawn_min_interval_hard"), 40);
		SetConVarInt(FindConVar("z_mob_spawn_max_interval_hard"), 65);
	}
	else if (count == 2)
	{
		SetConVarInt(FindConVar("l4d_together_loner_punish"), 1);
		SetConVarInt(FindConVar("survivor_crawl_speed"), 15);
		SetConVarInt(FindConVar("survivor_revive_duration"), 4);
		SetConVarInt(FindConVar("survivor_revive_health"), 48);
		SetConVarInt(FindConVar("survivor_limp_health"), 32);
		SetConVarInt(FindConVar("first_aid_kit_use_duration"), 4);
		SetConVarInt(FindConVar("z_witch_health"), 1100);
		SetConVarInt(FindConVar("z_witch_burn_time"), 16);
		SetConVarInt(FindConVar("z_tank_speed"), 212);
		SetConVarInt(FindConVar("tongue_hit_delay"), 18);
		SetConVarInt(FindConVar("tongue_range"), 1100);
		SetConVarInt(FindConVar("tongue_victim_max_speed"), 175);
		SetConVarInt(FindConVar("z_vomit_interval"), 18);
		SetConVarInt(FindConVar("director_force_background"), 0);
		SetConVarInt(FindConVar("z_background_limit"), 27);
		SetConVarInt(FindConVar("z_common_limit"), 39);
		SetConVarInt(FindConVar("z_mob_spawn_min_size"), 12);
		SetConVarInt(FindConVar("z_mob_spawn_finale_size"), 24);
		SetConVarInt(FindConVar("z_mob_spawn_max_size"), 36);
		SetConVarInt(FindConVar("z_mega_mob_size"), 60);
		SetConVarInt(FindConVar("z_mob_spawn_min_interval_hard"), 40);
		SetConVarInt(FindConVar("z_mob_spawn_max_interval_hard"), 60);
	}
	else if (count == 3)
	{
		SetConVarInt(FindConVar("l4d_together_loner_punish"), 1);
		SetConVarInt(FindConVar("survivor_crawl_speed"), 15);
		SetConVarInt(FindConVar("survivor_revive_duration"), 4);
		SetConVarInt(FindConVar("survivor_revive_health"), 47);
		SetConVarInt(FindConVar("survivor_limp_health"), 33);
		SetConVarInt(FindConVar("first_aid_kit_use_duration"), 4);
		SetConVarInt(FindConVar("z_witch_health"), 1150);
		SetConVarInt(FindConVar("z_witch_burn_time"), 17);
		SetConVarInt(FindConVar("z_tank_speed"), 213);
		SetConVarInt(FindConVar("tongue_hit_delay"), 17);
		SetConVarInt(FindConVar("tongue_range"), 1350);
		SetConVarInt(FindConVar("tongue_victim_max_speed"), 178);
		SetConVarInt(FindConVar("z_vomit_interval"), 17);
		SetConVarInt(FindConVar("director_force_background"), 0);
		SetConVarInt(FindConVar("z_background_limit"), 28);
		SetConVarInt(FindConVar("z_common_limit"), 40);
		SetConVarInt(FindConVar("z_mob_spawn_min_size"), 14);
		SetConVarInt(FindConVar("z_mob_spawn_finale_size"), 28);
		SetConVarInt(FindConVar("z_mob_spawn_max_size"), 42);
		SetConVarInt(FindConVar("z_mega_mob_size"), 70);
		SetConVarInt(FindConVar("z_mob_spawn_min_interval_hard"), 35);
		SetConVarInt(FindConVar("z_mob_spawn_max_interval_hard"), 60);
	}
	else if (count == 4)
	{
		SetConVarInt(FindConVar("l4d_together_loner_punish"), 1);
		SetConVarInt(FindConVar("survivor_crawl_speed"), 20);
		SetConVarInt(FindConVar("survivor_revive_duration"), 5);
		SetConVarInt(FindConVar("survivor_revive_health"), 46);
		SetConVarInt(FindConVar("survivor_limp_health"), 34);
		SetConVarInt(FindConVar("first_aid_kit_use_duration"), 5);
		SetConVarInt(FindConVar("z_witch_health"), 1200);
		SetConVarInt(FindConVar("z_witch_burn_time"), 18);
		SetConVarInt(FindConVar("z_tank_speed"), 214);
		SetConVarInt(FindConVar("tongue_hit_delay"), 16);
		SetConVarInt(FindConVar("tongue_range"), 1500);
		SetConVarInt(FindConVar("tongue_victim_max_speed"), 181);
		SetConVarInt(FindConVar("z_vomit_interval"), 16);
		SetConVarInt(FindConVar("director_force_background"), 0);
		SetConVarInt(FindConVar("z_background_limit"), 29);
		SetConVarInt(FindConVar("z_common_limit"), 41);
		SetConVarInt(FindConVar("z_mob_spawn_min_size"), 16);
		SetConVarInt(FindConVar("z_mob_spawn_finale_size"), 32);
		SetConVarInt(FindConVar("z_mob_spawn_max_size"), 48);
		SetConVarInt(FindConVar("z_mega_mob_size"), 80);
		SetConVarInt(FindConVar("z_mob_spawn_min_interval_hard"), 35);
		SetConVarInt(FindConVar("z_mob_spawn_max_interval_hard"), 55);
	}
	else if (count == 5)
	{
		SetConVarInt(FindConVar("l4d_together_loner_punish"), 1);
		SetConVarInt(FindConVar("survivor_crawl_speed"), 25);
		SetConVarInt(FindConVar("survivor_revive_duration"), 5);
		SetConVarInt(FindConVar("survivor_revive_health"), 45);
		SetConVarInt(FindConVar("survivor_limp_health"), 35);
		SetConVarInt(FindConVar("first_aid_kit_use_duration"), 5);
		SetConVarInt(FindConVar("z_witch_health"), 1250);
		SetConVarInt(FindConVar("z_witch_burn_time"), 19);
		SetConVarInt(FindConVar("z_tank_speed"), 215);
		SetConVarInt(FindConVar("tongue_hit_delay"), 15);
		SetConVarInt(FindConVar("tongue_range"), 1750);
		SetConVarInt(FindConVar("tongue_victim_max_speed"), 184);
		SetConVarInt(FindConVar("z_vomit_interval"), 15);
		SetConVarInt(FindConVar("director_force_background"), 0);
		SetConVarInt(FindConVar("z_background_limit"), 30);
		SetConVarInt(FindConVar("z_common_limit"), 42);
		SetConVarInt(FindConVar("z_mob_spawn_min_size"), 18);
		SetConVarInt(FindConVar("z_mob_spawn_finale_size"), 36);
		SetConVarInt(FindConVar("z_mob_spawn_max_size"), 54);
		SetConVarInt(FindConVar("z_mega_mob_size"), 90);
		SetConVarInt(FindConVar("z_mob_spawn_min_interval_hard"), 30);
		SetConVarInt(FindConVar("z_mob_spawn_max_interval_hard"), 55);
	}
	else if (count == 6)
	{
		SetConVarInt(FindConVar("l4d_together_loner_punish"), 1);
		SetConVarInt(FindConVar("survivor_crawl_speed"), 30);
		SetConVarInt(FindConVar("survivor_revive_duration"), 6);
		SetConVarInt(FindConVar("survivor_revive_health"), 44);
		SetConVarInt(FindConVar("survivor_limp_health"), 36);
		SetConVarInt(FindConVar("first_aid_kit_use_duration"), 6);
		SetConVarInt(FindConVar("z_witch_health"), 1300);
		SetConVarInt(FindConVar("z_witch_burn_time"), 20);
		SetConVarInt(FindConVar("z_tank_speed"), 216);
		SetConVarInt(FindConVar("tongue_hit_delay"), 14);
		SetConVarInt(FindConVar("tongue_range"), 2000);
		SetConVarInt(FindConVar("tongue_victim_max_speed"), 187);
		SetConVarInt(FindConVar("z_vomit_interval"), 14);
		SetConVarInt(FindConVar("director_force_background"), 0);
		SetConVarInt(FindConVar("z_background_limit"), 31);
		SetConVarInt(FindConVar("z_common_limit"), 43);
		SetConVarInt(FindConVar("z_mob_spawn_min_size"), 20);
		SetConVarInt(FindConVar("z_mob_spawn_finale_size"), 40);
		SetConVarInt(FindConVar("z_mob_spawn_max_size"), 60);
		SetConVarInt(FindConVar("z_mega_mob_size"), 100);
		SetConVarInt(FindConVar("z_mob_spawn_min_interval_hard"), 30);
		SetConVarInt(FindConVar("z_mob_spawn_max_interval_hard"), 50);
	}
	else if (count == 7)
	{
		SetConVarInt(FindConVar("l4d_together_loner_punish"), 1);
		SetConVarInt(FindConVar("survivor_crawl_speed"), 35);
		SetConVarInt(FindConVar("survivor_revive_duration"), 6);
		SetConVarInt(FindConVar("survivor_revive_health"), 43);
		SetConVarInt(FindConVar("survivor_limp_health"), 37);
		SetConVarInt(FindConVar("first_aid_kit_use_duration"), 6);
		SetConVarInt(FindConVar("z_witch_health"), 1350);
		SetConVarInt(FindConVar("z_witch_burn_time"), 21);
		SetConVarInt(FindConVar("z_tank_speed"), 217);
		SetConVarInt(FindConVar("tongue_hit_delay"), 13);
		SetConVarInt(FindConVar("tongue_range"), 2250);
		SetConVarInt(FindConVar("tongue_victim_max_speed"), 190);
		SetConVarInt(FindConVar("z_vomit_interval"), 13);
		SetConVarInt(FindConVar("director_force_background"), 0);
		SetConVarInt(FindConVar("z_background_limit"), 32);
		SetConVarInt(FindConVar("z_common_limit"), 44);
		SetConVarInt(FindConVar("z_mob_spawn_min_size"), 22);
		SetConVarInt(FindConVar("z_mob_spawn_finale_size"), 44);
		SetConVarInt(FindConVar("z_mob_spawn_max_size"), 66);
		SetConVarInt(FindConVar("z_mega_mob_size"), 110);
		SetConVarInt(FindConVar("z_mob_spawn_min_interval_hard"), 25);
		SetConVarInt(FindConVar("z_mob_spawn_max_interval_hard"), 50);
	}
	else if (count == 8)
	{
		SetConVarInt(FindConVar("l4d_together_loner_punish"), 1);
		SetConVarInt(FindConVar("survivor_crawl_speed"), 40);
		SetConVarInt(FindConVar("survivor_revive_duration"), 7);
		SetConVarInt(FindConVar("survivor_revive_health"), 42);
		SetConVarInt(FindConVar("survivor_limp_health"), 38);
		SetConVarInt(FindConVar("first_aid_kit_use_duration"), 7);
		SetConVarInt(FindConVar("z_witch_health"), 1400);
		SetConVarInt(FindConVar("z_witch_burn_time"), 22);
		SetConVarInt(FindConVar("z_tank_speed"), 218);
		SetConVarInt(FindConVar("tongue_hit_delay"), 12);
		SetConVarInt(FindConVar("tongue_range"), 2500);
		SetConVarInt(FindConVar("tongue_victim_max_speed"), 193);
		SetConVarInt(FindConVar("z_vomit_interval"), 12);
		SetConVarInt(FindConVar("director_force_background"), 0);
		SetConVarInt(FindConVar("z_background_limit"), 33);
		SetConVarInt(FindConVar("z_common_limit"), 45);
		SetConVarInt(FindConVar("z_mob_spawn_min_size"), 24);
		SetConVarInt(FindConVar("z_mob_spawn_finale_size"), 48);
		SetConVarInt(FindConVar("z_mob_spawn_max_size"), 72);
		SetConVarInt(FindConVar("z_mega_mob_size"), 120);
		SetConVarInt(FindConVar("z_mob_spawn_min_interval_hard"), 25);
		SetConVarInt(FindConVar("z_mob_spawn_max_interval_hard"), 45);
	}
	else if (count == 9)
	{
		SetConVarInt(FindConVar("l4d_together_loner_punish"), 1);
		SetConVarInt(FindConVar("survivor_crawl_speed"), 40);
		SetConVarInt(FindConVar("survivor_revive_duration"), 7);
		SetConVarInt(FindConVar("survivor_revive_health"), 41);
		SetConVarInt(FindConVar("survivor_limp_health"), 39);
		SetConVarInt(FindConVar("first_aid_kit_use_duration"), 7);
		SetConVarInt(FindConVar("z_witch_health"), 1450);
		SetConVarInt(FindConVar("z_witch_burn_time"), 23);
		SetConVarInt(FindConVar("z_tank_speed"), 219);
		SetConVarInt(FindConVar("tongue_hit_delay"), 11);
		SetConVarInt(FindConVar("tongue_range"), 2800);
		SetConVarInt(FindConVar("tongue_victim_max_speed"), 196);
		SetConVarInt(FindConVar("z_vomit_interval"), 11);
		SetConVarInt(FindConVar("director_force_background"), 40);
		SetConVarInt(FindConVar("z_background_limit"), 5);
		SetConVarInt(FindConVar("z_common_limit"), 45);
		SetConVarInt(FindConVar("z_mob_spawn_min_size"), 26);
		SetConVarInt(FindConVar("z_mob_spawn_finale_size"), 52);
		SetConVarInt(FindConVar("z_mob_spawn_max_size"), 78);
		SetConVarInt(FindConVar("z_mega_mob_size"), 130);
		SetConVarInt(FindConVar("z_mob_spawn_min_interval_hard"), 20);
		SetConVarInt(FindConVar("z_mob_spawn_max_interval_hard"), 45);
	}
	else if (count == 10)
	{
		SetConVarInt(FindConVar("l4d_together_loner_punish"), 1);
		SetConVarInt(FindConVar("survivor_crawl_speed"), 40);
		SetConVarInt(FindConVar("survivor_revive_duration"), 7);
		SetConVarInt(FindConVar("survivor_revive_health"), 40);
		SetConVarInt(FindConVar("survivor_limp_health"), 40);
		SetConVarInt(FindConVar("first_aid_kit_use_duration"), 7);
		SetConVarInt(FindConVar("z_witch_health"), 1500);
		SetConVarInt(FindConVar("z_witch_burn_time"), 24);
		SetConVarInt(FindConVar("z_tank_speed"), 220);
		SetConVarInt(FindConVar("tongue_hit_delay"), 10);
		SetConVarInt(FindConVar("tongue_range"), 3100);
		SetConVarInt(FindConVar("tongue_victim_max_speed"), 199);
		SetConVarInt(FindConVar("z_vomit_interval"), 10);
		SetConVarInt(FindConVar("director_force_background"), 40);
		SetConVarInt(FindConVar("z_background_limit"), 5);
		SetConVarInt(FindConVar("z_common_limit"), 45);
		SetConVarInt(FindConVar("z_mob_spawn_min_size"), 28);
		SetConVarInt(FindConVar("z_mob_spawn_finale_size"), 56);
		SetConVarInt(FindConVar("z_mob_spawn_max_size"), 84);
		SetConVarInt(FindConVar("z_mega_mob_size"), 140);
		SetConVarInt(FindConVar("z_mob_spawn_min_interval_hard"), 20);
		SetConVarInt(FindConVar("z_mob_spawn_max_interval_hard"), 40);
	}
	return true;
}

SetDifficulty_Impossible()
{
	new count = survivors;
	if (count == 1)
	{
		SetConVarInt(FindConVar("l4d_together_loner_punish"), 0);
		SetConVarInt(FindConVar("survivor_limp_health"), 35);
		SetConVarInt(FindConVar("first_aid_kit_use_duration"), 4);
		SetConVarInt(FindConVar("z_witch_health"), 1050);
		SetConVarInt(FindConVar("z_witch_burn_time"), 15);
		SetConVarInt(FindConVar("z_tank_speed"), 211);
		SetConVarInt(FindConVar("tongue_hit_delay"), 20);
		SetConVarInt(FindConVar("tongue_range"), 1000);
		SetConVarInt(FindConVar("z_vomit_interval"), 19);
		SetConVarInt(FindConVar("director_force_background"), 0);
		SetConVarInt(FindConVar("z_background_limit"), 26);
		SetConVarInt(FindConVar("z_common_limit"), 38);
		SetConVarInt(FindConVar("z_mob_spawn_min_size"), 10);
		SetConVarInt(FindConVar("z_mob_spawn_finale_size"), 20);
		SetConVarInt(FindConVar("z_mob_spawn_max_size"), 30);
		SetConVarInt(FindConVar("z_mega_mob_size"), 50);
		SetConVarInt(FindConVar("z_mob_spawn_min_interval_expert"), 35);
		SetConVarInt(FindConVar("z_mob_spawn_max_interval_expert"), 60);
	}
	else if (count == 2)
	{
		SetConVarInt(FindConVar("l4d_together_loner_punish"), 1);
		SetConVarInt(FindConVar("survivor_crawl_speed"), 15);
		SetConVarInt(FindConVar("survivor_revive_duration"), 4);
		SetConVarInt(FindConVar("survivor_revive_health"), 41);
		SetConVarInt(FindConVar("survivor_limp_health"), 39);
		SetConVarInt(FindConVar("first_aid_kit_use_duration"), 4);
		SetConVarInt(FindConVar("z_witch_health"), 1100);
		SetConVarInt(FindConVar("z_witch_burn_time"), 16);
		SetConVarInt(FindConVar("z_tank_speed"), 212);
		SetConVarInt(FindConVar("tongue_hit_delay"), 18);
		SetConVarInt(FindConVar("tongue_range"), 1300);
		SetConVarInt(FindConVar("tongue_victim_max_speed"), 175);
		SetConVarInt(FindConVar("z_vomit_interval"), 18);
		SetConVarInt(FindConVar("director_force_background"), 0);
		SetConVarInt(FindConVar("z_background_limit"), 27);
		SetConVarInt(FindConVar("z_common_limit"), 39);
		SetConVarInt(FindConVar("z_mob_spawn_min_size"), 12);
		SetConVarInt(FindConVar("z_mob_spawn_finale_size"), 24);
		SetConVarInt(FindConVar("z_mob_spawn_max_size"), 36);
		SetConVarInt(FindConVar("z_mega_mob_size"), 60);
		SetConVarInt(FindConVar("z_mob_spawn_min_interval_expert"), 35);
		SetConVarInt(FindConVar("z_mob_spawn_max_interval_expert"), 55);
	}
	else if (count == 3)
	{
		SetConVarInt(FindConVar("l4d_together_loner_punish"), 1);
		SetConVarInt(FindConVar("survivor_crawl_speed"), 15);
		SetConVarInt(FindConVar("survivor_revive_duration"), 4);
		SetConVarInt(FindConVar("survivor_revive_health"), 43);
		SetConVarInt(FindConVar("survivor_limp_health"), 38);
		SetConVarInt(FindConVar("first_aid_kit_use_duration"), 4);
		SetConVarInt(FindConVar("z_witch_health"), 1150);
		SetConVarInt(FindConVar("z_witch_burn_time"), 17);
		SetConVarInt(FindConVar("z_tank_speed"), 213);
		SetConVarInt(FindConVar("tongue_hit_delay"), 17);
		SetConVarInt(FindConVar("tongue_range"), 1600);
		SetConVarInt(FindConVar("tongue_victim_max_speed"), 178);
		SetConVarInt(FindConVar("z_vomit_interval"), 17);
		SetConVarInt(FindConVar("director_force_background"), 0);
		SetConVarInt(FindConVar("z_background_limit"), 28);
		SetConVarInt(FindConVar("z_common_limit"), 40);
		SetConVarInt(FindConVar("z_mob_spawn_min_size"), 14);
		SetConVarInt(FindConVar("z_mob_spawn_finale_size"), 28);
		SetConVarInt(FindConVar("z_mob_spawn_max_size"), 42);
		SetConVarInt(FindConVar("z_mega_mob_size"), 70);
		SetConVarInt(FindConVar("z_mob_spawn_min_interval_expert"), 30);
		SetConVarInt(FindConVar("z_mob_spawn_max_interval_expert"), 55);
	}
	else if (count == 4)
	{
		SetConVarInt(FindConVar("l4d_together_loner_punish"), 1);
		SetConVarInt(FindConVar("survivor_crawl_speed"), 20);
		SetConVarInt(FindConVar("survivor_revive_duration"), 5);
		SetConVarInt(FindConVar("survivor_revive_health"), 44);
		SetConVarInt(FindConVar("survivor_limp_health"), 37);
		SetConVarInt(FindConVar("first_aid_kit_use_duration"), 5);
		SetConVarInt(FindConVar("z_witch_health"), 1200);
		SetConVarInt(FindConVar("z_witch_burn_time"), 18);
		SetConVarInt(FindConVar("z_tank_speed"), 214);
		SetConVarInt(FindConVar("tongue_hit_delay"), 16);
		SetConVarInt(FindConVar("tongue_range"), 1900);
		SetConVarInt(FindConVar("tongue_victim_max_speed"), 181);
		SetConVarInt(FindConVar("z_vomit_interval"), 16);
		SetConVarInt(FindConVar("director_force_background"), 0);
		SetConVarInt(FindConVar("z_background_limit"), 29);
		SetConVarInt(FindConVar("z_common_limit"), 41);
		SetConVarInt(FindConVar("z_mob_spawn_min_size"), 16);
		SetConVarInt(FindConVar("z_mob_spawn_finale_size"), 32);
		SetConVarInt(FindConVar("z_mob_spawn_max_size"), 48);
		SetConVarInt(FindConVar("z_mega_mob_size"), 80);
		SetConVarInt(FindConVar("z_mob_spawn_min_interval_expert"), 30);
		SetConVarInt(FindConVar("z_mob_spawn_max_interval_expert"), 50);
	}
	else if (count == 5)
	{
		SetConVarInt(FindConVar("l4d_together_loner_punish"), 1);
		SetConVarInt(FindConVar("survivor_crawl_speed"), 25);
		SetConVarInt(FindConVar("survivor_revive_duration"), 5);
		SetConVarInt(FindConVar("survivor_revive_health"), 45);
		SetConVarInt(FindConVar("survivor_limp_health"), 36);
		SetConVarInt(FindConVar("first_aid_kit_use_duration"), 5);
		SetConVarInt(FindConVar("z_witch_health"), 1250);
		SetConVarInt(FindConVar("z_witch_burn_time"), 19);
		SetConVarInt(FindConVar("z_tank_speed"), 215);
		SetConVarInt(FindConVar("tongue_hit_delay"), 15);
		SetConVarInt(FindConVar("tongue_range"), 2300);
		SetConVarInt(FindConVar("tongue_victim_max_speed"), 184);
		SetConVarInt(FindConVar("z_vomit_interval"), 15);
		SetConVarInt(FindConVar("director_force_background"), 0);
		SetConVarInt(FindConVar("z_background_limit"), 30);
		SetConVarInt(FindConVar("z_common_limit"), 42);
		SetConVarInt(FindConVar("z_mob_spawn_min_size"), 18);
		SetConVarInt(FindConVar("z_mob_spawn_finale_size"), 36);
		SetConVarInt(FindConVar("z_mob_spawn_max_size"), 54);
		SetConVarInt(FindConVar("z_mega_mob_size"), 90);
		SetConVarInt(FindConVar("z_mob_spawn_min_interval_expert"), 25);
		SetConVarInt(FindConVar("z_mob_spawn_max_interval_expert"), 50);
	}
	else if (count == 6)
	{
		SetConVarInt(FindConVar("l4d_together_loner_punish"), 1);
		SetConVarInt(FindConVar("survivor_crawl_speed"), 30);
		SetConVarInt(FindConVar("survivor_revive_duration"), 6);
		SetConVarInt(FindConVar("survivor_revive_health"), 44);
		SetConVarInt(FindConVar("survivor_limp_health"), 35);
		SetConVarInt(FindConVar("first_aid_kit_use_duration"), 6);
		SetConVarInt(FindConVar("z_witch_health"), 1300);
		SetConVarInt(FindConVar("z_witch_burn_time"), 20);
		SetConVarInt(FindConVar("z_tank_speed"), 216);
		SetConVarInt(FindConVar("tongue_hit_delay"), 14);
		SetConVarInt(FindConVar("tongue_range"), 2700);
		SetConVarInt(FindConVar("tongue_victim_max_speed"), 187);
		SetConVarInt(FindConVar("z_vomit_interval"), 14);
		SetConVarInt(FindConVar("director_force_background"), 0);
		SetConVarInt(FindConVar("z_background_limit"), 31);
		SetConVarInt(FindConVar("z_common_limit"), 43);
		SetConVarInt(FindConVar("z_mob_spawn_min_size"), 20);
		SetConVarInt(FindConVar("z_mob_spawn_finale_size"), 40);
		SetConVarInt(FindConVar("z_mob_spawn_max_size"), 60);
		SetConVarInt(FindConVar("z_mega_mob_size"), 100);
		SetConVarInt(FindConVar("z_mob_spawn_min_interval_expert"), 25);
		SetConVarInt(FindConVar("z_mob_spawn_max_interval_expert"), 45);
	}
	else if (count == 7)
	{
		SetConVarInt(FindConVar("l4d_together_loner_punish"), 1);
		SetConVarInt(FindConVar("survivor_crawl_speed"), 35);
		SetConVarInt(FindConVar("survivor_revive_duration"), 6);
		SetConVarInt(FindConVar("survivor_revive_health"), 43);
		SetConVarInt(FindConVar("survivor_limp_health"), 35);
		SetConVarInt(FindConVar("first_aid_kit_use_duration"), 6);
		SetConVarInt(FindConVar("z_witch_health"), 1350);
		SetConVarInt(FindConVar("z_witch_burn_time"), 21);
		SetConVarInt(FindConVar("z_tank_speed"), 217);
		SetConVarInt(FindConVar("tongue_hit_delay"), 13);
		SetConVarInt(FindConVar("tongue_range"), 3000);
		SetConVarInt(FindConVar("tongue_victim_max_speed"), 190);
		SetConVarInt(FindConVar("z_vomit_interval"), 13);
		SetConVarInt(FindConVar("director_force_background"), 0);
		SetConVarInt(FindConVar("z_background_limit"), 32);
		SetConVarInt(FindConVar("z_common_limit"), 44);
		SetConVarInt(FindConVar("z_mob_spawn_min_size"), 22);
		SetConVarInt(FindConVar("z_mob_spawn_finale_size"), 44);
		SetConVarInt(FindConVar("z_mob_spawn_max_size"), 66);
		SetConVarInt(FindConVar("z_mega_mob_size"), 110);
		SetConVarInt(FindConVar("z_mob_spawn_min_interval_expert"), 20);
		SetConVarInt(FindConVar("z_mob_spawn_max_interval_expert"), 45);
	}
	else if (count == 8)
	{
		SetConVarInt(FindConVar("l4d_together_loner_punish"), 1);
		SetConVarInt(FindConVar("survivor_crawl_speed"), 40);
		SetConVarInt(FindConVar("survivor_revive_duration"), 7);
		SetConVarInt(FindConVar("survivor_revive_health"), 42);
		SetConVarInt(FindConVar("survivor_limp_health"), 35);
		SetConVarInt(FindConVar("first_aid_kit_use_duration"), 7);
		SetConVarInt(FindConVar("z_witch_health"), 1400);
		SetConVarInt(FindConVar("z_witch_burn_time"), 22);
		SetConVarInt(FindConVar("z_tank_speed"), 218);
		SetConVarInt(FindConVar("tongue_hit_delay"), 12);
		SetConVarInt(FindConVar("tongue_range"), 3500);
		SetConVarInt(FindConVar("tongue_victim_max_speed"), 193);
		SetConVarInt(FindConVar("z_vomit_interval"), 12);
		SetConVarInt(FindConVar("director_force_background"), 0);
		SetConVarInt(FindConVar("z_background_limit"), 33);
		SetConVarInt(FindConVar("z_common_limit"), 45);
		SetConVarInt(FindConVar("z_mob_spawn_min_size"), 24);
		SetConVarInt(FindConVar("z_mob_spawn_finale_size"), 48);
		SetConVarInt(FindConVar("z_mob_spawn_max_size"), 72);
		SetConVarInt(FindConVar("z_mega_mob_size"), 120);
		SetConVarInt(FindConVar("z_mob_spawn_min_interval_expert"), 20);
		SetConVarInt(FindConVar("z_mob_spawn_max_interval_expert"), 40);
	}
	else if (count == 9)
	{
		SetConVarInt(FindConVar("l4d_together_loner_punish"), 1);
		SetConVarInt(FindConVar("survivor_crawl_speed"), 40);
		SetConVarInt(FindConVar("survivor_revive_duration"), 7);
		SetConVarInt(FindConVar("survivor_revive_health"), 41);
		SetConVarInt(FindConVar("survivor_limp_health"), 35);
		SetConVarInt(FindConVar("first_aid_kit_use_duration"), 7);
		SetConVarInt(FindConVar("z_witch_health"), 1450);
		SetConVarInt(FindConVar("z_witch_burn_time"), 23);
		SetConVarInt(FindConVar("z_tank_speed"), 219);
		SetConVarInt(FindConVar("tongue_hit_delay"), 11);
		SetConVarInt(FindConVar("tongue_range"), 4000);
		SetConVarInt(FindConVar("tongue_victim_max_speed"), 196);
		SetConVarInt(FindConVar("z_vomit_interval"), 11);
		SetConVarInt(FindConVar("director_force_background"), 40);
		SetConVarInt(FindConVar("z_background_limit"), 5);
		SetConVarInt(FindConVar("z_common_limit"), 45);
		SetConVarInt(FindConVar("z_mob_spawn_min_size"), 26);
		SetConVarInt(FindConVar("z_mob_spawn_finale_size"), 52);
		SetConVarInt(FindConVar("z_mob_spawn_max_size"), 78);
		SetConVarInt(FindConVar("z_mega_mob_size"), 130);
		SetConVarInt(FindConVar("z_mob_spawn_min_interval_expert"), 15);
		SetConVarInt(FindConVar("z_mob_spawn_max_interval_expert"), 40);
	}
	else if (count == 10)
	{
		SetConVarInt(FindConVar("l4d_together_loner_punish"), 1);
		SetConVarInt(FindConVar("survivor_crawl_speed"), 40);
		SetConVarInt(FindConVar("survivor_revive_duration"), 7);
		SetConVarInt(FindConVar("survivor_revive_health"), 40);
		SetConVarInt(FindConVar("survivor_limp_health"), 35);
		SetConVarInt(FindConVar("first_aid_kit_use_duration"), 7);
		SetConVarInt(FindConVar("z_witch_health"), 1500);
		SetConVarInt(FindConVar("z_witch_burn_time"), 24);
		SetConVarInt(FindConVar("z_tank_speed"), 220);
		SetConVarInt(FindConVar("tongue_hit_delay"), 10);
		SetConVarInt(FindConVar("tongue_range"), 4500);
		SetConVarInt(FindConVar("tongue_victim_max_speed"), 199);
		SetConVarInt(FindConVar("z_vomit_interval"), 10);
		SetConVarInt(FindConVar("director_force_background"), 40);
		SetConVarInt(FindConVar("z_background_limit"), 5);
		SetConVarInt(FindConVar("z_common_limit"), 45);
		SetConVarInt(FindConVar("z_mob_spawn_min_size"), 28);
		SetConVarInt(FindConVar("z_mob_spawn_finale_size"), 56);
		SetConVarInt(FindConVar("z_mob_spawn_max_size"), 84);
		SetConVarInt(FindConVar("z_mega_mob_size"), 140);
		SetConVarInt(FindConVar("z_mob_spawn_min_interval_expert"), 15);
		SetConVarInt(FindConVar("z_mob_spawn_max_interval_expert"), 35);
	}
	return true;
}