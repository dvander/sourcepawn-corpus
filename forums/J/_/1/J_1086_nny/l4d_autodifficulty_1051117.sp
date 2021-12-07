#include <sourcemod>

public Plugin:myinfo = 
{
	name = "[L4D2] Autodifficulty",
	author = "Jonny",
	description = "",
	version = "1.5",
	url = "http://www.sourcemod.net/"
};

new Handle:l4d_autodifficulty;
new Handle:z_difficulty;
new Handle:z_special_spawn_interval;
new Handle:tank_burn_duration;
new Handle:z_hunter_health;
new Handle:z_smoker_health;
new Handle:z_boomer_health;
new Handle:z_charger_health;
new Handle:z_spitter_health;
new Handle:z_jockey_health;
new Handle:z_witch_health;
new Handle:z_tank_health;
new Handle:z_health;
new Handle:z_hunter_limit;
new Handle:z_smoker_limit;
new Handle:z_boomer_limit;
new Handle:z_charger_limit;
new Handle:z_spitter_limit;
new Handle:z_jockey_limit;
new Handle:z_spitter_max_wait_time;
new Handle:z_vomit_interval;
new Handle:z_spitter_speed;
new Handle:z_tank_speed;
//new Handle:l4d_loot_hunter_chance;
//new Handle:l4d_loot_smoker_chance;
//new Handle:l4d_loot_boomer_chance;
//new Handle:l4d_loot_charger_chance;
//new Handle:l4d_loot_spitter_chance;
//new Handle:l4d_loot_jocker_chance;
//new Handle:l4d_loot_tank_chance;

public OnPluginStart()
{
	l4d_autodifficulty = CreateConVar("l4d_autodifficulty", "1", "Is the plugin enabled.", FCVAR_PLUGIN);
	HookConVarChange(l4d_autodifficulty, Autodifficulty_EnableDisable);

	z_difficulty = FindConVar("z_difficulty");

	z_special_spawn_interval = FindConVar("z_special_spawn_interval");
	tank_burn_duration = FindConVar("tank_burn_duration");
	z_hunter_health = FindConVar("z_hunter_health");
	z_smoker_health = FindConVar("z_gas_health");
	z_boomer_health = FindConVar("z_exploding_health");
	z_charger_health = FindConVar("z_charger_health");
	z_spitter_health = FindConVar("z_spitter_health");
	z_jockey_health = FindConVar("z_jockey_health");
	z_witch_health = FindConVar("z_witch_health");
	z_tank_health = FindConVar("z_tank_health");
	z_hunter_limit = FindConVar("z_hunter_limit");
	z_smoker_limit = FindConVar("z_smoker_limit");
	z_boomer_limit = FindConVar("z_boomer_limit");
	z_charger_limit = FindConVar("z_charger_limit");
	z_spitter_limit = FindConVar("z_spitter_limit");
	z_jockey_limit = FindConVar("z_jockey_limit");
	z_health = FindConVar("z_health");
	z_spitter_max_wait_time = FindConVar("z_spitter_max_wait_time");
	z_vomit_interval = FindConVar("z_vomit_interval");
	z_spitter_speed = FindConVar("z_spitter_speed");
	z_tank_speed = FindConVar("z_tank_speed");

	RegConsoleCmd("say", Command_Say);
}

stock GetRealClientCount(bool:inGameOnly = true)
{
	new clients = 0;
	decl String:ClientSteamID[12];

	for (new i = 1; i <= GetMaxClients(); i++)
	{
		if (IsClientConnected(i))
		{
			GetClientAuthString(i, ClientSteamID, sizeof(ClientSteamID));
			if (!StrEqual(ClientSteamID, "BOT", false))
				if (IsClientInGame(i) && !IsFakeClient(i))
				{
					clients++;
				}       
		}
	}
	return clients;
}

public Action:Command_Say(client, args)
{
	if (!client)
	{
		return Plugin_Continue;
	}
	
	decl String:text[192];
	if (!GetCmdArgString(text, sizeof(text)))
	{
		return Plugin_Continue;
	}
	
	new startidx = 0;
	if(text[strlen(text)-1] == '"')
	{
		text[strlen(text)-1] = '\0';
		startidx = 1;
	}
	
	new ReplySource:old = SetCmdReplySource(SM_REPLY_TO_CHAT);
	
	if (strcmp(text[startidx], "!info", false) == 0)
	{

		decl String:GameDifficulty[24];
		GetConVarString(z_difficulty, GameDifficulty, sizeof(GameDifficulty));
		if (StrEqual(GameDifficulty, "Hard", false))
		{
			GameDifficulty = "Master";
		}
		if (StrEqual(GameDifficulty, "Impossible", false))
		{
			GameDifficulty = "Expert";
	        }

		PrintToChatAll("\x05Informantion:\x03");
		PrintToChatAll("\x05Difficulty: \x04%s\x05 | Active players: \x04%i\x03", GameDifficulty, GetRealClientCount(true));
		PrintToChatAll("\x05Tank HP: \x04%i\x05 | Witch HP: \x04%i\x05 | Zombie HP: \x04%i\x03", GetConVarInt(z_tank_health), GetConVarInt(z_witch_health), GetConVarInt(z_health));
		PrintToChatAll("\x05Hunter HP: \x04%i\x05 | Smoker HP: \x04%i\x05 | Boomer HP: \x04%i\x05 \nCharger HP: \x04%i\x05 | Spitter HP: \x04%i\x05 | Jockey HP: \x04%i\x03", GetConVarInt(z_hunter_health), GetConVarInt(z_smoker_health), GetConVarInt(z_boomer_health), GetConVarInt(z_charger_health), GetConVarInt(z_spitter_health), GetConVarInt(z_jockey_health));
		PrintToChatAll("\x05Real HP = \x04Base HP \x05x\x04 Game Difficulty!\x03");
	}

	if (strcmp(text[startidx], "!points", false) == 0 || strcmp(text[startidx], "!usepoints", false) == 0 || strcmp(text[startidx], "!wm", false) == 0 || strcmp(text[startidx], "!cc", false) == 0 || strcmp(text[startidx], "!buy", false) == 0)
	{

		PrintToChatAll("\x05No points on this server. Only loot drops from special infected.\x03");
		PrintToChatAll("\x05No commands on this server! Only \x04!info\x05, \x04!next\x05 and standart SM commands like \x04thetime\x03");
	}
	
	SetCmdReplySource(old);
	
	return Plugin_Continue;	
}

public OnMapStart()
{
    if (GetConVarInt(l4d_autodifficulty) == 1) 
	{
		Autodifficulty(GetRealClientCount(true));
	}
}


public Autodifficulty_EnableDisable(Handle:hVariable, const String:strOldValue[], const String:strNewValue[])
{
    if (GetConVarInt(l4d_autodifficulty) == 1) 
	{
		ServerCommand("exec autodifficulty_on.cfg");
		Autodifficulty(GetRealClientCount(true));
	}
    else
	{

		SetConVarInt(z_special_spawn_interval, 45, false, false);
		SetConVarInt(tank_burn_duration, 75, false, false);
		SetConVarInt(z_hunter_limit, 3, false, false);
		SetConVarInt(z_smoker_limit, 1, false, false);
		SetConVarInt(z_boomer_limit, 1, false, false);
		SetConVarInt(z_charger_limit, 1, false, false);
		SetConVarInt(z_spitter_limit, 1, false, false);

		SetConVarInt(z_hunter_health, 250, false, false);
		SetConVarInt(z_smoker_health, 250, false, false);
		SetConVarInt(z_boomer_health, 50, false, false);
		SetConVarInt(z_charger_health, 600, false, false);
		SetConVarInt(z_spitter_health, 50, false, false);
		SetConVarInt(z_jockey_health, 325, false, false);
		SetConVarInt(z_witch_health, 1000, false, false);

		SetConVarInt(z_spitter_max_wait_time, 30, false, false);
		SetConVarInt(z_vomit_interval, 30, false, false);

		SetConVarInt(z_spitter_speed, 210, false, false);
		SetConVarInt(z_tank_speed, 210, false, false);

		decl String:sGameDifficulty[16];
		GetConVarString(z_difficulty, sGameDifficulty, sizeof(sGameDifficulty));
		
		if (StrEqual(sGameDifficulty, "Easy", false))
		{
			SetConVarInt(z_tank_health, 2000, false, false);
		}
		else if (StrEqual(sGameDifficulty, "Normal", false))
		{
			SetConVarInt(z_tank_health, 4000, false, false);
		}
		else if (StrEqual(sGameDifficulty, "Hard", false))
		{
			SetConVarInt(z_tank_health, 6000, false, false);
		}
		else if (StrEqual(sGameDifficulty, "Impossible", false))
		{
			SetConVarInt(z_tank_health, 8000, false, false);
		}
                                                     		
		SetConVarInt(z_health, 50, false, false);

		ServerCommand("exec autodifficulty_off.cfg");
	}
}

public Action:AutoDifficulty(Handle:timer)
{
	Autodifficulty(GetRealClientCount(true));
}

public OnClientPutInServer(client)
{
	if (!IsFakeClient(client))
	{
		CreateTimer(3.0, AutoDifficulty);
//		Autodifficulty(GetRealClientCount(true));
		PrintToChatAll("\x05Player \x04%N\x05 has entered the game. Zombies grow stronger!\x03", client);
	}
}

public OnClientDisconnect(client)
{
	if (!IsFakeClient(client))
	{
		if (GetRealClientCount(true) == 0)
		{
			ServerCommand("exec clear.cfg");
		}
		else
		{
			CreateTimer(3.0, AutoDifficulty);
//			Autodifficulty(GetRealClientCount(true));
			PrintToChatAll("\x05Player \x04%N\x05 has left the game. Zombies weaken! \x03", client);
		}
	}
}

public Autodifficulty(playerscount)
{
	if (playerscount < 4)
		playerscount = 4;

	new Handle:l4d_loot_hunter_cycles;
	new Handle:l4d_loot_smoker_cycles;
	new Handle:l4d_loot_boomer_cycles;
	new Handle:l4d_loot_charger_cycles;
	new Handle:l4d_loot_spitter_cycles;
	new Handle:l4d_loot_jockey_cycles;
	new Handle:l4d_loot_tank_cycles;

	new Handle:l4d_loot_hunter_chance;
	new Handle:l4d_loot_smoker_chance;
	new Handle:l4d_loot_boomer_chance;
	new Handle:l4d_loot_charger_chance;
	new Handle:l4d_loot_spitter_chance;
	new Handle:l4d_loot_jockey_chance;
	new Handle:l4d_loot_tank_chance;

	l4d_loot_hunter_cycles = FindConVar("l4d_loot_hunter_cycles");
	l4d_loot_smoker_cycles = FindConVar("l4d_loot_smoker_cycles");
	l4d_loot_boomer_cycles = FindConVar("l4d_loot_boomer_cycles");
	l4d_loot_charger_cycles = FindConVar("l4d_loot_charger_cycles");
	l4d_loot_spitter_cycles = FindConVar("l4d_loot_spitter_cycles");
	l4d_loot_jockey_cycles = FindConVar("l4d_loot_jockey_cycles");
	l4d_loot_tank_cycles = FindConVar("l4d_loot_tank_cycles");

	l4d_loot_hunter_chance = FindConVar("l4d_loot_hunter_chance");
	l4d_loot_smoker_chance = FindConVar("l4d_loot_smoker_chance");
	l4d_loot_boomer_chance = FindConVar("l4d_loot_boomer_chance");
	l4d_loot_charger_chance = FindConVar("l4d_loot_charger_chance");
	l4d_loot_spitter_chance = FindConVar("l4d_loot_spitter_chance");
	l4d_loot_jockey_chance = FindConVar("l4d_loot_jockey_chance");
	l4d_loot_tank_chance = FindConVar("l4d_loot_tank_chance");

	if (playerscount > 4)
	{
		SetConVarInt(z_special_spawn_interval, 49 - playerscount, false, false);
		SetConVarInt(tank_burn_duration, RoundToZero(18.75 * playerscount), false, false);

		SetConVarInt(z_spitter_max_wait_time, 34 - playerscount, false, false);
		SetConVarInt(z_vomit_interval, 34 - playerscount, false, false);

		SetConVarInt(z_spitter_speed, 160 + RoundToZero(15.0 * playerscount), false, false);
		SetConVarInt(z_tank_speed, 206 + playerscount, false, false);

		SetConVarInt(z_hunter_limit, RoundToZero(1.5 + playerscount / 5), false, false);
		SetConVarInt(z_smoker_limit, RoundToZero(0.5 + playerscount / 6), false, false);
		SetConVarInt(z_boomer_limit, RoundToZero(0.5 + playerscount / 7), false, false);
		SetConVarInt(z_charger_limit, RoundToZero(0.3 + playerscount / 7), false, false);
		SetConVarInt(z_spitter_limit, RoundToZero(0.4 + playerscount / 6), false, false);
		SetConVarInt(z_jockey_limit, RoundToZero(0.5 + playerscount / 8), false, false);
	
		SetConVarInt(l4d_loot_hunter_chance, RoundToZero(0.5 + (playerscount / 2)), false, false);
		SetConVarInt(l4d_loot_smoker_chance, RoundToZero(0.4 + (playerscount / 4)), false, false);
		SetConVarInt(l4d_loot_boomer_chance, RoundToZero(0.3 + (playerscount / 3)), false, false);
		SetConVarInt(l4d_loot_spitter_chance, RoundToZero(0.5 + (playerscount / 3)), false, false);
		SetConVarInt(l4d_loot_jockey_chance, RoundToZero(0.5 + (playerscount / 2)), false, false);

		SetConVarInt(l4d_loot_charger_chance, RoundToZero(0.2 + playerscount / 3), false, false);
		SetConVarInt(l4d_loot_charger_cycles, RoundToZero(playerscount * 1.0), false, false);

		SetConVarInt(l4d_loot_tank_chance, RoundToZero(playerscount / 20.0), false, false);
		SetConVarInt(l4d_loot_tank_cycles, RoundToZero(playerscount * 1.4), false, false);

		SetConVarInt(z_hunter_health, 250 + RoundToZero(137.5 * playerscount), false, false);
		SetConVarInt(z_smoker_health, 80 + RoundToZero(146.0 * playerscount), false, false);
		SetConVarInt(z_boomer_health, 50 + RoundToZero(47.5 * playerscount), false, false);
		SetConVarInt(z_charger_health, 600 + RoundToZero(470.0 * playerscount), false, false);
		SetConVarInt(z_spitter_health, 50 + RoundToZero(47.5 * playerscount), false, false);
		SetConVarInt(z_jockey_health, 325 + RoundToZero(167.1875 * (playerscount - 4)), false, false);
		SetConVarInt(z_witch_health, 1000 + RoundToZero(200.0 * playerscount), false, false);
		SetConVarInt(z_health, RoundToZero(12.5 * playerscount), false, false);
	}
	else
	{
		SetConVarInt(z_hunter_health, 250, false, false);
		SetConVarInt(z_smoker_health, 250, false, false);
		SetConVarInt(z_boomer_health, 50, false, false);
		SetConVarInt(z_charger_health, 600, false, false);
		SetConVarInt(z_spitter_health, 50, false, false);
		SetConVarInt(z_jockey_health, 325, false, false);
		SetConVarInt(z_witch_health, 1000, false, false);
		SetConVarInt(z_health, 50, false, false);

		SetConVarInt(z_special_spawn_interval, 45, false, false);

		SetConVarInt(z_hunter_limit, 3, false, false);
		SetConVarInt(z_smoker_limit, 1, false, false);
		SetConVarInt(z_boomer_limit, 1, false, false);
		SetConVarInt(z_charger_limit, 1, false, false);
		SetConVarInt(z_spitter_limit, 1, false, false);
		SetConVarInt(z_jockey_limit, 1, false, false);

		SetConVarInt(l4d_loot_hunter_chance, 3, false, false);
		SetConVarInt(l4d_loot_smoker_chance, 3, false, false);
		SetConVarInt(l4d_loot_boomer_chance, 3, false, false);
		SetConVarInt(l4d_loot_charger_chance, 3, false, false);
		SetConVarInt(l4d_loot_spitter_chance, 3, false, false);
		SetConVarInt(l4d_loot_jockey_chance, 3, false, false);
		SetConVarInt(l4d_loot_tank_chance, 3, false, false);

		SetConVarInt(z_spitter_max_wait_time, 30, false, false);
		SetConVarInt(z_spitter_speed, 210, false, false);
		SetConVarInt(z_tank_speed, 210, false, false);

		SetConVarInt(l4d_loot_charger_cycles, playerscount, false, false);		
		SetConVarInt(l4d_loot_tank_cycles, playerscount, false, false);
	}

	decl String:sGameDifficulty[16];
	GetConVarString(z_difficulty, sGameDifficulty, sizeof(sGameDifficulty));
		
	if (StrEqual(sGameDifficulty, "Easy", false))
	{
		SetConVarInt(z_tank_health, 500 * playerscount, false, false);
	}
	else if (StrEqual(sGameDifficulty, "Normal", false))
	{
		SetConVarInt(z_tank_health, 1000 * playerscount, false, false);
	}
	else if (StrEqual(sGameDifficulty, "Hard", false))
	{
		SetConVarInt(z_tank_health, 1500 * playerscount, false, false);
	}
	else if (StrEqual(sGameDifficulty, "Impossible", false))
	{
		SetConVarInt(z_tank_health, 2000 * playerscount, false, false);
	}

	SetConVarInt(l4d_loot_hunter_cycles, playerscount, false, false);
	SetConVarInt(l4d_loot_smoker_cycles, playerscount, false, false);
	SetConVarInt(l4d_loot_boomer_cycles, playerscount, false, false);
	
	SetConVarInt(l4d_loot_spitter_cycles, playerscount, false, false);
	SetConVarInt(l4d_loot_jockey_cycles, playerscount, false, false);
}