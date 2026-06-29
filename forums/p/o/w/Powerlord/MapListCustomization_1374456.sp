#include <sourcemod>

#pragma semicolon 1

new gamesupported = 0;

new const String:officialmaps[][] = { "arena_badlands", "arena_granary", "arena_lumberyard",
								"arena_nucleus", "arena_offblast_final", "arena_ravine", 
								"arena_sawmill", "arena_watchtower", "arena_well", "cp_badlands", 
								"cp_dustbowl", "cp_egypt_final", "cp_fastlane", "cp_gorge", 
								"cp_granary", "cp_gravelpit", "cp_junction_final", "cp_steel", 
								"cp_well", "cp_yukon_final", "ctf_2fort", "ctf_doublecross", 
								"ctf_sawmill", "ctf_turbine", "ctf_well", "koth_harvest_event", 
								"koth_harvest_final", "koth_nucleus", "koth_sawmill", 
								"koth_viaduct", "pl_badwater", "pl_goldrush", "pl_hoodoo_final", 
								"plr_pipeline", "tc_hydro", "cs_assault", "cs_compound", 
								"cs_havana", "cs_italy", "cs_militia", "cs_office", "de_aztec", 
								"de_cbble", "de_chateau", "de_dust", "de_dust2", "de_inferno", 
								"de_nuke", "de_piranesi", "de_port", "de_prodigy", "de_tides", 
								"de_train", "dod_anzio", "dod_argentan", "dod_avalanche", 
								"dod_colmar", "dod_donner", "dod_flash", "dod_jagd", "dod_kalt", 
								"dod_palermo", "dm_lockdown", "dm_overwatch", "dm_powerhouse", 
								"dm_resistance", "dm_runoff", "dm_steamlab", "dm_underpass", 
								"pl_upward", "plr_hightower", "pl_thundermountain", "cp_coldfront", 
								"cp_freight_final1", "cp_manor_event", "cp_mountainlab",
								"cp_degrootkeep" };
// official map list for: 	Team Fortress 2, Counter-Strike: Source, Day of Defeat: Source,
//							Half-Life 2: Deathmatch

public OnPluginStart_MapListCustom()
{
	new String:game_mod_name[32];
	GetGameFolderName(game_mod_name, sizeof(game_mod_name));
	if (strcmp(game_mod_name, "tf", false) == 0)
	{
		gamesupported = 1;
		LogAction(0, -1, "Team-Fotress 2 detected, official map list available");
	}	
	else if (strcmp(game_mod_name, "cstrike", false) == 0)
	{
		gamesupported = 1;
		LogAction(0, -1, "Counter-Strike Source detected, official map list available");
	}
	else if (strcmp(game_mod_name, "dod", false) == 0)
	{
		gamesupported = 1;
		LogAction(0, -1, "Day Of Defeat detected, official map list available");
	}
	else if (strcmp(game_mod_name, "hl2mp", false) == 0)
	{
		gamesupported = 1;
		LogAction(0, -1, "Half-Life 2: Deathmatch detected, official map list available");
	}
	else
	{
		gamesupported = 0;
		LogAction(0, -1, "Unsupported game/mod detected, no official map list available.");
	}
}

/**
 * @return        return if map is official
 */
MapIsOfficial(String: map[])
{
	if(gamesupported)
	{
		new match = 0;
		new map_index = 0;
		while ((match == 0) && (map_index < sizeof(officialmaps)))
		{
			if (strcmp(map, officialmaps[map_index]) == 0)
			{
				match++;
			}
			map_index++;
		}
		if (match > 0)
		{
			return true;
		}
		return false;
	}
	else return true;
}