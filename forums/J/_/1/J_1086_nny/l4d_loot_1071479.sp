#include <sourcemod>

#define CVAR_FLAGS FCVAR_PLUGIN
#define PLUGIN_VERSION "1.1c"
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

new Handle:IsPluginEnabled;
new Handle:DropItemsFromPlayers;

// Global
new Handle:L4D_loot_g_chance_nodrop;

// Hunter
new Handle:L4D_loot_h_drop_items;
new Handle:L4D_loot_h_chance_health;
new Handle:L4D_loot_h_chance_bullet;
new Handle:L4D_loot_h_chance_throw;
new Handle:L4D_loot_h_chance_misc;
new Handle:L4D_loot_h_chance_nodrop;

// Boomer
new Handle:L4D_loot_b_drop_items;
new Handle:L4D_loot_b_chance_health;
new Handle:L4D_loot_b_chance_bullet;
new Handle:L4D_loot_b_chance_throw;
new Handle:L4D_loot_b_chance_misc;
new Handle:L4D_loot_b_chance_nodrop;

// Smoker
new Handle:L4D_loot_s_drop_items;
new Handle:L4D_loot_s_chance_health;
new Handle:L4D_loot_s_chance_bullet;
new Handle:L4D_loot_s_chance_throw;
new Handle:L4D_loot_s_chance_misc;
new Handle:L4D_loot_s_chance_nodrop;

// Tank
new Handle:L4D_loot_t_drop_items;
new Handle:L4D_loot_t_chance_health;
new Handle:L4D_loot_t_chance_bullet;
new Handle:L4D_loot_t_chance_throw;
new Handle:L4D_loot_t_chance_misc;
new Handle:L4D_loot_t_chance_nodrop;

new Handle:L4D_loot_first_aid_kit;
new Handle:L4D_loot_pain_pills;

new Handle:L4D_loot_pistol;
new Handle:L4D_loot_smg;
new Handle:L4D_loot_pumpshotgun;
new Handle:L4D_loot_autoshotgun;
new Handle:L4D_loot_hunting_rifle;
new Handle:L4D_loot_rifle;

new Handle:L4D_loot_pipe_bomb;
new Handle:L4D_loot_molotov;

new Handle:L4D_loot_gascan;

public OnPluginStart()
{
	AddServerTag("loot");
	CreateConVar("l4d_loot_version", PLUGIN_VERSION, "Version of the [L4D] Loot.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	IsPluginEnabled = CreateConVar("l4d_loot", "1", "Is the plugin enabled.", FCVAR_PLUGIN);
	DropItemsFromPlayers = CreateConVar("l4d_loot_from_players", "0", "", FCVAR_PLUGIN);

	HookConVarChange(IsPluginEnabled, Loot_EnableDisable);

	if (GetConVarInt(IsPluginEnabled) == 1) 
	{
		HookEvent("player_death", Event_PlayerDeath);
	}
	else
	{
		UnhookEvent("player_death", Event_PlayerDeath);
	}

	L4D_loot_g_chance_nodrop = CreateConVar("L4D_loot_g_chance_nodrop", "0", "", FCVAR_PLUGIN);

	L4D_loot_h_drop_items = CreateConVar("L4D_loot_h_drop_items", "1", "", FCVAR_PLUGIN);
	L4D_loot_b_drop_items = CreateConVar("L4D_loot_b_drop_items", "1", "", FCVAR_PLUGIN);
	L4D_loot_s_drop_items = CreateConVar("L4D_loot_s_drop_items", "1", "", FCVAR_PLUGIN);
	L4D_loot_t_drop_items = CreateConVar("L4D_loot_t_drop_items", "1", "", FCVAR_PLUGIN);

	L4D_loot_h_chance_health = CreateConVar("L4D_loot_h_chance_health", "16", "", FCVAR_PLUGIN);
	L4D_loot_h_chance_bullet = CreateConVar("L4D_loot_h_chance_bullet", "15", "", FCVAR_PLUGIN);
	L4D_loot_h_chance_throw = CreateConVar("L4D_loot_h_chance_throw", "20", "", FCVAR_PLUGIN);
	L4D_loot_h_chance_misc = CreateConVar("L4D_loot_h_chance_misc", "10", "", FCVAR_PLUGIN);
	L4D_loot_h_chance_nodrop = CreateConVar("L4D_loot_h_chance_nodrop", "30", "", FCVAR_PLUGIN);

	L4D_loot_b_chance_health = CreateConVar("L4D_loot_b_chance_health", "16", "", FCVAR_PLUGIN);
	L4D_loot_b_chance_bullet = CreateConVar("L4D_loot_b_chance_bullet", "15", "", FCVAR_PLUGIN);
	L4D_loot_b_chance_throw = CreateConVar("L4D_loot_b_chance_throw", "20", "", FCVAR_PLUGIN);
	L4D_loot_b_chance_misc = CreateConVar("L4D_loot_b_chance_misc", "10", "", FCVAR_PLUGIN);
	L4D_loot_b_chance_nodrop = CreateConVar("L4D_loot_b_chance_nodrop", "30", "", FCVAR_PLUGIN);

	L4D_loot_s_chance_health = CreateConVar("L4D_loot_s_chance_health", "16", "", FCVAR_PLUGIN);
	L4D_loot_s_chance_bullet = CreateConVar("L4D_loot_s_chance_bullet", "15", "", FCVAR_PLUGIN);
	L4D_loot_s_chance_throw = CreateConVar("L4D_loot_s_chance_throw", "20", "", FCVAR_PLUGIN);
	L4D_loot_s_chance_misc = CreateConVar("L4D_loot_s_chance_misc", "10", "", FCVAR_PLUGIN);
	L4D_loot_s_chance_nodrop = CreateConVar("L4D_loot_s_chance_nodrop", "30", "", FCVAR_PLUGIN);

	L4D_loot_t_chance_health = CreateConVar("L4D_loot_t_chance_health", "15", "", FCVAR_PLUGIN);
	L4D_loot_t_chance_bullet = CreateConVar("L4D_loot_t_chance_bullet", "3", "", FCVAR_PLUGIN);
	L4D_loot_t_chance_throw = CreateConVar("L4D_loot_t_chance_throw", "4", "", FCVAR_PLUGIN);
	L4D_loot_t_chance_misc = CreateConVar("L4D_loot_t_chance_misc", "1", "", FCVAR_PLUGIN);
	L4D_loot_t_chance_nodrop = CreateConVar("L4D_loot_t_chance_nodrop", "0", "", FCVAR_PLUGIN);

	L4D_loot_first_aid_kit = CreateConVar("L4D_loot_first_aid_kit", "4", "", FCVAR_PLUGIN);
	L4D_loot_pain_pills = CreateConVar("L4D_loot_pain_pills", "5", "", FCVAR_PLUGIN);

	L4D_loot_pistol = CreateConVar("L4D_loot_pistol", "10", "", FCVAR_PLUGIN);
	L4D_loot_smg = CreateConVar("L4D_loot_smg", "10", "", FCVAR_PLUGIN);
	L4D_loot_pumpshotgun = CreateConVar("L4D_loot_pumpshotgun", "10", "", FCVAR_PLUGIN);
	L4D_loot_autoshotgun = CreateConVar("L4D_loot_autoshotgun", "10", "", FCVAR_PLUGIN);
	L4D_loot_hunting_rifle = CreateConVar("L4D_loot_hunting_rifle", "10", "", FCVAR_PLUGIN);
	L4D_loot_rifle = CreateConVar("L4D_loot_rifle", "10", "", FCVAR_PLUGIN);

	L4D_loot_pipe_bomb = CreateConVar("L4D_loot_pipe_bomb", "10", "", FCVAR_PLUGIN);
	L4D_loot_molotov = CreateConVar("L4D_loot_molotov", "10", "", FCVAR_PLUGIN);

	L4D_loot_gascan = CreateConVar("L4D_loot_gascan", "50", "", FCVAR_PLUGIN);

#if DEBUG
	RegConsoleCmd("sm_loot_test_group", LootTestGroup);
	RegConsoleCmd("sm_checkmodel", CheckModel);
#endif	
}

public Loot_EnableDisable(Handle:hVariable, const String:strOldValue[], const String:strNewValue[])
{
    if (GetConVarInt(IsPluginEnabled) == 1) 
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
		ReplyToCommand(client, "[L4DLOOT] Usage: sm_loot_test_group <Hunter|Boomer|Smoker|Tank>");
		return Plugin_Handled;
	}

	decl String:argstring[10];
	GetCmdArgString(argstring, sizeof(argstring));

	new GroupCount[6];
		
	for (new i = 0; i < 100; i++)
	{
		GroupCount[GetRandomGroup(argstring)]++;
	}
	
	ReplyToCommand(client, "Group #1 (Health): %d", GroupCount[1]);
	ReplyToCommand(client, "Group #2 (Bullet): %d", GroupCount[3]);
	ReplyToCommand(client, "Group #3 (Throw): %d", GroupCount[5]);
	ReplyToCommand(client, "Group #4 (Misc): %d", GroupCount[7]);
	ReplyToCommand(client, "Group #5 (No-Drop): %d", GroupCount[0]);
	
	return Plugin_Handled;
}
#endif

public Action:Event_PlayerDeath(Handle:hEvent, const String:strName[], bool:DontBroadcast)
{
#if DEBUG
//	PrintToChatAll("\x05Event: PlayerDeath (Start)");
#endif

	decl String:strBuffer[48];
	new Attacker = GetClientOfUserId(GetEventInt(hEvent, "attacker"));

	if (Attacker == 0)
	{
#if DEBUG
		PrintToChatAll("\x05Event: PlayerDeath : Attacker = 0");
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

	decl String:ClientSteamID[20];
	GetClientAuthString(Target, ClientSteamID, sizeof(ClientSteamID));
	if (!StrEqual(ClientSteamID, "BOT", false) && GetConVarInt(DropItemsFromPlayers) == 0)
		return Plugin_Continue;
    
	GetEventString(hEvent, "victimname", strBuffer, sizeof(strBuffer));
	
#if PRINT_DROP
	PrintToServer("[L4DLOOT] DEAD :: %s", strBuffer);
#endif		
	
#if DEBUG
	PrintToChatAll("\x05Event: PlayerDeath Target name : %s", strBuffer);
#endif
	
	if (StrEqual("Hunter", strBuffer, false))
	{
#if DEBUG
		PrintToChatAll("\x05Event: PlayerDeath : %s (%d)", strBuffer, GetConVarInt(L4D_loot_h_drop_items));
#endif

		for (new i = 0; i < GetConVarInt(L4D_loot_h_drop_items); i++)
			LootDropItem(Target, GetRandomItem(GetRandomGroup(strBuffer)));
	}
	if (StrEqual("Boomer", strBuffer, false))
	{
#if DEBUG
		PrintToChatAll("\x05Event: PlayerDeath : %s (%d)", strBuffer, GetConVarInt(L4D_loot_b_drop_items));
#endif

		for (new i = 0; i < GetConVarInt(L4D_loot_b_drop_items); i++)
			LootDropItem(Target, GetRandomItem(GetRandomGroup(strBuffer)));
	}
	else if (StrEqual("Smoker", strBuffer, false))
	{
#if DEBUG
		PrintToChatAll("\x05Event: PlayerDeath : %s (%d)", strBuffer, GetConVarInt(L4D_loot_s_drop_items));
#endif

		for (new i = 0; i < GetConVarInt(L4D_loot_s_drop_items); i++)
			LootDropItem(Target, GetRandomItem(GetRandomGroup(strBuffer)));
	}
	else if (StrEqual("Tank", strBuffer, false))
	{
#if DEBUG
		PrintToChatAll("\x05Event: PlayerDeath : %s (%d)", strBuffer, GetConVarInt(L4D_loot_t_drop_items));
#endif

		for (new i = 0; i < GetConVarInt(L4D_loot_t_drop_items); i++)
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
		return 3;
	}
	else if (StrEqual(GameMode, "versus", false) == true)
	{
		return 4;
	}
	else if (StrEqual(GameMode, "teamversus", false) == true)
	{
		return 5;
	}
	return 0;
}

stock GetRandomGroup(const String:BotDiedName[])
{
#if DEBUG
	PrintToChatAll("\x05 Function: GetRandomGroup");
#endif

	new Sum = 0;
	if (StrEqual("Hunter", BotDiedName))
	{
		Sum = GetConVarInt(L4D_loot_h_chance_health);
		Sum = Sum + GetConVarInt(L4D_loot_h_chance_bullet);
		Sum = Sum + GetConVarInt(L4D_loot_h_chance_throw);
		Sum = Sum + GetConVarInt(L4D_loot_h_chance_misc) + GetConVarInt(L4D_loot_h_chance_nodrop);
		Sum = Sum + GetConVarInt(L4D_loot_g_chance_nodrop);
		if (Sum > 0)
		{
			new Float:X = 100.0 / Sum;
			new Float:Y = GetRandomFloat(0.0, 100.0);
			new Float:A = 0.0;
			new Float:B = GetConVarInt(L4D_loot_h_chance_health) * X;
			if (Y >= A && Y < A + B)
			{
				// Health Based Items

#if DEBUG
				PrintToChatAll("\x05 Function: GetRandomGroup : return 1");
#endif

				return 1;
			}
			A = A + B;
			B = GetConVarInt(L4D_loot_h_chance_bullet) * X;
			if (Y >= A && Y < A + B)
			{
				// Bullet-Based Weapon

#if DEBUG
				PrintToChatAll("\x05 Function: GetRandomGroup : return 3");
#endif

				return 3;
			}
			A = A + B;
			B = GetConVarInt(L4D_loot_h_chance_throw) * X;
			if (Y >= A && Y < A + B)
			{
				// Throw-Based Weapon

#if DEBUG
				PrintToChatAll("\x05 Function: GetRandomGroup : return 5");
#endif

				return 5;
			}
			A = A + B;
			B = GetConVarInt(L4D_loot_h_chance_misc) * X;
			if (Y >= A && Y < A + B)
			{
				// Misc

#if DEBUG
				PrintToChatAll("\x05 Function: GetRandomGroup : return 7");
#endif

				return 7;
			}
			A = A + B;
			B = GetConVarInt(L4D_loot_h_chance_nodrop) * X;
			if (Y >= A && Y < A + B)
			{
				// Hunter No-Drop

#if DEBUG
				PrintToChatAll("\x05 Function: GetRandomGroup : return 0 (hunter)");
#endif

				return 0;
			}
			A = A + B;
			B = GetConVarInt(L4D_loot_g_chance_nodrop) * X;
			if (Y >= A && Y < A + B)
			{
				// Global No-Drop

#if DEBUG
				PrintToChatAll("\x05 Function: GetRandomGroup : return 0 (global)");
#endif

				return 0;
			}
		}
		else
		{
#if DEBUG
			PrintToChatAll("\x05 Function: GetRandomGroup : return 0 (else)");
#endif

			return 0;
		}
	}
	if (StrEqual("Boomer", BotDiedName))
	{
		Sum = GetConVarInt(L4D_loot_b_chance_health);
		Sum = Sum + GetConVarInt(L4D_loot_b_chance_bullet);
		Sum = Sum + GetConVarInt(L4D_loot_b_chance_throw);
		Sum = Sum + GetConVarInt(L4D_loot_b_chance_misc) + GetConVarInt(L4D_loot_b_chance_nodrop);
		Sum = Sum + GetConVarInt(L4D_loot_g_chance_nodrop);
		if (Sum > 0)
		{
			new Float:X = 100.0 / Sum;
			new Float:Y = GetRandomFloat(0.0, 100.0);
			new Float:A = 0.0;
			new Float:B = GetConVarInt(L4D_loot_b_chance_health) * X;
			if (Y >= A && Y < A + B)
			{
				// Health Based Items

#if DEBUG
				PrintToChatAll("\x05 Function: GetRandomGroup : return 1");
#endif

				return 1;
			}
			A = A + B;
			B = GetConVarInt(L4D_loot_b_chance_bullet) * X;
			if (Y >= A && Y < A + B)
			{
				// Bullet-Based Weapon

#if DEBUG
				PrintToChatAll("\x05 Function: GetRandomGroup : return 3");
#endif

				return 3;
			}
			A = A + B;
			B = GetConVarInt(L4D_loot_b_chance_throw) * X;
			if (Y >= A && Y < A + B)
			{
				// Throw-Based Weapon

#if DEBUG
				PrintToChatAll("\x05 Function: GetRandomGroup : return 5");
#endif

				return 5;
			}
			A = A + B;
			B = GetConVarInt(L4D_loot_b_chance_misc) * X;
			if (Y >= A && Y < A + B)
			{
				// Misc

#if DEBUG
				PrintToChatAll("\x05 Function: GetRandomGroup : return 7");
#endif

				return 7;
			}
			A = A + B;
			B = GetConVarInt(L4D_loot_b_chance_nodrop) * X;
			if (Y >= A && Y < A + B)
			{
				// Boomer No-Drop

#if DEBUG
				PrintToChatAll("\x05 Function: GetRandomGroup : return 0 (boomer)");
#endif

				return 0;
			}
			A = A + B;
			B = GetConVarInt(L4D_loot_g_chance_nodrop) * X;
			if (Y >= A && Y < A + B)
			{
				// Global No-Drop

#if DEBUG
				PrintToChatAll("\x05 Function: GetRandomGroup : return 0 (global)");
#endif

				return 0;
			}
		}
		else
		{
#if DEBUG
			PrintToChatAll("\x05 Function: GetRandomGroup : return 0 (else)");
#endif

			return 0;
		}
	}
	if (StrEqual("Smoker", BotDiedName))
	{

#if DEBUG
		PrintToChatAll("\x05 Function: GetRandomGroup : Died Smoker");
#endif

		Sum = GetConVarInt(L4D_loot_s_chance_health);
		Sum = Sum + GetConVarInt(L4D_loot_s_chance_bullet);
		Sum = Sum + GetConVarInt(L4D_loot_s_chance_throw);
		Sum = Sum + GetConVarInt(L4D_loot_s_chance_misc) + GetConVarInt(L4D_loot_s_chance_nodrop);
		Sum = Sum + GetConVarInt(L4D_loot_g_chance_nodrop);

#if DEBUG
		PrintToChatAll("\x05 Function: GetRandomGroup : Sum = %d", Sum);
#endif

		if (Sum > 0)
		{
			new Float:X = 100.0 / Sum;
			new Float:Y = GetRandomFloat(0.0, 100.0);
			new Float:A = 0.0;
			new Float:B = GetConVarInt(L4D_loot_s_chance_health) * X;

#if DEBUG
			PrintToChatAll("\x05 Function: GetRandomGroup : X = %f", X);
#endif

			if (Y >= A && Y < A + B)
			{
				// Health Based Items

#if DEBUG
				PrintToChatAll("\x05 Function: GetRandomGroup : return 1");
#endif

				return 1;
			}
			A = A + B;
			B = GetConVarInt(L4D_loot_s_chance_bullet) * X;
			if (Y >= A && Y < A + B)
			{
				// Bullet-Based Weapon

#if DEBUG
				PrintToChatAll("\x05 Function: GetRandomGroup : return 3");
#endif

				return 3;
			}
			A = A + B;
			B = GetConVarInt(L4D_loot_s_chance_throw) * X;
			if (Y >= A && Y < A + B)
			{
				// Throw-Based Weapon

#if DEBUG
				PrintToChatAll("\x05 Function: GetRandomGroup : return 5");
#endif

				return 5;
			}
			A = A + B;
			B = GetConVarInt(L4D_loot_s_chance_misc) * X;
			if (Y >= A && Y < A + B)
			{
				// Misc

#if DEBUG
				PrintToChatAll("\x05 Function: GetRandomGroup : return 7");
#endif

				return 7;
			}
			A = A + B;
			B = GetConVarInt(L4D_loot_s_chance_nodrop) * X;
			if (Y >= A && Y < A + B)
			{
				// Smoker No-Drop

#if DEBUG
				PrintToChatAll("\x05 Function: GetRandomGroup : return 0 (smoker)");
#endif

				return 0;
			}
			A = A + B;
			B = GetConVarInt(L4D_loot_g_chance_nodrop) * X;
			if (Y >= A && Y < A + B)
			{
				// Global No-Drop

#if DEBUG
				PrintToChatAll("\x05 Function: GetRandomGroup : return 0 (global)");
#endif

				return 0;
			}
		}
		else
		{
#if DEBUG
			PrintToChatAll("\x05 Function: GetRandomGroup : return 0 (else)");
#endif

			return 0;
		}
	}
	if (StrEqual("Tank", BotDiedName))
	{
		Sum = GetConVarInt(L4D_loot_t_chance_health);
		Sum = Sum + GetConVarInt(L4D_loot_t_chance_bullet);
		Sum = Sum + GetConVarInt(L4D_loot_t_chance_throw);
		Sum = Sum + GetConVarInt(L4D_loot_t_chance_misc) + GetConVarInt(L4D_loot_t_chance_nodrop);
		Sum = Sum + GetConVarInt(L4D_loot_g_chance_nodrop);
		if (Sum > 0)
		{
			new Float:X = 100.0 / Sum;
			new Float:Y = GetRandomFloat(0.0, 100.0);
			new Float:A = 0.0;
			new Float:B = GetConVarInt(L4D_loot_t_chance_health) * X;
			if (Y >= A && Y < A + B)
			{
				// Health Based Items

#if DEBUG
				PrintToChatAll("\x05 Function: GetRandomGroup : return 1");
#endif

				return 1;
			}
			A = A + B;
			B = GetConVarInt(L4D_loot_t_chance_bullet) * X;
			if (Y >= A && Y < A + B)
			{
				// Bullet-Based Weapon

#if DEBUG
				PrintToChatAll("\x05 Function: GetRandomGroup : return 3");
#endif

				return 3;
			}
			A = A + B;
			B = GetConVarInt(L4D_loot_t_chance_throw) * X;
			if (Y >= A && Y < A + B)
			{
				// Throw-Based Weapon

#if DEBUG
				PrintToChatAll("\x05 Function: GetRandomGroup : return 5");
#endif

				return 5;
			}
			A = A + B;
			B = GetConVarInt(L4D_loot_t_chance_misc) * X;
			if (Y >= A && Y < A + B)
			{
				// Misc

#if DEBUG
				PrintToChatAll("\x05 Function: GetRandomGroup : return 7");
#endif

				return 7;
			}
			A = A + B;
			B = GetConVarInt(L4D_loot_t_chance_nodrop) * X;
			if (Y >= A && Y < A + B)
			{
				// Tank No-Drop

#if DEBUG
				PrintToChatAll("\x05 Function: GetRandomGroup : return 0 (tank)");
#endif

				return 0;
			}
			A = A + B;
			B = GetConVarInt(L4D_loot_g_chance_nodrop) * X;
			if (Y >= A && Y < A + B)
			{
				// Global No-Drop

#if DEBUG
				PrintToChatAll("\x05 Function: GetRandomGroup : return 0 (global)");
#endif

				return 0;
			}
		}
		else
		{
#if DEBUG
			PrintToChatAll("\x05 Function: GetRandomGroup : return 0 (else)");
#endif

			return 0;
		}
	}

#if DEBUG
	PrintToChatAll("\x05 Function: GetRandomGroup : return 0 (end of function)");
#endif

	return 0;
}

stock GetRandomItem(const Group)
{
#if DEBUG
	PrintToChatAll("\x05 Function: GetRandomItem");
#endif

	if (Group == 0)
		return 0;
	if (Group == 1)
	{
		new Sum = 0;
		if (IsModelPrecached("models/w_models/weapons/w_eq_Medkit.mdl"))
		{
			Sum = Sum + GetConVarInt(L4D_loot_first_aid_kit);
		}
		if (IsModelPrecached("models/w_models/weapons/w_eq_painpills.mdl"))
		{
			Sum = Sum + GetConVarInt(L4D_loot_pain_pills);
		}
		if (Sum > 0)
		{
			new Float:X = 100.0 / Sum;
			new Float:Y = GetRandomFloat(0.0, 100.0);
			new Float:A = 0.0;
			new Float:B = 0.0;
			if (IsModelPrecached("models/w_models/weapons/w_eq_Medkit.mdl"))
			{
				B = GetConVarInt(L4D_loot_first_aid_kit) * X;
				if (Y >= A && Y < A + B)
				{
					return 1;
				}
			}
			if (IsModelPrecached("models/w_models/weapons/w_eq_painpills.mdl"))
			{
				A = A + B;
				B = GetConVarInt(L4D_loot_pain_pills) * X;
				if (Y >= A && Y < A + B)
				{
					return 3;
				}
			}
		}
		else
		{
			return 0;
		}
	}
	if (Group == 2)
	{
		return 0;		
	}
	if (Group == 3)
	{
		new Sum = 0;
		if (IsModelPrecached("models/w_models/weapons/w_pistol_1911.mdl"))
		{
			Sum = Sum + GetConVarInt(L4D_loot_pistol);
		}
		if (IsModelPrecached("models/w_models/weapons/w_smg_uzi.mdl"))
		{
			Sum = Sum + GetConVarInt(L4D_loot_smg);
		}
		if (IsModelPrecached("models/w_models/weapons/w_shotgun.mdl"))
		{
			Sum = Sum + GetConVarInt(L4D_loot_pumpshotgun);
		}
		if (IsModelPrecached("models/w_models/weapons/w_autoshot_m4super.mdl"))
		{
			Sum = Sum + GetConVarInt(L4D_loot_autoshotgun);
		}
		if (IsModelPrecached("models/w_models/weapons/w_rifle_m16a2.mdl"))
		{
			Sum = Sum + GetConVarInt(L4D_loot_rifle);
		}
		if (IsModelPrecached("models/w_models/weapons/w_sniper_mini14.mdl"))
		{
			Sum = Sum + GetConVarInt(L4D_loot_hunting_rifle);
		}
		if (Sum > 0)
		{
			new Float:X = 100.0 / Sum;
			new Float:Y = GetRandomFloat(0.0, 100.0);
			new Float:A = 0.0;
			new Float:B = 0.0;
			if (IsModelPrecached("models/w_models/weapons/w_pistol_1911.mdl"))
			{
				B = GetConVarInt(L4D_loot_pistol) * X;
				if (Y >= A && Y < A + B)
				{
					return 15;
				}
			}
			if (IsModelPrecached("models/w_models/weapons/w_smg_uzi.mdl"))
			{
				A = A + B;
				B = GetConVarInt(L4D_loot_smg) * X;
				if (Y >= A && Y < A + B)
				{
					return 17;
				}
			}
			if (IsModelPrecached("models/w_models/weapons/w_shotgun.mdl"))
			{
				A = A + B;
				B = GetConVarInt(L4D_loot_pumpshotgun) * X;
				if (Y >= A && Y < A + B)
				{
					return 20;
				}
			}
			if (IsModelPrecached("models/w_models/weapons/w_autoshot_m4super.mdl"))
			{
				A = A + B;
				B = GetConVarInt(L4D_loot_autoshotgun) * X;
				if (Y >= A && Y < A + B)
				{
					return 39;
				}
			}
			if (IsModelPrecached("models/w_models/weapons/w_sniper_mini14.mdl"))
			{
				A = A + B;
				B = GetConVarInt(L4D_loot_hunting_rifle) * X;
				if (Y >= A && Y < A + B)
				{
					return 26;
				}
			}
			if (IsModelPrecached("models/w_models/weapons/w_rifle_m16a2.mdl"))
			{
				A = A + B;
				B = GetConVarInt(L4D_loot_rifle) * X;
				if (Y >= A && Y < A + B)
				{
					return 27;
				}
			}
		}
		else
		{
			return 0;
		}
	}
	if (Group == 4)
	{
		return 0;	
	}
	if (Group == 5)
	{
		new Sum = 0;
		if (IsModelPrecached("models/w_models/weapons/w_eq_pipebomb.mdl"))
		{
			Sum = Sum + GetConVarInt(L4D_loot_pipe_bomb);
		}
		if (IsModelPrecached("models/w_models/weapons/w_eq_molotov.mdl"))
		{
			Sum = Sum + GetConVarInt(L4D_loot_molotov);
		}
		if (Sum > 0)
		{
			new Float:X = 100.0 / Sum;
			new Float:Y = GetRandomFloat(0.0, 100.0);
			new Float:A = 0.0;
			new Float:B = 0.0;
			if (IsModelPrecached("models/w_models/weapons/w_eq_pipebomb.mdl"))
			{
				B = GetConVarInt(L4D_loot_pipe_bomb) * X;
				if (Y >= A && Y < A + B)
				{
					return 32;
				}
			}
			if (IsModelPrecached("models/w_models/weapons/w_eq_molotov.mdl"))
			{
				A = A + B;
				B = GetConVarInt(L4D_loot_molotov) * X;
				if (Y >= A && Y < A + B)
				{
					return 33;
				}
			}
		}
		else
		{
			return 0;
		}
	}
	if (Group == 6)
	{
		return 0;
	}
	if (Group == 7)
	{
		new Sum = 0;
		if (IsModelPrecached("models/props_junk/gascan001a.mdl"))
		{
			Sum = Sum + GetConVarInt(L4D_loot_gascan);
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
				B = GetConVarInt(L4D_loot_gascan) * X;
				if (Y >= A && Y < A + B)
				{
					return 38;
				}
			}
		}
		else
		{
			return 0;
		}
	}
	return 0;
}

public LootDropItem(any:client, ItemNumber)
{
#if DEBUG
	PrintToChatAll("\x05Function: LootDropItem (%d)", ItemNumber);
#endif

	if (ItemNumber > 0)
	{
		new String:ItemName[24];
		switch (ItemNumber)
		{
			case 1: ItemName = "first_aid_kit";
			case 2: ItemName = "defibrillator";
			case 3: ItemName = "pain_pills";
			case 4: ItemName = "adrenaline";
			case 5: ItemName = "cricket_bat";
			case 6: ItemName = "crowbar";
			case 7: ItemName = "electric_guitar";
			case 8: ItemName = "chainsaw";
			case 9: ItemName = "katana";
			case 10: ItemName = "machete";
			case 11: ItemName = "tonfa";
			case 12: ItemName = "baseball_bat";
			case 13: ItemName = "frying_pan";
			case 14: ItemName = "fireaxe";
			case 15: ItemName = "pistol";
			case 16: ItemName = "pistol_magnum";
			case 17: ItemName = "smg";
			case 18: ItemName = "smg_mp5";
			case 19: ItemName = "smg_silenced";
			case 20: ItemName = "pumpshotgun";
			case 21: ItemName = "shotgun_chrome";
			case 22: ItemName = "shotgun_spas";
			case 23: ItemName = "sniper_scout";
			case 24: ItemName = "sniper_military";
			case 25: ItemName = "sniper_awp";
			case 26: ItemName = "hunting_rifle";
			case 27: ItemName = "rifle";
			case 28: ItemName = "rifle_desert";
			case 29: ItemName = "rifle_ak47";
			case 30: ItemName = "rifle_sg552";
			case 31: ItemName = "grenade_launcher";
			case 32: ItemName = "pipe_bomb";
			case 33: ItemName = "molotov";
			case 34: ItemName = "vomitjar";
			case 35: ItemName = "upgradepack_explosive";
			case 36: ItemName = "upgradepack_incendiary";
			case 37: ItemName = "fireworkcrate";
			case 38: ItemName = "gascan";
			case 39: ItemName = "autoshotgun";
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