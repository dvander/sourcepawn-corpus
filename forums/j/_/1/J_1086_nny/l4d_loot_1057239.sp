#include <sourcemod>

#define CVAR_FLAGS FCVAR_PLUGIN
#define PLUGIN_VERSION "1.3p"
#define DEBUG false
#define PRINT_DROP false

public Plugin:myinfo = 
{
	name = "[L4D] Loot of Zombies",
	author = "Jonny",
	description = "Plugin drops some items from killed special-infected",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=115763"
}

new IsMapFinished;

new Handle:IsPluginEnabled;
new Handle:DropItemsFromPlayers;
new Handle:NoFarm;
new Handle:NoFarmPanic;

// Global
new Handle:l4d_loot_g_chance_nodrop;

// Hunter
new Handle:l4d_loot_h_drop_items;
new Handle:l4d_loot_h_chance_health;
new Handle:l4d_loot_h_chance_bullet;
new Handle:l4d_loot_h_chance_throw;
new Handle:l4d_loot_h_chance_misc;
new Handle:l4d_loot_h_chance_nodrop;

// Boomer
new Handle:l4d_loot_b_drop_items;
new Handle:l4d_loot_b_chance_health;
new Handle:l4d_loot_b_chance_bullet;
new Handle:l4d_loot_b_chance_throw;
new Handle:l4d_loot_b_chance_misc;
new Handle:l4d_loot_b_chance_nodrop;

// Smoker
new Handle:l4d_loot_s_drop_items;
new Handle:l4d_loot_s_chance_health;
new Handle:l4d_loot_s_chance_bullet;
new Handle:l4d_loot_s_chance_throw;
new Handle:l4d_loot_s_chance_misc;
new Handle:l4d_loot_s_chance_nodrop;

// Tank
new Handle:l4d_loot_t_drop_items;
new Handle:l4d_loot_t_chance_health;
new Handle:l4d_loot_t_chance_bullet;
new Handle:l4d_loot_t_chance_throw;
new Handle:l4d_loot_t_chance_misc;
new Handle:l4d_loot_t_chance_nodrop;

new Handle:l4d_loot_first_aid_kit;
new Handle:l4d_loot_pain_pills;

new Handle:l4d_loot_pistol;
new Handle:l4d_loot_smg;
new Handle:l4d_loot_pumpshotgun;
new Handle:l4d_loot_autoshotgun;
new Handle:l4d_loot_hunting_rifle;
new Handle:l4d_loot_rifle;

new Handle:l4d_loot_pipe_bomb;
new Handle:l4d_loot_molotov;

new Handle:l4d_loot_gascan;
new Handle:l4d_loot_oxygentank;
new Handle:l4d_loot_propanetank;

public OnPluginStart()
{
    decl String:gamedir[11];
    GetGameFolderName(gamedir, sizeof(gamedir));
    if (!StrEqual(gamedir, "left4dead", false))
	{
        SetFailState("L4D only.");
	}
	else
	{
		AddServerTag("loot");
		CreateConVar("l4d_loot_version", PLUGIN_VERSION, "Version of the [L4D] Loot.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
		IsPluginEnabled = CreateConVar("l4d_loot", "1", "Is the plugin enabled.", FCVAR_PLUGIN);
		DropItemsFromPlayers = CreateConVar("l4d_loot_from_players", "0", "", FCVAR_PLUGIN);
		NoFarm = CreateConVar("l4d_loot_nofarm", "1", "No farm", FCVAR_PLUGIN);
		NoFarmPanic = CreateConVar("l4d_loot_nofarm_panic", "0", "Panic", FCVAR_PLUGIN);
		
		HookConVarChange(IsPluginEnabled, Loot_EnableDisable);

		if (GetConVarInt(IsPluginEnabled) > 0) 
		{
			HookEvent("player_death", Event_PlayerDeath);
		}
		else
		{
			UnhookEvent("player_death", Event_PlayerDeath);
		}
		HookEvent("player_entered_checkpoint", Event_CheckPoint);
		HookEvent("round_start_post_nav", Event_RoundStart);

		l4d_loot_g_chance_nodrop = CreateConVar("l4d_loot_g_chance_nodrop", "0", "", FCVAR_PLUGIN);

		l4d_loot_h_drop_items = CreateConVar("l4d_loot_h_drop_items", "1", "", FCVAR_PLUGIN);
		l4d_loot_b_drop_items = CreateConVar("l4d_loot_b_drop_items", "1", "", FCVAR_PLUGIN);
		l4d_loot_s_drop_items = CreateConVar("l4d_loot_s_drop_items", "1", "", FCVAR_PLUGIN);
		l4d_loot_t_drop_items = CreateConVar("l4d_loot_t_drop_items", "1", "", FCVAR_PLUGIN);

		l4d_loot_h_chance_health = CreateConVar("l4d_loot_h_chance_health", "16", "", FCVAR_PLUGIN);
		l4d_loot_h_chance_bullet = CreateConVar("l4d_loot_h_chance_bullet", "15", "", FCVAR_PLUGIN);
		l4d_loot_h_chance_throw = CreateConVar("l4d_loot_h_chance_throw", "20", "", FCVAR_PLUGIN);
		l4d_loot_h_chance_misc = CreateConVar("l4d_loot_h_chance_misc", "10", "", FCVAR_PLUGIN);
		l4d_loot_h_chance_nodrop = CreateConVar("l4d_loot_h_chance_nodrop", "30", "", FCVAR_PLUGIN);

		l4d_loot_b_chance_health = CreateConVar("l4d_loot_b_chance_health", "16", "", FCVAR_PLUGIN);
		l4d_loot_b_chance_bullet = CreateConVar("l4d_loot_b_chance_bullet", "15", "", FCVAR_PLUGIN);
		l4d_loot_b_chance_throw = CreateConVar("l4d_loot_b_chance_throw", "20", "", FCVAR_PLUGIN);
		l4d_loot_b_chance_misc = CreateConVar("l4d_loot_b_chance_misc", "10", "", FCVAR_PLUGIN);
		l4d_loot_b_chance_nodrop = CreateConVar("l4d_loot_b_chance_nodrop", "30", "", FCVAR_PLUGIN);

		l4d_loot_s_chance_health = CreateConVar("l4d_loot_s_chance_health", "16", "", FCVAR_PLUGIN);
		l4d_loot_s_chance_bullet = CreateConVar("l4d_loot_s_chance_bullet", "15", "", FCVAR_PLUGIN);
		l4d_loot_s_chance_throw = CreateConVar("l4d_loot_s_chance_throw", "20", "", FCVAR_PLUGIN);
		l4d_loot_s_chance_misc = CreateConVar("l4d_loot_s_chance_misc", "10", "", FCVAR_PLUGIN);
		l4d_loot_s_chance_nodrop = CreateConVar("l4d_loot_s_chance_nodrop", "30", "", FCVAR_PLUGIN);

		l4d_loot_t_chance_health = CreateConVar("l4d_loot_t_chance_health", "15", "", FCVAR_PLUGIN);
		l4d_loot_t_chance_bullet = CreateConVar("l4d_loot_t_chance_bullet", "3", "", FCVAR_PLUGIN);
		l4d_loot_t_chance_throw = CreateConVar("l4d_loot_t_chance_throw", "4", "", FCVAR_PLUGIN);
		l4d_loot_t_chance_misc = CreateConVar("l4d_loot_t_chance_misc", "1", "", FCVAR_PLUGIN);
		l4d_loot_t_chance_nodrop = CreateConVar("l4d_loot_t_chance_nodrop", "0", "", FCVAR_PLUGIN);

		l4d_loot_first_aid_kit = CreateConVar("l4d_loot_first_aid_kit", "4", "", FCVAR_PLUGIN);
		l4d_loot_pain_pills = CreateConVar("l4d_loot_pain_pills", "5", "", FCVAR_PLUGIN);

		l4d_loot_pistol = CreateConVar("l4d_loot_pistol", "10", "", FCVAR_PLUGIN);
		l4d_loot_smg = CreateConVar("l4d_loot_smg", "10", "", FCVAR_PLUGIN);
		l4d_loot_pumpshotgun = CreateConVar("l4d_loot_pumpshotgun", "10", "", FCVAR_PLUGIN);
		l4d_loot_autoshotgun = CreateConVar("l4d_loot_autoshotgun", "10", "", FCVAR_PLUGIN);
		l4d_loot_hunting_rifle = CreateConVar("l4d_loot_hunting_rifle", "10", "", FCVAR_PLUGIN);
		l4d_loot_rifle = CreateConVar("l4d_loot_rifle", "10", "", FCVAR_PLUGIN);

		l4d_loot_pipe_bomb = CreateConVar("l4d_loot_pipe_bomb", "10", "", FCVAR_PLUGIN);
		l4d_loot_molotov = CreateConVar("l4d_loot_molotov", "10", "", FCVAR_PLUGIN);

		l4d_loot_gascan = CreateConVar("l4d_loot_gascan", "25", "", FCVAR_PLUGIN);
		l4d_loot_oxygentank = CreateConVar("l4d_loot_oxygentank", "25", "", FCVAR_PLUGIN);
		l4d_loot_propanetank = CreateConVar("l4d_loot_propanetank", "25", "", FCVAR_PLUGIN);

#if DEBUG
		RegConsoleCmd("sm_loot_test_group", LootTestGroup);
		RegConsoleCmd("sm_checkmodel", CheckModel);
#endif	
	}
}

public Loot_EnableDisable(Handle:hVariable, const String:strOldValue[], const String:strNewValue[])
{
    if (GetConVarInt(IsPluginEnabled) > 0) 
	{
		HookEvent("player_death", Event_PlayerDeath);
	}
    else
	{
		UnhookEvent("player_death", Event_PlayerDeath);
	}
}

#if DEBUG
public Action:CheckModel(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[L4DLOOT] Usage: sm_checkmodel <model_name>");
		return Plugin_Handled;
	}

	decl String:argstring[256];
	GetCmdArgString(argstring, sizeof(argstring));

	if (IsModelPrecached(argstring))
	{
		ReplyToCommand(client, "[precached]: %s", argstring);
	}
	else
	{
		ReplyToCommand(client, "[not precached]: %s", argstring);
	}
	return Plugin_Handled;
}
#endif

#if DEBUG
public Action:LootTestGroup(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[L4DLOOT] Usage: sm_loot_test_group <Hunter|Boomer|Smoker|Spitter|Charger|Jockey|Tank>");
		return Plugin_Handled;
	}

	decl String:argstring[10];
	GetCmdArgString(argstring, sizeof(argstring));

	new GroupCount[9];
		
	for (new i = 0; i < 100; i++)
	{
		GroupCount[GetRandomGroup(argstring)]++;
	}
	
	ReplyToCommand(client, "Group #1 (Health): %d", GroupCount[1]);
	ReplyToCommand(client, "Group #2 (Bullet): %d", GroupCount[2]);
	ReplyToCommand(client, "Group #3 (Throw): %d", GroupCount[3]);
	ReplyToCommand(client, "Group #4 (Misc): %d", GroupCount[4]);
	ReplyToCommand(client, "Group #5 (No-Drop): %d", GroupCount[0]);
	
	return Plugin_Handled;
}
#endif

public Action:Event_RoundStart(Handle:hEvent, const String:strName[], bool:DontBroadcast)
{
	IsMapFinished = 0;
}

public CheckPointReached(any:client)
{
	IsMapFinished = 1;
	if (GetConVarInt(NoFarmPanic) > 0)
	{
		new String:command[] = "director_force_panic_event";
		new flags = GetCommandFlags(command);
		SetCommandFlags(command, flags & ~FCVAR_CHEAT);
		FakeClientCommand(client, command);
		SetCommandFlags(command, flags);
	}
}

public Action:Event_CheckPoint(Handle:event, const String:name[], bool:dontBroadcast)
{
#if DEBUG
//	PrintToChatAll("\x05Event: CheckPoint (Start)");
#endif

	if (IsMapFinished > 0)
		return Plugin_Continue;
	
	new Target = GetClientOfUserId(GetEventInt(event, "userid"));
	decl String:strBuffer[128];
	GetEventString(event, "doorname", strBuffer, sizeof(strBuffer));
	
#if DEBUG
	PrintToChatAll("\x05Event: \x03CheckPoint ( \x01%N :: %s :: %d \x03 )", Target, strBuffer, GetEventInt(event, "area"));
#endif

	if (Target && (GetClientTeam(Target)) == 2)
	{
		if (StrEqual(strBuffer, "checkpoint_entrance", false))
		{
			CheckPointReached(Target);
		}
		else
		{
			new String:current_map[64];
			GetCurrentMap(current_map, 63);
			if (StrEqual(current_map, "l4d_garage01_alleys", false))
			{
				if (GetEventInt(event, "area") == 21211)
					CheckPointReached(Target);
			}
			else if (StrEqual(current_map, "l4d_smalltown04_mainstreet", false))
			{
				if (GetEventInt(event, "area") == 85093 || GetEventInt(event, "area") == 85038)
					CheckPointReached(Target);
			}
			else if (StrEqual(current_map, "l4d_farm01_hilltop", false))
			{
				if (GetEventInt(event, "area") == 60481)
					CheckPointReached(Target);
			}
		}
	}

#if DEBUG
//	PrintToChatAll("\x05Event: CheckPoint (End)");
#endif
	
	return Plugin_Continue;
}

public Action:Event_PlayerDeath(Handle:hEvent, const String:strName[], bool:DontBroadcast)
{
#if DEBUG
//	PrintToChatAll("\x05Event: PlayerDeath (Start)");
#endif

	if (GetConVarInt(NoFarm) > 0 && IsMapFinished > 0)
	{
		return Plugin_Continue;
	}

	decl String:strBuffer[48];
	new Attacker = GetClientOfUserId(GetEventInt(hEvent, "attacker"));

	if (Attacker == 0)
	{
#if DEBUG
		PrintToChatAll("\x05Event: \x04PlayerDeath : Attacker =\x01 0");
#endif
//		return Plugin_Continue;
	}
	else
	{
		decl String:AttackerSteamID[20];
		GetClientAuthString(Attacker, AttackerSteamID, sizeof(AttackerSteamID));

#if DEBUG
		PrintToServer("[L4DLOOT] Attacker :: %s", AttackerSteamID);
#endif
	
		if (StrEqual(AttackerSteamID, "BOT", false))
			return Plugin_Continue;
	}
		
	new Target = GetClientOfUserId(GetEventInt(hEvent, "userid"));

	if (Target == 0) 
		return Plugin_Continue;
		
	if (GetClientTeam(Target) != 3)
		return Plugin_Continue;

	decl String:ClientSteamID[20];
	GetClientAuthString(Target, ClientSteamID, sizeof(ClientSteamID));
	if (!StrEqual(ClientSteamID, "BOT", false) && GetConVarInt(DropItemsFromPlayers) == 0)
		return Plugin_Continue;
    
	GetEventString(hEvent, "victimname", strBuffer, sizeof(strBuffer));
	
#if PRINT_DROP
	PrintToServer("[L4DLOOT] DEAD :: %s", strBuffer);
#endif		
	
#if DEBUG
	PrintToChatAll("\x05Event: \x04PlayerDeath ( \x01%s\x04 )", strBuffer);
#endif
	
	if (StrEqual("Hunter", strBuffer, false))
	{
#if DEBUG
		PrintToChatAll("\x05Event: \x04PlayerDeath ( \x01%s\x04 ) : \x01%d", strBuffer, GetConVarInt(l4d_loot_h_drop_items));
#endif

		for (new i = 0; i < GetConVarInt(l4d_loot_h_drop_items); i++)
			LootDropItem(Target, GetRandomItem(GetRandomGroup(strBuffer)));
	}
	if (StrEqual("Boomer", strBuffer, false))
	{
#if DEBUG
		PrintToChatAll("\x05Event: \x04PlayerDeath ( \x01%s\x04 ) : \x01%d", strBuffer, GetConVarInt(l4d_loot_b_drop_items));
#endif

		for (new i = 0; i < GetConVarInt(l4d_loot_b_drop_items); i++)
			LootDropItem(Target, GetRandomItem(GetRandomGroup(strBuffer)));
	}
	else if (StrEqual("Smoker", strBuffer, false))
	{
#if DEBUG
		PrintToChatAll("\x05Event: \x04PlayerDeath ( \x01%s\x04 ) : \x01%d", strBuffer, GetConVarInt(l4d_loot_s_drop_items));
#endif

		for (new i = 0; i < GetConVarInt(l4d_loot_s_drop_items); i++)
			LootDropItem(Target, GetRandomItem(GetRandomGroup(strBuffer)));
	}
	else if (StrEqual("Tank", strBuffer, false))
	{
#if DEBUG
		PrintToChatAll("\x05Event: \x04PlayerDeath ( \x01%s\x04 ) : \x01%d", strBuffer, GetConVarInt(l4d_loot_t_drop_items));
#endif

		for (new i = 0; i < GetConVarInt(l4d_loot_t_drop_items); i++)
			LootDropItem(Target, GetRandomItem(GetRandomGroup(strBuffer)));
	}

	return Plugin_Continue;
}

stock GetGameMode()
{
	new String:GameMode[13];
	new Handle:gamecvar_mp_gamemode = FindConVar("mp_gamemode");
	GetConVarString(gamecvar_mp_gamemode, GameMode, sizeof(GameMode));
	if (StrEqual(GameMode, "coop", false) == true)
	{
		return 1;
	}
	else if (StrEqual(GameMode, "survival", false) == true)
	{
		return 2;
	}
	else if (StrEqual(GameMode, "versus", false) == true)
	{
		return 3;
	}
	else if (StrEqual(GameMode, "teamversus", false) == true)
	{
		return 4;
	}
	return 0;
}

stock GetRandomGroup(const String:BotDiedName[])
{
	if (GetConVarInt(l4d_loot_g_chance_nodrop) > 0)
	{
		new RND = GetRandomInt(1, 100);
		if (GetConVarInt(l4d_loot_g_chance_nodrop) >= RND)
		{
			// Global No-Drop

#if DEBUG
			PrintToChatAll("\x05 Function: \x04GetRandomGroup ( \x01%s\x04 ) : return 0 (global)", BotDiedName);
#endif

			return 0;
		}
	}
	
	new Sum = 0;
	if (StrEqual("Hunter", BotDiedName))
	{
		Sum = GetConVarInt(l4d_loot_h_chance_health);
		Sum = Sum + GetConVarInt(l4d_loot_h_chance_bullet);
		Sum = Sum + GetConVarInt(l4d_loot_h_chance_throw);
		Sum = Sum + GetConVarInt(l4d_loot_h_chance_misc)
		Sum = Sum + GetConVarInt(l4d_loot_h_chance_nodrop);
		if (Sum > 0)
		{
			new Float:X = 100.0 / Sum;
			new Float:Y = GetRandomFloat(0.0, 100.0);
			new Float:A = 0.0;
			new Float:B = GetConVarInt(l4d_loot_h_chance_health) * X;
			if (Y >= A && Y < A + B)
			{
				// Health Based Items

#if DEBUG
				PrintToChatAll("\x05 Function: \x04GetRandomGroup ( \x01%s\x04 ) : return 1", BotDiedName);
#endif

				return 1;
			}
			A = A + B;
			B = GetConVarInt(l4d_loot_h_chance_bullet) * X;
			if (Y >= A && Y < A + B)
			{
				// Bullet-Based Weapon

#if DEBUG
				PrintToChatAll("\x05 Function: \x04GetRandomGroup ( \x01%s\x04 ): return 2", BotDiedName);
#endif

				return 2;
			}
			A = A + B;
			B = GetConVarInt(l4d_loot_h_chance_throw) * X;
			if (Y >= A && Y < A + B)
			{
				// Throw-Based Weapon

#if DEBUG
				PrintToChatAll("\x05 Function: \x04GetRandomGroup ( \x01%s\x04 ) : return 3", BotDiedName);
#endif

				return 3;
			}
			A = A + B;
			B = GetConVarInt(l4d_loot_h_chance_misc) * X;
			if (Y >= A && Y < A + B)
			{
				// Misc

#if DEBUG
				PrintToChatAll("\x05 Function: \x04GetRandomGroup ( \x01%s\x04 ) : return 4", BotDiedName);
#endif

				return 4;
			}
			A = A + B;
			B = GetConVarInt(l4d_loot_h_chance_nodrop) * X;
			if (Y >= A && Y < A + B)
			{
				// Hunter No-Drop

#if DEBUG
				PrintToChatAll("\x05 Function: \x04GetRandomGroup ( \x01%s\x04 ) : return 0 (hunter)", BotDiedName);
#endif

				return 0;
			}
		}
		else
		{
#if DEBUG
			PrintToChatAll("\x05 Function: \x04GetRandomGroup ( \x01%s\x04 ): return 0 (else)", BotDiedName);
#endif

			return 0;
		}
	}
	if (StrEqual("Boomer", BotDiedName))
	{
		Sum = GetConVarInt(l4d_loot_b_chance_health);
		Sum = Sum + GetConVarInt(l4d_loot_b_chance_bullet);
		Sum = Sum + GetConVarInt(l4d_loot_b_chance_throw);
		Sum = Sum + GetConVarInt(l4d_loot_b_chance_misc);
		Sum = Sum + GetConVarInt(l4d_loot_b_chance_nodrop);
		if (Sum > 0)
		{
			new Float:X = 100.0 / Sum;
			new Float:Y = GetRandomFloat(0.0, 100.0);
			new Float:A = 0.0;
			new Float:B = GetConVarInt(l4d_loot_b_chance_health) * X;
			if (Y >= A && Y < A + B)
			{
				// Health Based Items

#if DEBUG
				PrintToChatAll("\x05 Function: \x04GetRandomGroup ( \x01%s\x04 ) : return 1", BotDiedName);
#endif

				return 1;
			}
			A = A + B;
			B = GetConVarInt(l4d_loot_b_chance_bullet) * X;
			if (Y >= A && Y < A + B)
			{
				// Bullet-Based Weapon

#if DEBUG
				PrintToChatAll("\x05 Function: \x04GetRandomGroup ( \x01%s\x04 ) : return 2", BotDiedName);
#endif

				return 2;
			}
			A = A + B;
			B = GetConVarInt(l4d_loot_b_chance_throw) * X;
			if (Y >= A && Y < A + B)
			{
				// Throw-Based Weapon

#if DEBUG
				PrintToChatAll("\x05 Function: \x04GetRandomGroup ( \x01%s\x04 ) : return 3", BotDiedName);
#endif

				return 3;
			}
			A = A + B;
			B = GetConVarInt(l4d_loot_b_chance_misc) * X;
			if (Y >= A && Y < A + B)
			{
				// Misc

#if DEBUG
				PrintToChatAll("\x05 Function: \x04GetRandomGroup ( \x01%s\x04 ) : return 4", BotDiedName);
#endif

				return 4;
			}
			A = A + B;
			B = GetConVarInt(l4d_loot_b_chance_nodrop) * X;
			if (Y >= A && Y < A + B)
			{
				// Boomer No-Drop

#if DEBUG
				PrintToChatAll("\x05 Function: \x04GetRandomGroup ( \x01%s\x04 ) : return 0 (boomer)", BotDiedName);
#endif

				return 0;
			}
		}
		else
		{
#if DEBUG
			PrintToChatAll("\x05 Function: \x04GetRandomGroup ( \x01%s\x04 ) : return 0 (else)", BotDiedName);
#endif

			return 0;
		}
	}
	if (StrEqual("Smoker", BotDiedName))
	{

#if DEBUG
		PrintToChatAll("\x05 Function: \x04GetRandomGroup ( \x01%s\x04 )", BotDiedName);
#endif

		Sum = GetConVarInt(l4d_loot_s_chance_health);
		Sum = Sum + GetConVarInt(l4d_loot_s_chance_bullet);
		Sum = Sum + GetConVarInt(l4d_loot_s_chance_throw);
		Sum = Sum + GetConVarInt(l4d_loot_s_chance_misc)
		Sum = Sum + GetConVarInt(l4d_loot_s_chance_nodrop);

#if DEBUG
		PrintToChatAll("\x05 Function: \x04GetRandomGroup ( \x01%s\x04 ) : Sum = %d", Sum);
#endif

		if (Sum > 0)
		{
			new Float:X = 100.0 / Sum;
			new Float:Y = GetRandomFloat(0.0, 100.0);
			new Float:A = 0.0;
			new Float:B = GetConVarInt(l4d_loot_s_chance_health) * X;

#if DEBUG
			PrintToChatAll("\x05 Function: \x04GetRandomGroup ( \x01%s\x04 ) : X = %f", X);
#endif

			if (Y >= A && Y < A + B)
			{
				// Health Based Items

#if DEBUG
				PrintToChatAll("\x05 Function: \x04GetRandomGroup ( \x01%s\x04 ) : return 1", BotDiedName);
#endif

				return 1;
			}
			A = A + B;
			B = GetConVarInt(l4d_loot_s_chance_bullet) * X;
			if (Y >= A && Y < A + B)
			{
				// Bullet-Based Weapon

#if DEBUG
				PrintToChatAll("\x05 Function: \x04GetRandomGroup ( \x01%s\x04 ) : return 2", BotDiedName);
#endif

				return 2;
			}
			A = A + B;
			B = GetConVarInt(l4d_loot_s_chance_throw) * X;
			if (Y >= A && Y < A + B)
			{
				// Throw-Based Weapon

#if DEBUG
				PrintToChatAll("\x05 Function: \x04GetRandomGroup ( \x01%s\x04 ) : return 3", BotDiedName);
#endif

				return 3;
			}
			A = A + B;
			B = GetConVarInt(l4d_loot_s_chance_misc) * X;
			if (Y >= A && Y < A + B)
			{
				// Misc

#if DEBUG
				PrintToChatAll("\x05 Function: \x04GetRandomGroup ( \x01%s\x04 ) : return 4", BotDiedName);
#endif

				return 4;
			}
			A = A + B;
			B = GetConVarInt(l4d_loot_s_chance_nodrop) * X;
			if (Y >= A && Y < A + B)
			{
				// Smoker No-Drop

#if DEBUG
				PrintToChatAll("\x05 Function: \x04GetRandomGroup ( \x01%s\x04 ) : return 0 (smoker)", BotDiedName);
#endif

				return 0;
			}
		}
		else
		{
#if DEBUG
			PrintToChatAll("\x05 Function: \x04GetRandomGroup ( \x01%s\x04 ) : return 0 (else)", BotDiedName);
#endif

			return 0;
		}
	}
	if (StrEqual("Tank", BotDiedName))
	{
		Sum = GetConVarInt(l4d_loot_t_chance_health);
		Sum = Sum + GetConVarInt(l4d_loot_t_chance_bullet);
		Sum = Sum + GetConVarInt(l4d_loot_t_chance_throw);
		Sum = Sum + GetConVarInt(l4d_loot_t_chance_misc)
		Sum = Sum + GetConVarInt(l4d_loot_t_chance_nodrop);
		if (Sum > 0)
		{
			new Float:X = 100.0 / Sum;
			new Float:Y = GetRandomFloat(0.0, 100.0);
			new Float:A = 0.0;
			new Float:B = GetConVarInt(l4d_loot_t_chance_health) * X;
			if (Y >= A && Y < A + B)
			{
				// Health Based Items

#if DEBUG
				PrintToChatAll("\x05 Function: \x04GetRandomGroup ( \x01%s\x04 ) : return 1", BotDiedName);
#endif

				return 1;
			}
			A = A + B;
			B = GetConVarInt(l4d_loot_t_chance_bullet) * X;
			if (Y >= A && Y < A + B)
			{
				// Bullet-Based Weapon

#if DEBUG
				PrintToChatAll("\x05 Function: \x04GetRandomGroup ( \x01%s\x04 ) : return 2", BotDiedName);
#endif

				return 2;
			}
			A = A + B;
			B = GetConVarInt(l4d_loot_t_chance_throw) * X;
			if (Y >= A && Y < A + B)
			{
				// Throw-Based Weapon

#if DEBUG
				PrintToChatAll("\x05 Function: \x04GetRandomGroup ( \x01%s\x04 ) : return 3", BotDiedName);
#endif

				return 3;
			}
			A = A + B;
			B = GetConVarInt(l4d_loot_t_chance_misc) * X;
			if (Y >= A && Y < A + B)
			{
				// Misc

#if DEBUG
				PrintToChatAll("\x05 Function: \x04GetRandomGroup ( \x01%s\x04 ) : return 4", BotDiedName);
#endif

				return 4;
			}
			A = A + B;
			B = GetConVarInt(l4d_loot_t_chance_nodrop) * X;
			if (Y >= A && Y < A + B)
			{
				// Tank No-Drop

#if DEBUG
				PrintToChatAll("\x05 Function: \x04GetRandomGroup ( \x01%s\x04 ) : return 0 (tank)", BotDiedName);
#endif

				return 0;
			}
		}
		else
		{
#if DEBUG
			PrintToChatAll("\x05 Function: \x04GetRandomGroup ( \x01%s\x04 ) : return 0 (else)", BotDiedName);
#endif

			return 0;
		}
	}

#if DEBUG
	PrintToChatAll("\x05 Function: \x04GetRandomGroup ( \x01%s\x04 ) : return 0 (end of function)", BotDiedName);
#endif

	return 0;
}

stock GetRandomItem(const Group)
{
#if DEBUG
	PrintToChatAll("\x05 Function: \x04GetRandomItem ( \x01%d\x04 )", Group);
#endif

	if (Group == 0)
	{

#if DEBUG
		PrintToChatAll("\x05 Function: \x04GetRandomItem ( \x01%d\x04 ) : return 0", Group);
#endif				
	
		return 0;
	}
	if (Group == 1)
	{
		new Sum = 0;
		if (IsModelPrecached("models/w_models/weapons/w_eq_Medkit.mdl"))
		{
			Sum = Sum + GetConVarInt(l4d_loot_first_aid_kit);
		}
		if (IsModelPrecached("models/w_models/weapons/w_eq_painpills.mdl"))
		{
			Sum = Sum + GetConVarInt(l4d_loot_pain_pills);
		}
		if (Sum > 0)
		{
			new Float:X = 100.0 / Sum;
			new Float:Y = GetRandomFloat(0.0, 100.0);
			new Float:A = 0.0;
			new Float:B = 0.0;
			if (IsModelPrecached("models/w_models/weapons/w_eq_Medkit.mdl"))
			{
				B = GetConVarInt(l4d_loot_first_aid_kit) * X;
				if (Y >= A && Y < A + B)
				{
					return 1;
				}
			}
			if (IsModelPrecached("models/w_models/weapons/w_eq_painpills.mdl"))
			{
				A = A + B;
				B = GetConVarInt(l4d_loot_pain_pills) * X;
				if (Y >= A && Y < A + B)
				{
					return 3;
				}
			}
		}
		else
		{
		
#if DEBUG
			PrintToChatAll("\x05 Function: \x04GetRandomItem ( \x01%d\x04 ) : return 0", Group);
#endif				
		
			return 0;
		}
	}
	if (Group == 2)
	{
		new Sum = 0;
		if (IsModelPrecached("models/w_models/weapons/w_pistol_1911.mdl"))
		{
			Sum = Sum + GetConVarInt(l4d_loot_pistol);
		}
		if (IsModelPrecached("models/w_models/weapons/w_smg_uzi.mdl"))
		{
			Sum = Sum + GetConVarInt(l4d_loot_smg);
		}
		if (IsModelPrecached("models/w_models/weapons/w_shotgun.mdl"))
		{
			Sum = Sum + GetConVarInt(l4d_loot_pumpshotgun);
		}
		if (IsModelPrecached("models/w_models/weapons/w_autoshot_m4super.mdl"))
		{
			Sum = Sum + GetConVarInt(l4d_loot_autoshotgun);
		}
		if (IsModelPrecached("models/w_models/weapons/w_sniper_mini14.mdl"))
		{
			Sum = Sum + GetConVarInt(l4d_loot_hunting_rifle);
		}
		if (IsModelPrecached("models/w_models/weapons/w_rifle_m16a2.mdl"))
		{
			Sum = Sum + GetConVarInt(l4d_loot_rifle);
		}
		if (Sum > 0)
		{
			new Float:X = 100.0 / Sum;
			new Float:Y = GetRandomFloat(0.0, 100.0);
			new Float:A = 0.0;
			new Float:B = 0.0;
			if (IsModelPrecached("models/w_models/weapons/w_pistol_1911.mdl"))
			{
				B = GetConVarInt(l4d_loot_pistol) * X;
				if (Y >= A && Y < A + B)
				{
					return 15;
				}
			}
			if (IsModelPrecached("models/w_models/weapons/w_smg_uzi.mdl"))
			{
				A = A + B;
				B = GetConVarInt(l4d_loot_smg) * X;
				if (Y >= A && Y < A + B)
				{
					return 17;
				}
			}
			if (IsModelPrecached("models/w_models/weapons/w_shotgun.mdl"))
			{
				A = A + B;
				B = GetConVarInt(l4d_loot_pumpshotgun) * X;
				if (Y >= A && Y < A + B)
				{
					return 20;
				}
			}
			if (IsModelPrecached("models/w_models/weapons/w_autoshot_m4super.mdl"))
			{
				A = A + B;
				B = GetConVarInt(l4d_loot_autoshotgun) * X;
				if (Y >= A && Y < A + B)
				{
					return 39;
				}
			}
			if (IsModelPrecached("models/w_models/weapons/w_sniper_mini14.mdl"))
			{
				A = A + B;
				B = GetConVarInt(l4d_loot_hunting_rifle) * X;
				if (Y >= A && Y < A + B)
				{
					return 26;
				}
			}
			if (IsModelPrecached("models/w_models/weapons/w_rifle_m16a2.mdl"))
			{
				A = A + B;
				B = GetConVarInt(l4d_loot_rifle) * X;
				if (Y >= A && Y < A + B)
				{
					return 27;
				}
			}
		}
		else
		{
		
#if DEBUG
			PrintToChatAll("\x05 Function: \x04GetRandomItem ( \x01%d\x04 ) : return 0", Group);
#endif				
			return 0;
		}
	}
	if (Group == 3)
	{
		new Sum = 0;
		if (IsModelPrecached("models/w_models/weapons/w_eq_pipebomb.mdl"))
		{
			Sum = Sum + GetConVarInt(l4d_loot_pipe_bomb);
		}
		if (IsModelPrecached("models/w_models/weapons/w_eq_molotov.mdl"))
		{
			Sum = Sum + GetConVarInt(l4d_loot_molotov);
		}
		if (Sum > 0)
		{
			new Float:X = 100.0 / Sum;
			new Float:Y = GetRandomFloat(0.0, 100.0);
			new Float:A = 0.0;
			new Float:B = 0.0;
			if (IsModelPrecached("models/w_models/weapons/w_eq_pipebomb.mdl"))
			{
				B = GetConVarInt(l4d_loot_pipe_bomb) * X;
				if (Y >= A && Y < A + B)
				{
					return 32;
				}
			}
			if (IsModelPrecached("models/w_models/weapons/w_eq_molotov.mdl"))
			{
				A = A + B;
				B = GetConVarInt(l4d_loot_molotov) * X;
				if (Y >= A && Y < A + B)
				{
					return 33;
				}
			}
		}
		else
		{
		
#if DEBUG
			PrintToChatAll("\x05 Function: \x04GetRandomItem ( \x01%d\x04 ) : return 0", Group);
#endif				
		
			return 0;
		}
	}
	if (Group == 4)
	{
		new Sum = 0;
		if (IsModelPrecached("models/props_junk/gascan001a.mdl"))
		{
			Sum = Sum + GetConVarInt(l4d_loot_gascan);
		}
		if (IsModelPrecached("models/props_equipment/oxygentank01.mdl"))
		{
			Sum = Sum + GetConVarInt(l4d_loot_oxygentank);
		}
		if (IsModelPrecached("models/props_junk/propanecanister001a.mdl"))
		{
			Sum = Sum + GetConVarInt(l4d_loot_propanetank);
		}
		if (Sum > 0)
		{
			new Float:X = 100.0 / Sum;
			new Float:Y = GetRandomFloat(0.0, 100.0);
			new Float:A = 0.0;
			new Float:B = 0.0;
			if (IsModelPrecached("models/props_junk/gascan001a.mdl"))
			{
				A = A + B;
				B = GetConVarInt(l4d_loot_gascan) * X;
				if (Y >= A && Y < A + B)
				{
					return 38;
				}
			}
			if (IsModelPrecached("models/props_equipment/oxygentank01.mdl"))
			{
				A = A + B;
				B = GetConVarInt(l4d_loot_oxygentank) * X;
				if (Y >= A && Y < A + B)
				{
					return 41;
				}
			}
			if (IsModelPrecached("models/props_junk/propanecanister001a.mdl"))
			{
				A = A + B;
				B = GetConVarInt(l4d_loot_propanetank) * X;
				if (Y >= A && Y < A + B)
				{
					return 42;
				}
			}
		}
		else
		{

#if DEBUG
			PrintToChatAll("\x05 Function: \x04GetRandomItem ( \x01%d\x04 ) : return 0", Group);
#endif				
		
			return 0;
		}
	}

#if DEBUG
	PrintToChatAll("\x05 Function: \x04GetRandomItem ( \x01%d\x04 ) : return 0");
#endif				
	
	return 0;
}

public LootDropItem(any:client, ItemNumber)
{
#if DEBUG
	PrintToChatAll("\x05Function: \x04LootDropItem ( \x01%d\x04 )", ItemNumber);
#endif

	if (IsMapFinished > 0)
	{
		if (GetConVarInt(NoFarm) > 0)
			return;
	}

	if (ItemNumber > 0)
	{
		new String:ItemName[24];
		switch (ItemNumber)
		{
			case 1: ItemName = "first_aid_kit";
			case 3: ItemName = "pain_pills";
			case 15: ItemName = "pistol";
			case 17: ItemName = "smg";
			case 20: ItemName = "pumpshotgun";
			case 26: ItemName = "hunting_rifle";
			case 27: ItemName = "rifle";
			case 32: ItemName = "pipe_bomb";
			case 33: ItemName = "molotov";
			case 38: ItemName = "gascan";
			case 39: ItemName = "autoshotgun";
			case 41: ItemName = "oxygentank";
			case 42: ItemName = "propanetank";
		}
		
		new flags = GetCommandFlags("give");
		SetCommandFlags("give", flags & ~FCVAR_CHEAT);

#if PRINT_DROP
		PrintToServer("[L4DLOOT] LOOT :: %s", ItemName);
#endif		

		FakeClientCommand(client, "give %s", ItemName);
		SetCommandFlags("give", flags);
	}
}