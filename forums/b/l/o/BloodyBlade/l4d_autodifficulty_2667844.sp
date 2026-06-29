#pragma newdecls required
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.2.1"

public Plugin myinfo = 
{
	name = "[L4D] Autodifficulty",
	author = "Jonny",
	description = "",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};

float DifficultyMultiplier[MAXPLAYERS + 1];

ConVar l4d_autodifficulty;
ConVar z_difficulty;
ConVar z_special_spawn_interval;
ConVar tank_burn_duration_expert;
ConVar z_hunter_health;
ConVar z_smoker_health;
ConVar z_boomer_health;
ConVar z_witch_health;
ConVar z_tank_health;
ConVar z_health;
ConVar z_hunter_limit;
ConVar z_smoker_limit;
ConVar z_boomer_limit;
ConVar z_spitter_max_wait_time;
ConVar z_vomit_interval;

ConVar z_smoker_speed;
ConVar z_boomer_speed;
ConVar z_tank_speed;

ConVar smoker_pz_claw_dmg;
ConVar tongue_choke_damage_amount;
ConVar tongue_drag_damage_amount;
ConVar tongue_miss_delay;
ConVar tongue_hit_delay;

ConVar l4d_loot_h_drop_items;
ConVar l4d_loot_b_drop_items;
ConVar l4d_loot_s_drop_items;
ConVar l4d_loot_t_drop_items;

ConVar l4d_loot_g_chance_nodrop;

public void OnPluginStart()
{
	AddServerTag("autodifficulty");
	l4d_autodifficulty = CreateConVar("l4d_autodifficulty", "1", "Is the plugin enabled.");
	CreateConVar("l4d_autodifficulty_ver", PLUGIN_VERSION, "Version of the [L4D2] Autodifficulty.", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	HookConVarChange(l4d_autodifficulty, Autodifficulty_EnableDisable);
	HookEvent("player_entered_checkpoint", Event_CheckPoint);

	z_difficulty = FindConVar("z_difficulty");

	z_special_spawn_interval = FindConVar("z_special_spawn_interval");
	tank_burn_duration_expert = FindConVar("tank_burn_duration_expert");
	z_hunter_health = FindConVar("z_hunter_health");
	z_smoker_health = FindConVar("z_gas_health");
	z_boomer_health = FindConVar("z_exploding_health");
	z_witch_health = FindConVar("z_witch_health");
	z_tank_health = FindConVar("z_tank_health");
	z_hunter_limit = FindConVar("z_hunter_limit");
	z_smoker_limit = FindConVar("z_gas_limit");
	z_boomer_limit = FindConVar("z_exploding_limit");
	z_health = FindConVar("z_health");
	z_spitter_max_wait_time = FindConVar("z_spitter_max_wait_time");
	z_vomit_interval = FindConVar("z_vomit_interval");

	z_smoker_speed = FindConVar("z_gas_speed");
	z_boomer_speed = FindConVar("z_exploding_speed");
	z_tank_speed = FindConVar("z_tank_speed");

	RegConsoleCmd("say", Command_Say);

	DifficultyMultiplier[0] = 1.0;
}

stock int CheckCvarMin(const int Cvar_Value, int Cvar_Value_Min)
{
	if (Cvar_Value < Cvar_Value_Min)
	{
		return Cvar_Value_Min;
	}
	else
	{
		return Cvar_Value;
	}
}

public Action Event_CheckPoint(Event event, const char[] name, bool dontBroadcast)
{
	if (GetConVarInt(l4d_autodifficulty) == 0)
		return Plugin_Continue;

	return Plugin_Continue;
		
	int Target = GetClientOfUserId(GetEventInt(event, "userid"));
	char strBuffer[128];
	GetEventString(event, "doorname", strBuffer, sizeof(strBuffer));

	if (Target)
	{
		PrintToChatAll("\x05Event: \x04CheckPoint ( \x01%N\x04 ) Door ( \x01%s\x04 ) Area ( \x01%d\x04 )", Target, strBuffer, GetEventInt(event, "area"));
	}
	
	return Plugin_Continue;
}

stock int GetRealClientCount(bool inGameOnly = true)
{
	int clients = 0;
	char ClientSteamID[12];
	for (int i = 1; i <= GetMaxClients(); i++)
	{
		if (IsClientConnected(i))
		{
			GetClientAuthId(i, AuthId_Steam2, ClientSteamID, sizeof(ClientSteamID));
			if (!StrEqual(ClientSteamID, "BOT", false))
			{
				if (IsClientInGame(i) && !IsFakeClient(i))
				{
					clients++;
				}
			}
		}
	}
	return clients;
}

stock int GetTankHP()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsTank(i))
		{
			return GetClientHealth(i);
		}
	}
	return GetConVarInt(z_tank_health) * 2;
}

stock bool IsTankAlive()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsTank(i))
		{
			return true;
		}
	}
	return false;
}

stock bool IsTank(int client) // L4D
{
	if(client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 3)
	{
		int class = GetEntProp(client, Prop_Send, "m_zombieClass");
		if(class == 5)
		{
			return true;
		}
	}
	return false;
}

stock int GetTotalDifficultyMultiplier()
{
	int clients = 0;
	float DifficultySum = 0.0;
	char ClientSteamID[12];
	for (int i = 1; i <= GetMaxClients(); i++)
	{
		if (IsClientConnected(i))
		{
			GetClientAuthId(i, AuthId_Steam2, ClientSteamID, sizeof(ClientSteamID));
			if (!StrEqual(ClientSteamID, "BOT", false))
			{
				if (IsClientInGame(i) && !IsFakeClient(i))
				{
					clients++;
//					if (DifficultyMultiplier[i] == 0.0)
//						DifficultyMultiplier[i] = 1.0;
					DifficultySum = DifficultySum + DifficultyMultiplier[i];
				}
			}
		}
	}
	DifficultyMultiplier[0] = (DifficultySum / clients) * (DifficultySum / clients);

	if (DifficultyMultiplier[0] < 0.1)
	{
		DifficultyMultiplier[0] = 0.1;
	}

	return RoundToZero(DifficultyMultiplier[0] * 10);
}

public Action Command_Say(int client, int args)
{
	if (GetConVarInt(l4d_autodifficulty) == 0)
		return Plugin_Continue;

	if (!client)
	{
		return Plugin_Continue;
	}
	
	char text[192];
	if (!GetCmdArgString(text, sizeof(text)))
	{
		return Plugin_Continue;
	}
	
	int startidx = 0;
	if(text[strlen(text)-1] == '"')
	{
		text[strlen(text)-1] = '\0';
		startidx = 1;
	}
	
	ReplySource old = SetCmdReplySource(SM_REPLY_TO_CHAT);
	
	if (strcmp(text[startidx], "!info", false) == 0)
	{
		char GameDifficulty[24];
		GetConVarString(z_difficulty, GameDifficulty, sizeof(GameDifficulty));
		if (StrEqual(GameDifficulty, "Easy", false))
		{
			GameDifficulty = "Easy";
		}
		else if (StrEqual(GameDifficulty, "Normal", false))
		{
			GameDifficulty = "Normal";
	    }
		else if (StrEqual(GameDifficulty, "Hard", false))
		{
			GameDifficulty = "Master";
		}
		else if (StrEqual(GameDifficulty, "Impossible", false))
		{
			GameDifficulty = "Expert";
		}

		PrintToChatAll("\x05Informantion:\x03");
		PrintToChatAll("\x05Difficulty: \x04%s\x05 x \x04%f\x05 | Active players: \x04%i\x03", GameDifficulty, DifficultyMultiplier[0], GetRealClientCount(true));
		if (IsTankAlive())
		{
			PrintToChatAll("\x05Tank HP: \x03%i\x05 | Witch HP: \x04%i\x05 | Zombie HP: \x04%i\x03", GetTankHP(), GetConVarInt(z_witch_health), GetConVarInt(z_health));
		}
		else
		{
			PrintToChatAll("\x05Tank HP: \x04%i\x05 | Witch HP: \x04%i\x05 | Zombie HP: \x04%i\x03", GetTankHP(), GetConVarInt(z_witch_health), GetConVarInt(z_health));
		}
		PrintToChatAll("\x05Hunter HP: \x04%i\x05 | Smoker HP: \x04%i\x05 | Boomer HP: \x04%i", GetConVarInt(z_hunter_health), GetConVarInt(z_smoker_health), GetConVarInt(z_boomer_health));
	}
	
	if (strcmp(text[startidx], "!points", false) == 0 || strcmp(text[startidx], "!usepoints", false) == 0 || strcmp(text[startidx], "!wm", false) == 0 || strcmp(text[startidx], "!cc", false) == 0 || strcmp(text[startidx], "!buy", false) == 0)
	{
		PrintToChatAll("\x05No points on this server. Only loot drops from special infected.\x03");
		PrintToChatAll("\x05No commands on this server! Only \x04!easy\x05, \x04!normal\x05, \x04!info\x05, \x04!hard\x05, \x04!next\x05 and standart SM commands like \x04thetime\x03");
	}

	if (strcmp(text[startidx], "!easy", false) == 0)
	{
		if (DifficultyMultiplier[client] != 0.0)
		{
			SetClientInfo(client, "_dv", "easy");
			DifficultyMultiplier[client] = 0.0;
			GetTotalDifficultyMultiplier();
			Autodifficulty(GetRealClientCount(true));
			PrintToChatAll("\x05%N changed Difficulty Multiplier to \x04%f. (0.0)", client, DifficultyMultiplier[0]);
		}
	}
	else if (strcmp(text[startidx], "!normal", false) == 0)
	{
		if (DifficultyMultiplier[client] != 1.0)
		{
			SetClientInfo(client, "_dv", "normal");
			DifficultyMultiplier[client] = 1.0;
			GetTotalDifficultyMultiplier();
			Autodifficulty(GetRealClientCount(true));
			PrintToChatAll("\x05%N changed Difficulty Multiplier to \x04%f. (1.0)", client, DifficultyMultiplier[0]);
		}
	}
	else if (strcmp(text[startidx], "!hard", false) == 0)
	{
		if (DifficultyMultiplier[client] != 2.0)
		{
			SetClientInfo(client, "_dv", "hard");
			DifficultyMultiplier[client] = 2.0;
			GetTotalDifficultyMultiplier();
			Autodifficulty(GetRealClientCount(true));
			PrintToChatAll("\x05%N changed Difficulty Multiplier to \x04%f (2.0)", client, DifficultyMultiplier[0]);
		}
	}
	if (strcmp(text[startidx], "!all easy", false) == 0)
	{
		AdminId adminId = GetUserAdmin(client);
		// Checks if player is registered as an admin
		if (((adminId == INVALID_ADMIN_ID) ? false : GetAdminFlag(adminId, Admin_Root)) == false)
		{
			ReplyToCommand(client, "You don't have enough permissions to use this command.");
			return Plugin_Continue;
		}
		else
		{
			char ClientSteamID[12];
			for (int i = 1; i <= GetMaxClients(); i++)
			{
				if (IsClientConnected(i))
				{
					GetClientAuthId(i, AuthId_Steam2, ClientSteamID, sizeof(ClientSteamID));
					if (!StrEqual(ClientSteamID, "BOT", false))
					{
						if (IsClientInGame(i) && !IsFakeClient(i))
						{
							DifficultyMultiplier[i] = 0.0;
						}       
					}
				}
			}
			GetTotalDifficultyMultiplier();
			Autodifficulty(GetRealClientCount(true));
			PrintToChatAll("\x05%N changed Difficulty Multiplier to \x04%f (0.0)", client, DifficultyMultiplier[0]);			
		}
	}
	if (strcmp(text[startidx], "!all normal", false) == 0)
	{
		AdminId adminId = GetUserAdmin(client);
		// Checks if player is registered as an admin
		if (((adminId == INVALID_ADMIN_ID) ? false : GetAdminFlag(adminId, Admin_Root)) == false)
		{
			ReplyToCommand(client, "You don't have enough permissions to use this command.");
			return Plugin_Continue;
		}
		else
		{
			char ClientSteamID[12];
			for (int i = 1; i <= GetMaxClients(); i++)
			{
				if (IsClientConnected(i))
				{
					GetClientAuthId(i, AuthId_Steam2, ClientSteamID, sizeof(ClientSteamID));
					if (!StrEqual(ClientSteamID, "BOT", false))
					{
						if (IsClientInGame(i) && !IsFakeClient(i))
						{
							DifficultyMultiplier[i] = 1.0;
						}     
					}
				}
			}
			GetTotalDifficultyMultiplier();
			Autodifficulty(GetRealClientCount(true));
			PrintToChatAll("\x05%N changed Difficulty Multiplier to \x04%f (1.0)", client, DifficultyMultiplier[0]);			
		}
	}
	if (strcmp(text[startidx], "!all hard", false) == 0)
	{
		AdminId adminId = GetUserAdmin(client);
		// Checks if player is registered as an admin
		if (((adminId == INVALID_ADMIN_ID) ? false : GetAdminFlag(adminId, Admin_Root)) == false)
		{
			ReplyToCommand(client, "You don't have enough permissions to use this command.");
			return Plugin_Continue;
		}
		else
		{
			char ClientSteamID[12];
			for (int i = 1; i <= GetMaxClients(); i++)
			{
				if (IsClientConnected(i))
				{
					GetClientAuthId(i, AuthId_Steam2, ClientSteamID, sizeof(ClientSteamID));
					if (!StrEqual(ClientSteamID, "BOT", false))
					{
						if (IsClientInGame(i) && !IsFakeClient(i))
						{
							DifficultyMultiplier[i] = 2.0;
						}
					}
				}
			}
			GetTotalDifficultyMultiplier();
			Autodifficulty(GetRealClientCount(true));
			PrintToChatAll("\x05%N changed Difficulty Multiplier to \x04%f (2.0)", client, DifficultyMultiplier[0]);
		}
	}

	SetCmdReplySource(old);
	
	return Plugin_Continue;	
}

public void OnMapStart()
{
    if (GetConVarInt(l4d_autodifficulty) == 1) 
	{
		Autodifficulty(GetRealClientCount(true));
	}
}


public void Autodifficulty_EnableDisable(Handle hVariable, const char[] strOldValue, const char[] strNewValue)
{
    if (GetConVarInt(l4d_autodifficulty) == 1)
	{
		ServerCommand("exec autodifficulty_on.cfg");
		Autodifficulty(GetRealClientCount(true));
	}
    else
	{
		SetConVarInt(z_special_spawn_interval, 45, false, false);
		SetConVarInt(tank_burn_duration_expert, 75, false, false);
		SetConVarInt(z_hunter_limit, 3, false, false);
		SetConVarInt(z_smoker_limit, 1, false, false);
		SetConVarInt(z_boomer_limit, 1, false, false);

		SetConVarInt(z_hunter_health, 250, false, false);
		SetConVarInt(z_smoker_health, 250, false, false);
		SetConVarInt(z_boomer_health, 50, false, false);
		SetConVarInt(z_witch_health, 1000, false, false);

		SetConVarInt(z_spitter_max_wait_time, 30, false, false);
		SetConVarInt(z_vomit_interval, 30, false, false);

		SetConVarInt(z_smoker_speed, 210, false, false);
		SetConVarInt(z_boomer_speed, 175, false, false);
		SetConVarInt(z_tank_speed, 210, false, false);

		char sGameDifficulty[16];
		GetConVarString(z_difficulty, sGameDifficulty, sizeof(sGameDifficulty));
		if (StrEqual(sGameDifficulty, "Easy", false))
		{
			SetConVarInt(z_tank_health, 1000, false, false);
		}
		else if (StrEqual(sGameDifficulty, "Normal", false))
		{
			SetConVarInt(z_tank_health, 2000, false, false);
		}
		else if (StrEqual(sGameDifficulty, "Hard", false))
		{
			SetConVarInt(z_tank_health, 3000, false, false);
		}
		else if (StrEqual(sGameDifficulty, "Impossible", false))
		{
			SetConVarInt(z_tank_health, 4000, false, false);
		}

		SetConVarInt(z_health, 50, false, false);

		ServerCommand("exec autodifficulty_off.cfg");
	}
}

public Action AutoDifficulty(Handle timer)
{
	Autodifficulty(GetRealClientCount(true));
}

public void OnClientPutInServer(int client)
{
	if (!IsFakeClient(client) && GetConVarInt(l4d_autodifficulty) == 1)
	{
		CreateTimer(3.0, AutoDifficulty);
		char client_difficulty[10];
		// Difficulty Voted
		if (GetClientInfo(client, "_dv", client_difficulty, sizeof(client_difficulty)))
		{
			if (StrEqual(client_difficulty, "easy", false))
			{
				DifficultyMultiplier[client] = 0.0;
			}
			else if (StrEqual(client_difficulty, "normal", false))
			{
				DifficultyMultiplier[client] = 1.0;
			}
			else if (StrEqual(client_difficulty, "hard", false))
			{
				DifficultyMultiplier[client] = 2.0;
			}
			else
			{
				DifficultyMultiplier[client] = 1.0;
				PrintToChat(client, "\x05No difficulty records found. It will be \"Normal (1.0)\"", client);
			}
		}
		GetTotalDifficultyMultiplier();
		Autodifficulty(GetRealClientCount(true));
//		PrintToChatAll("\x05Player \x04%N\x05 has entered the game. Zombies grow stronger!\x03", client);
//		PrintToChatAll("\x05%N changed Difficulty Multiplier to \x04%f.", client, DifficultyMultiplier[0]);
	}
}

public void OnClientDisconnect(int client)
{
	if (!IsFakeClient(client) && GetConVarInt(l4d_autodifficulty) == 1)
	{
		if (GetRealClientCount(true) == 0)
		{
			ServerCommand("exec clear.cfg");
		}
		else
		{
			Autodifficulty(GetRealClientCount(true));
			CreateTimer(3.0, AutoDifficulty);
			PrintToChatAll("\x05Player \x04%N\x05 has left the game. Zombies weaken! \x03", client);
//			PrintToChatAll("\x05%N changed Difficulty Multiplier to \x04%f.", client, DifficultyMultiplier[0]);
		}
	}
}

public void Autodifficulty(int playerscount)
{
	if (playerscount < 4)
	{
		playerscount = 4;
	}
	
//	GetTotalDifficultyMultiplier();

	smoker_pz_claw_dmg = FindConVar("smoker_pz_claw_dmg");
	tongue_choke_damage_amount = FindConVar("tongue_choke_damage_amount");
	tongue_drag_damage_amount = FindConVar("tongue_drag_damage_amount");
	tongue_miss_delay = FindConVar("tongue_miss_delay");
	tongue_hit_delay = FindConVar("tongue_hit_delay");

	l4d_loot_h_drop_items = FindConVar("l4d_loot_h_drop_items");
	l4d_loot_b_drop_items = FindConVar("l4d_loot_b_drop_items");
	l4d_loot_s_drop_items = FindConVar("l4d_loot_s_drop_items");
	l4d_loot_t_drop_items = FindConVar("l4d_loot_t_drop_items");
	
	l4d_loot_g_chance_nodrop = FindConVar("l4d_loot_g_chance_nodrop");

	if (playerscount > 4)
	{
		SetConVarInt(z_special_spawn_interval, CheckCvarMin((49 - (playerscount * 3)), 5), false, false);
		SetConVarInt(tank_burn_duration_expert, RoundToZero(10.0 * playerscount), false, false);

		SetConVarInt(z_vomit_interval, 34 - playerscount, false, false);

		SetConVarInt(z_smoker_speed, 210 + RoundToZero(4.0 * (playerscount - 4) * DifficultyMultiplier[0]), false, false); 
		SetConVarInt(z_boomer_speed, 175 + RoundToZero(4.0 * (playerscount - 4) * DifficultyMultiplier[0]), false, false); 
		SetConVarInt(z_tank_speed, 210 + RoundToZero((playerscount - 4) * 5 * DifficultyMultiplier[0]), false, false);

		SetConVarInt(z_hunter_limit, RoundToZero(1.5 + (playerscount / 5)), false, false);
		SetConVarInt(z_smoker_limit, RoundToZero(0.5 + (playerscount / 6)), false, false);
		SetConVarInt(z_boomer_limit, RoundToZero(0.5 + (playerscount / 7)), false, false);
	
		SetConVarInt(l4d_loot_h_drop_items, RoundToZero((playerscount / 7) * SquareRoot(DifficultyMultiplier[0])), false, false);
		SetConVarInt(l4d_loot_b_drop_items, RoundToZero((playerscount / 5) * SquareRoot(DifficultyMultiplier[0])), false, false);
		SetConVarInt(l4d_loot_s_drop_items, RoundToZero((playerscount / 6) * SquareRoot(DifficultyMultiplier[0])), false, false);
		SetConVarInt(l4d_loot_t_drop_items, RoundToZero(playerscount * SquareRoot(DifficultyMultiplier[0])), false, false);

		SetConVarInt(z_hunter_health, RoundToZero(62.5 * playerscount * DifficultyMultiplier[0]), false, false);
		SetConVarInt(z_smoker_health, RoundToZero(62.5 * playerscount * DifficultyMultiplier[0]), false, false);
		SetConVarInt(z_boomer_health, RoundToZero(12.5 * playerscount * DifficultyMultiplier[0]), false, false);
		SetConVarInt(z_witch_health, 1000 + RoundToZero(80.0 * (playerscount - 4) * DifficultyMultiplier[0]), false, false);
		SetConVarInt(z_health, RoundToZero(12.5 * playerscount * DifficultyMultiplier[0]), false, false);
	}
	else
	{
		SetConVarInt(z_hunter_health, 250, false, false);
		SetConVarInt(z_smoker_health, 250, false, false);
		SetConVarInt(z_boomer_health, 50, false, false);
		SetConVarInt(z_witch_health, 1000, false, false);
		SetConVarInt(z_health, 50, false, false);

		SetConVarInt(z_special_spawn_interval, 45, false, false);

		SetConVarInt(z_hunter_limit, 1, false, false);
		SetConVarInt(z_smoker_limit, 1, false, false);
		SetConVarInt(z_boomer_limit, 1, false, false);

		SetConVarInt(z_smoker_speed, 210, false, false);
		SetConVarInt(z_boomer_speed, 175, false, false);
		SetConVarInt(z_tank_speed, 210, false, false);
	}

	SetConVarInt(smoker_pz_claw_dmg, playerscount, false, false);
	SetConVarInt(tongue_choke_damage_amount, RoundToZero((10 + (playerscount - 4) * 1.666) * DifficultyMultiplier[0]), false, false);
	SetConVarInt(tongue_drag_damage_amount, RoundToZero(playerscount * 0.75 * DifficultyMultiplier[0]), false, false);
	SetConVarInt(tongue_miss_delay, CheckCvarMin(17 - playerscount, 1), false, false);
	SetConVarInt(tongue_hit_delay, CheckCvarMin(17 - playerscount, 1), false, false);

	SetConVarInt(l4d_loot_g_chance_nodrop, RoundToZero(30 / DifficultyMultiplier[0]), false, false);

	char sGameDifficulty[16];
	GetConVarString(z_difficulty, sGameDifficulty, sizeof(sGameDifficulty));
	if (StrEqual(sGameDifficulty, "Easy", false))
	{
		SetConVarInt(z_tank_health, 1000 + RoundToZero(250 * (playerscount - 4) * DifficultyMultiplier[0]), false, false);
	}
	else if (StrEqual(sGameDifficulty, "Normal", false))
	{
		SetConVarInt(z_tank_health, 2000 + RoundToZero(100 * (playerscount - 4) * DifficultyMultiplier[0]), false, false);
	}
	else if (StrEqual(sGameDifficulty, "Hard", false))
	{
		SetConVarInt(z_tank_health, 4000 + RoundToZero(250 * (playerscount - 4) * DifficultyMultiplier[0]), false, false);
	}
	else if (StrEqual(sGameDifficulty, "Impossible", false))
	{
		SetConVarInt(z_tank_health, 6000 + RoundToZero(250 * (playerscount - 4) * DifficultyMultiplier[0]), false, false);
	}
}