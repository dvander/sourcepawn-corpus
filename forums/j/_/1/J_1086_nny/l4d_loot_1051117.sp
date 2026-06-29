#include <sourcemod>

#define CVAR_FLAGS FCVAR_PLUGIN
#define PLUGIN_VERSION "1.1"
#define CS_GUNS false

public Plugin:myinfo = 
{
	name = "[L4D2] Loot",
	author = "",
	description = "Chance to drop something on the death of a zombie bosses.",
	version = PLUGIN_VERSION,
	url = ""
}

new Handle:CVarIsEnabled;
new Handle:CVarLootHunter;
new Handle:CVarLootHunterCycles;
new Handle:CVarLootHunterChance;
new Handle:CVarLootSmoker;
new Handle:CVarLootSmokerCycles;
new Handle:CVarLootSmokerChance;
new Handle:CVarLootBoomer;
new Handle:CVarLootBoomerCycles;
new Handle:CVarLootBoomerChance;
new Handle:CVarLootCharger;
new Handle:CVarLootChargerCycles;
new Handle:CVarLootChargerChance;
new Handle:CVarLootSpitter;
new Handle:CVarLootSpitterCycles;
new Handle:CVarLootSpitterChance;
new Handle:CVarLootJockey;
new Handle:CVarLootJockeyCycles;
new Handle:CVarLootJockeyChance;
new Handle:CVarLootTank;
new Handle:CVarLootTankCycles;
new Handle:CVarLootTankChance;
new Handle:CVarWitch;
new Handle:CVarDebug;


public OnPluginStart()
{
	SetRandomSeed(GetSysTickCount());
	
	CreateConVar("l4d_loot_ver", PLUGIN_VERSION, "Version of the infected loot drops plugins.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);

	CVarLootHunter = CreateConVar("l4d_loot_hunter_drop", "50", "Hunter RND (def=50)", FCVAR_PLUGIN);
	CVarLootHunterCycles = CreateConVar("l4d_loot_hunter_cycles", "2", "Hunter drop's cycles (def=2)", FCVAR_PLUGIN);
	CVarLootHunterChance = CreateConVar("l4d_loot_hunter_chance", "4", "Chance to drop something by hunter (1/x; def=4)", FCVAR_PLUGIN);

	CVarLootSmoker = CreateConVar("l4d_loot_smoker_drop", "100", "Smoker RND (def=100)", FCVAR_PLUGIN);
	CVarLootSmokerCycles = CreateConVar("l4d_loot_smoker_cycles", "5", "Smoker drop's cycles (def=5)", FCVAR_PLUGIN);
	CVarLootSmokerChance = CreateConVar("l4d_loot_smoker_chance", "3", "Chance to drop something by smoker (1/x; def=3)", FCVAR_PLUGIN);

	CVarLootBoomer = CreateConVar("l4d_loot_boomer_drop", "120", "Boomer RND (def=120)", FCVAR_PLUGIN);
	CVarLootBoomerCycles = CreateConVar("l4d_loot_boomer_cycles", "10", "Boomer drop's cycles (def=10)", FCVAR_PLUGIN);
	CVarLootBoomerChance = CreateConVar("l4d_loot_boomer_chance", "3", "Chance to drop something by boomer (1/x; def=3)", FCVAR_PLUGIN);

	CVarLootCharger = CreateConVar("l4d_loot_charger_drop", "90", "Charger RND (def=90)", FCVAR_PLUGIN);
	CVarLootChargerCycles = CreateConVar("l4d_loot_charger_cycles", "5", "Charger drop's cycles (def=5)", FCVAR_PLUGIN);
	CVarLootChargerChance = CreateConVar("l4d_loot_charger_chance", "2", "Chance to drop something by charger (1/x; def=2)", FCVAR_PLUGIN);

	CVarLootSpitter = CreateConVar("l4d_loot_spitter_drop", "90", "Spitter RND (def=90)", FCVAR_PLUGIN);
	CVarLootSpitterCycles = CreateConVar("l4d_loot_spitter_cycles", "7", "Spitter drop's cycles (def=7)", FCVAR_PLUGIN);
	CVarLootSpitterChance = CreateConVar("l4d_loot_spitter_chance", "3", "Chance to drop something by spitter (1/x; def=3)", FCVAR_PLUGIN);

	CVarLootJockey = CreateConVar("l4d_loot_jockey_drop", "75", "Jockey RND (def=75)", FCVAR_PLUGIN);
	CVarLootJockeyCycles = CreateConVar("l4d_loot_jockey_cycles", "2", "Jockey drop's cycles (def=2)", FCVAR_PLUGIN);
	CVarLootJockeyChance = CreateConVar("l4d_loot_jockey_chance", "5", "Chance to drop something by jockey (1/x; def=5)", FCVAR_PLUGIN);

	CVarLootTank = CreateConVar("l4d_loot_tank_drop", "140", "Tank RND (def=140)", FCVAR_PLUGIN);
	CVarLootTankCycles = CreateConVar("l4d_loot_tank_cycles", "30", "Boomer drop's cycles (def=30)", FCVAR_PLUGIN);
	CVarLootTankChance = CreateConVar("l4d_loot_tank_chance", "3", "Chance to drop something by tank (1/x; def=3)", FCVAR_PLUGIN);

        CVarDebug = CreateConVar("l4d_loot_debug", "0", "Show dev. information (def=0)", FCVAR_PLUGIN);
        CVarWitch = CreateConVar("l4d_loot_witch", "1", "Add some witches? (def=1)", FCVAR_PLUGIN);

	CVarIsEnabled = CreateConVar("l4d_loot_enabled", "1", "Is the plugin enabled.", FCVAR_PLUGIN);
	HookConVarChange(CVarIsEnabled, Loot_EnableDisable);
	
	// Change the enabled flag to the one the convar holds.
	if (GetConVarInt(CVarIsEnabled) == 1) 
	{
		HookEvent("player_death", Event_PlayerDeath);
	}
	else
	{
		UnhookEvent("player_death", Event_PlayerDeath);
	}
}

public Loot_EnableDisable(Handle:hVariable, const String:strOldValue[], const String:strNewValue[])
{
    if (GetConVarInt(CVarIsEnabled) == 1) 
	{
		HookEvent("player_death", Event_PlayerDeath);
	}
    else
	{
		UnhookEvent("player_death", Event_PlayerDeath);
	}
}

public Action:Event_PlayerDeath(Handle:hEvent, const String:strName[], bool:DontBroadcast)
{
	decl String:strBuffer[48];
	new ClientId    = 0;
	
	ClientId = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	
	if (ClientId == 0) 
		return Plugin_Continue;
    
	GetEventString(hEvent, "victimname", strBuffer, sizeof(strBuffer));
   
	if (StrEqual("Hunter", strBuffer))
	{
		for (new i = 0; i < GetConVarInt(CVarLootHunterCycles); i++)
		{
			if (GetRandomInt(1, GetConVarInt(CVarLootHunterChance)) == 1)
				SpawnItem(ClientId, 1, GetConVarInt(CVarLootHunter)); 
		}					  
	}
	else if (StrEqual("Smoker", strBuffer))
	{
		for (new i = 0; i < GetConVarInt(CVarLootSmokerCycles); i++)
		{
			if (GetRandomInt(1, GetConVarInt(CVarLootSmokerChance)) == 1)
				SpawnItem(ClientId, 1, GetConVarInt(CVarLootSmoker)); 
		}					  
	}
	else if (StrEqual("Boomer", strBuffer))
	{
		for (new i = 0; i < GetConVarInt(CVarLootBoomerCycles); i++)
		{
			if (GetRandomInt(1, GetConVarInt(CVarLootBoomerChance)) == 1)
				SpawnItem(ClientId, 1, GetConVarInt(CVarLootBoomer)); 
		}					  
	}
	else if (StrEqual("Charger", strBuffer))
	{
		for (new i = 0; i < GetConVarInt(CVarLootChargerCycles); i++)
		{
			if (GetRandomInt(1, GetConVarInt(CVarLootChargerChance)) == 1)
				SpawnItem(ClientId, 1, GetConVarInt(CVarLootCharger)); 
		}					  
	}
	else if (StrEqual("Spitter", strBuffer))
	{
		for (new i = 0; i < GetConVarInt(CVarLootSpitterCycles); i++)
		{
			if (GetRandomInt(1, GetConVarInt(CVarLootSpitterChance)) == 1)
				SpawnItem(ClientId, 1, GetConVarInt(CVarLootSpitter)); 
		}					  
	}
	else if (StrEqual("Jockey", strBuffer))
	{
		for (new i = 0; i < GetConVarInt(CVarLootJockeyCycles); i++)
		{
			if (GetRandomInt(1, GetConVarInt(CVarLootJockeyChance)) == 1)
				SpawnItem(ClientId, 1, GetConVarInt(CVarLootJockey)); 
		}					  
	}
	else if (StrEqual("Tank", strBuffer))
	{
		for (new i = 0; i < GetConVarInt(CVarLootTankCycles); i++)
		{
			if (GetRandomInt(1, GetConVarInt(CVarLootTankChance)) == 1)
				SpawnItem(ClientId, 1, GetConVarInt(CVarLootTank)); 
		}					  
	}
	if (GetConVarInt(CVarWitch) == 1)
	{
		if (GetRandomInt(1, 3) == 1)
			if (GetRandomInt(1, GetRandomInt(1, 25)) >= 15)
				ExecuteCommand(ClientId, "z_spawn", "witch auto");
	}
	return Plugin_Continue;
}

ExecuteCommand(Client, String:strCommand[], String:strParam1[])
{
	new flags = GetCommandFlags(strCommand);
    
	SetCommandFlags(strCommand, flags & ~FCVAR_CHEAT);
	FakeClientCommand(Client, "%s %s", strCommand, strParam1);
	SetCommandFlags(strCommand, flags);
}

Give(Client, String:itemId[], bool:sim = false)
{
	if (sim == false)
	{
		ExecuteCommand(Client, "give", itemId);
	}
}

SpawnItem(client, rnd, lootmax)
{
	new LootRND;

	if (rnd == 1)
	{
		LootRND = GetRandomInt(1, lootmax);	
	}
	else 
	{
		LootRND = GetRandomInt(1, GetRandomInt(1, lootmax));	
	}
	if (LootRND < 10)
	{
		new LootRND2 = GetRandomInt(1, 30)
		if (LootRND2 == 1)
		{
			Give(client, "cricket_bat");
			if (GetConVarInt(CVarDebug) == 1)
				PrintToChatAll("\x01[DEBUG] Random: %d (1-9 %d: cricket bat)", LootRND, LootRND2);
		}
		else if (LootRND2 == 2)
		{
			Give(client, "crowbar");
			if (GetConVarInt(CVarDebug) == 1)
				PrintToChatAll("\x01[DEBUG] Random: %d (1-9 %d: crowbar) \x03", LootRND, LootRND2);
		}
		else if (LootRND2 == 3)
		{
			Give(client, "fireaxe");
			if (GetConVarInt(CVarDebug) == 1)
				PrintToChatAll("\x01[DEBUG] Random: %d (1-9 %d: fireaxe) \x03", LootRND, LootRND2);
		}
		else if (LootRND2 == 4)
		{
			Give(client, "fireworkcrate");
			if (GetConVarInt(CVarDebug) == 1)
				PrintToChatAll("\x01[DEBUG] Random: %d (1-9 %d: fireworkcrate) \x03", LootRND, LootRND2);
		}
		else if (LootRND2 == 5)
		{
			Give(client, "katana");
			if (GetConVarInt(CVarDebug) == 1)
				PrintToChatAll("\x01[DEBUG] Random: %d (1-9 %d: katana) \x03", LootRND, LootRND2);
		}
		else if (LootRND2 >= 6 && LootRND2 <10)
		{
			Give(client, "chainsaw");
			if (GetConVarInt(CVarDebug) == 1)
				PrintToChatAll("\x01[DEBUG] Random: %d (1-9 %d: chainsaw) \x03", LootRND, LootRND2);
		}
		else if (LootRND2 == 10)
		{
			Give(client, "electric_guitar");
			if (GetConVarInt(CVarDebug) == 1)
				PrintToChatAll("\x01[DEBUG] Random: %d (1-9 %d: electric guitar) \x03", LootRND, LootRND2);
		}
		else if (LootRND2 == 11)
		{
			Give(client, "machete");
			if (GetConVarInt(CVarDebug) == 1)
				PrintToChatAll("\x01[DEBUG] Random: %d (1-9 %d: machete) \x03", LootRND, LootRND2);
		}
		else if (LootRND2 == 12)
		{
			Give(client, "tonfa");
			if (GetConVarInt(CVarDebug) == 1)
				PrintToChatAll("\x01[DEBUG] Random: %d (1-9 %d: tonfa) \x03", LootRND, LootRND2);
		}
		else if (LootRND2 == 13)
		{
			Give(client, "baseball_bat");
			if (GetConVarInt(CVarDebug) == 1)
				PrintToChatAll("\x01[DEBUG] Random: %d (1-9 %d: baseball bat) \x03", LootRND, LootRND2);
		} 
		else if (LootRND2 == 14)
		{
			Give(client, "frying_pan");
			if (GetConVarInt(CVarDebug) == 1)
				PrintToChatAll("\x01[DEBUG] Random: %d (1-9 %d: frying pan) \x03", LootRND, LootRND2);
		}
		else if (LootRND2 > 15)
		{
			if (GetConVarInt(CVarDebug) == 1)
				PrintToChatAll("\x01[DEBUG] Random: %d (1-9 %d: nothing) \x03", LootRND, LootRND2);
		}
	}
	else if (LootRND >= 10 && LootRND < 20)
	{
		new LootRND2 = GetRandomInt(1, 9)
		if (LootRND2 == 1)
		{
			Give(client, "pistol");
			if (GetConVarInt(CVarDebug) == 1)
				PrintToChatAll("\x01[DEBUG] Random: %d (10-19 1: pistol) \x03", LootRND);
		}
		else if (LootRND2 >= 2 && LootRND2 <5)
		{
			Give(client, "pistol_magnum");
			if (GetConVarInt(CVarDebug) == 1)
				PrintToChatAll("\x01[DEBUG] Random: %d (10-19 2-4: pistol_magnum) \x03", LootRND);
		}
	}
	else if (LootRND >= 20 && LootRND < 27)
	{
		Give(client, "adrenaline");
		if (GetConVarInt(CVarDebug) == 1)
			PrintToChatAll("\x01[DEBUG] Random: %d (20-26 adrenaline) \x03", LootRND);
	}
	else if (LootRND >= 27 && LootRND < 40)
	{
		new LootRND2 = GetRandomInt(1, 6)
		if (LootRND2 == 1)
		{
			Give(client, "molotov");
			if (GetConVarInt(CVarDebug) == 1)
				PrintToChatAll("\x01[DEBUG] Random: %d (27-40 1: molotov) \x03", LootRND);
		}
		else if (LootRND2 == 2)
		{
			Give(client, "pipe_bomb");
			if (GetConVarInt(CVarDebug) == 1)
				PrintToChatAll("\x01[DEBUG] Random: %d (27-40 2: pipe bomb) \x03", LootRND);
		}
		else if (LootRND2 == 3)
		{
			Give(client, "vomitjar");
			if (GetConVarInt(CVarDebug) == 1)
				PrintToChatAll("\x01[DEBUG] Random: %d (27-40 3: vomitjar) \x03", LootRND);
		}
	}
	else if (LootRND >= 40 && LootRND < 45)
	{
		new LootRND2 = GetRandomInt(1, 10)
		if (LootRND2 == 1)
		{
			Give(client, "smg");
			if (GetConVarInt(CVarDebug) == 1)
				PrintToChatAll("\x01[DEBUG] Random: %d (40-44 1: smg) \x03", LootRND);
		}
		else if (LootRND2 == 2)
		{
			#if CS_GUNS
				Give(client, "smg_mp5");
				if (GetConVarInt(CVarDebug) == 1)
					PrintToChatAll("\x01[DEBUG] Random: %d (40-44 2: smg mp5) \x03", LootRND);
			#endif
		}
		else if (LootRND2 == 3)
		{
			Give(client, "smg_silenced");
			if (GetConVarInt(CVarDebug) == 1)
				PrintToChatAll("\x01[DEBUG] Random: %d (40-44 3: smg silenced) \x03", LootRND);
		}
		else if (LootRND2 == 4)
		{
			Give(client, "pumpshotgun");
			if (GetConVarInt(CVarDebug) == 1)
				PrintToChatAll("\x01[DEBUG] Random: %d (40-44 4: pumpshotgun) \x03", LootRND);
		}
		else if (LootRND2 == 5)
		{
			Give(client, "shotgun_chrome");
			if (GetConVarInt(CVarDebug) == 1)
				PrintToChatAll("\x01[DEBUG] Random: %d (40-44 5: shotgun chrome) \x03", LootRND);
		}
		else if (LootRND2 == 6)
		{
			Give(client, "shotgun_spas");
			if (GetConVarInt(CVarDebug) == 1)
				PrintToChatAll("\x01[DEBUG] Random: %d (40-44 6: shotgun spas) \x03", LootRND);
		}
	}
	else if (LootRND >= 45 && LootRND < 51)
	{
		new LootRND2 = GetRandomInt(1, 4)
		if (LootRND2 == 1)
		{
			Give(client, "upgradepack_explosive");
			if (GetConVarInt(CVarDebug) == 1)
				PrintToChatAll("\x01[DEBUG] Random: %d (45-51 1: upgradepack explosive) \x03", LootRND);
		}
		else if (LootRND2 == 2)
		{
			Give(client, "upgradepack_incendiary");
			if (GetConVarInt(CVarDebug) == 1)
				PrintToChatAll("\x01[DEBUG] Random: %d (45-51 2: upgradepack incendiary) \x03", LootRND);
		}
		else if (LootRND2 == 3)
		{
			Give(client, "fireworkcrate");
			if (GetConVarInt(CVarDebug) == 1)
				PrintToChatAll("\x01[DEBUG] Random: %d (45-51 3: fireworkcrate) \x03", LootRND);
		}
		else if (LootRND2 == 4)
		{
			Give(client, "gascan");
			if (GetConVarInt(CVarDebug) == 1)
				PrintToChatAll("\x01[DEBUG] Random: %d (45-51 4: gascan) \x03", LootRND);
		}
	}
	else if (LootRND >= 51 && LootRND < 55)
	{
		Give(client, "defibrillator");
		if (GetConVarInt(CVarDebug) == 1)
			PrintToChatAll("\x01[DEBUG] Random: %d (51-54 defibrillator) \x03", LootRND);
	}
	else if (LootRND >= 55 && LootRND < 60)
	{
		new LootRND2 = GetRandomInt(1, 4)
		if (LootRND2 == 1)
		{
			#if CS_GUNS
				Give(client, "sniper_scout");
				if (GetConVarInt(CVarDebug) == 1)
					PrintToChatAll("\x01[DEBUG] Random: %d (55-59 1: sniper scout) \x03", LootRND);
			#endif
		}
		else if (LootRND2 == 2)
		{
			Give(client, "sniper_military");
			if (GetConVarInt(CVarDebug) == 1)
				PrintToChatAll("\x01[DEBUG] Random: %d (55-59 2: sniper military) \x03", LootRND);
		}
		else if (LootRND2 == 3)
		{
			#if CS_GUNS
				Give(client, "sniper_awp");
				if (GetConVarInt(CVarDebug) == 1)
					PrintToChatAll("\x01[DEBUG] Random: %d (55-59 3: sniper awp) \x03", LootRND);
			#endif
		}
		else if (LootRND2 == 4)
		{
			Give(client, "hunting_rifle");
			if (GetConVarInt(CVarDebug) == 1)
				PrintToChatAll("\x01[DEBUG] Random: %d (55-59 4: hunting rifle) \x03", LootRND);
		}
	}
	else if (LootRND >= 60 && LootRND < 70)
	{
		Give(client, "pain_pills");
		if (GetConVarInt(CVarDebug) == 1)
			PrintToChatAll("\x01[DEBUG] Random: %d (60-69 pain pills) \x03", LootRND);
	}

	else if (LootRND >= 70 && LootRND < 90)
	{
		new LootRND2 = GetRandomInt(1, 11)
		if (LootRND2 == 1)
		{
			Give(client, "rifle");
			if (GetConVarInt(CVarDebug) == 1)
				PrintToChatAll("\x01[DEBUG] Random: %d (70-89 1: rifle) \x03", LootRND);
		}
		else if (LootRND2 == 2)
		{
			Give(client, "rifle_desert");
			if (GetConVarInt(CVarDebug) == 1)
				PrintToChatAll("\x01[DEBUG] Random: %d (70-89 2: rifle desert) \x03", LootRND);
		}
		else if (LootRND2 == 3)
		{
			Give(client, "rifle_ak47");
			if (GetConVarInt(CVarDebug) == 1)
				PrintToChatAll("\x01[DEBUG] Random: %d (70-89 3: rifle ak47) \x03", LootRND);
		}
		else if (LootRND2 == 4)
		{
			Give(client, "grenade_launcher");
			if (GetConVarInt(CVarDebug) == 1)
				PrintToChatAll("\x01[DEBUG] Random: %d (70-89 4: grenade launcher) \x03", LootRND);
		}
		else if (LootRND2 == 5)
		{
			#if CS_GUNS
				Give(client, "rifle_sg552");
				if (GetConVarInt(CVarDebug) == 1)
					PrintToChatAll("\x01[DEBUG] Random: %d (70-89 5: rifle sg552) \x03", LootRND);
			#endif
		}
	}
	else if (LootRND >= 90)
	{
		Give(client, "first_aid_kit");
		if (GetConVarInt(CVarDebug) == 1)
			PrintToChatAll("\x01[DEBUG] Random: %d (90+ first aid kit) \x03", LootRND);
	}
}