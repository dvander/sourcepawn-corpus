#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#include <ps_natives>

#define PLUGIN_VERSION "1.3"
#define PS_ModuleName "\nBuy Extended Support Structure(BESS Module)"

new Handle:h_Enable = INVALID_HANDLE;
new Handle:h_Trie = INVALID_HANDLE;
new bool:loaded = false;

public Plugin:myinfo = 
{
	name = "[PS] Buy Extended Support Structure(BESS Module)",
	author = "McFlurry",
	description = "Module to extend buy support, example: !buy pills // this would buy you pills",
	version = PLUGIN_VERSION,
	url = "N/A"
}

public OnPluginStart()
{
	h_Trie = CreateTrie();
	decl String:game_name[64];
	GetGameFolderName(game_name, sizeof(game_name));
	if (!StrEqual(game_name, "left4dead2", false))
	{
		SetFailState("Plugin supports Left 4 Dead 2 only.");
	}
	CreateConVar("ps_bess_version", PLUGIN_VERSION, "Version of bess module", FCVAR_PLUGIN|FCVAR_DONTRECORD|FCVAR_NOTIFY|FCVAR_REPLICATED);
	h_Enable = CreateConVar("ps_bess_enable", "1", "Enable BESS Module", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	RegConsoleCmd("sm_buy", Cmd_Buy);
	/* RegConsoleCmd("sm_buyhelp", Cmd_Help); */
	AutoExecConfig(true, "ps_bess");
}

public OnAllPluginsLoaded()
{
	new Float:min = 1.62;
	if(LibraryExists("ps_natives"))
	{
		if(PS_GetVersion() >= min)
		{
			if(PS_RegisterModule(PS_ModuleName)) LogMessage("[PS] Plugin of same name already registered");
			SetUpBuyTrie();
			loaded = true;
		}	
		else
		{
			SetFailState("[PS] Incompatible version of points system is loaded! Please update!");
		}	
	}
	else
	{
		SetFailState("[PS] PS Natives aren't loaded!");
	}	
}

public OnPluginEnd()
{
	PS_UnregisterModule(PS_ModuleName);
	CloseHandle(h_Trie);
}

public OnPSUnloaded()
{
	loaded = false;
}	

public OnConfigsExecuted()
{
	UpdateBuyTrie();
}	

public SetUpBuyTrie()
{
	//health
	SetTrieString(h_Trie, "pills", "give pain_pills");
	SetTrieValue(h_Trie, "pillscost", GetConVarInt(FindConVar("l4d2_points_pills")));
	SetTrieString(h_Trie, "kit", "give first_aid_kit");
	SetTrieValue(h_Trie, "kitcost", GetConVarInt(FindConVar("l4d2_points_kit")));
	SetTrieString(h_Trie, "defib", "give defibrillator");
	SetTrieValue(h_Trie, "defibcost", GetConVarInt(FindConVar("l4d2_points_defib")));
	SetTrieString(h_Trie, "adren", "give adrenaline");
	SetTrieValue(h_Trie, "adrencost", GetConVarInt(FindConVar("l4d2_points_adrenaline")));
	SetTrieString(h_Trie, "fheal", "give health");
	//SetTrieValue(h_Trie, "fhealcost", GetConVarInt(FindConVar(""))) inapplicable for fheal since cost is dependant on 2 different cvars for different teams
	//secondaries
	SetTrieString(h_Trie, "pistol", "give pistol");
	SetTrieValue(h_Trie, "pistolcost", GetConVarInt(FindConVar("l4d2_points_pistol")));
	SetTrieString(h_Trie, "magnum", "give pistol_magnum");
	SetTrieValue(h_Trie, "magnumcost", GetConVarInt(FindConVar("l4d2_points_magnum")));
	//smgs
	SetTrieString(h_Trie, "smg", "give smg");
	SetTrieValue(h_Trie, "smgcost", GetConVarInt(FindConVar("l4d2_points_smg")));
	SetTrieString(h_Trie, "ssmg", "give smg_silenced");
	SetTrieValue(h_Trie, "ssmgcost", GetConVarInt(FindConVar("l4d2_points_ssmg")));
	SetTrieString(h_Trie, "mp5", "give smg_mp5");
	SetTrieValue(h_Trie, "mp5cost", GetConVarInt(FindConVar("l4d2_points_mp5")));
	//rifles
	SetTrieString(h_Trie, "m16", "give rifle");
	SetTrieValue(h_Trie, "m16cost", GetConVarInt(FindConVar("l4d2_points_m16")));
	SetTrieString(h_Trie, "scar", "give rifle_desert");
	SetTrieValue(h_Trie, "scarcost", GetConVarInt(FindConVar("l4d2_points_scar")));
	SetTrieString(h_Trie, "ak", "give rifle_ak47");
	SetTrieValue(h_Trie, "akcost", GetConVarInt(FindConVar("l4d2_points_ak")));
	SetTrieString(h_Trie, "sg", "give rifle_sg552");
	SetTrieValue(h_Trie, "sgcost", GetConVarInt(FindConVar("l4d2_points_sg")));
	SetTrieString(h_Trie, "m60", "give rifle_m60");
	SetTrieValue(h_Trie, "m60cost", GetConVarInt(FindConVar("l4d2_points_m60")));
	//snipers
	SetTrieString(h_Trie, "huntrifle", "give hunting_rifle");
	SetTrieValue(h_Trie, "huntriflecost", GetConVarInt(FindConVar("l4d2_points_hunting_rifle")));
	SetTrieString(h_Trie, "scout", "give sniper_scout");
	SetTrieValue(h_Trie, "scoutcost", GetConVarInt(FindConVar("l4d2_points_scout")));
	SetTrieString(h_Trie, "milrifle", "give sniper_military");
	SetTrieValue(h_Trie, "milriflecost", GetConVarInt(FindConVar("l4d2_points_military_sniper")));
	SetTrieString(h_Trie, "awp", "give sniper_scout");
	SetTrieValue(h_Trie, "awpcost", GetConVarInt(FindConVar("l4d2_points_awp")));
	//shotguns
	SetTrieString(h_Trie, "chrome", "give shotgun_chrome");
	SetTrieValue(h_Trie, "chromecost", GetConVarInt(FindConVar("l4d2_points_chrome")));
	SetTrieString(h_Trie, "pump", "give pumpshotgun");
	SetTrieValue(h_Trie, "pumpcost", GetConVarInt(FindConVar("l4d2_points_pump")));
	SetTrieString(h_Trie, "spas", "give shotgun_spas");
	SetTrieValue(h_Trie, "spascost", GetConVarInt(FindConVar("l4d2_points_spas")));
	SetTrieString(h_Trie, "auto", "give autoshotgun");
	SetTrieValue(h_Trie, "autocost", GetConVarInt(FindConVar("l4d2_points_autoshotgun")));
	//throwables
	SetTrieString(h_Trie, "molly", "give molotov");
	SetTrieValue(h_Trie, "mollycost", GetConVarInt(FindConVar("l4d2_points_molotov")));
	SetTrieString(h_Trie, "pipe", "give pipe_bomb");
	SetTrieValue(h_Trie, "pipecost", GetConVarInt(FindConVar("l4d2_points_pipe")));
	SetTrieString(h_Trie, "bile", "give vomitjar");
	SetTrieValue(h_Trie, "bilecost", GetConVarInt(FindConVar("l4d2_points_bile")));
	//misc
	SetTrieString(h_Trie, "csaw", "give chainsaw");
	SetTrieValue(h_Trie, "csawcost", GetConVarInt(FindConVar("l4d2_points_chainsaw")));
	SetTrieString(h_Trie, "launcher", "give grenade_launcher");
	SetTrieValue(h_Trie, "launchercost", GetConVarInt(FindConVar("l4d2_points_grenade")));
	SetTrieString(h_Trie, "gnome", "give gnome");
	SetTrieValue(h_Trie, "gnomecost", GetConVarInt(FindConVar("l4d2_points_gnome")));
	SetTrieString(h_Trie, "cola", "give cola_bottles");
	SetTrieValue(h_Trie, "colacost", GetConVarInt(FindConVar("l4d2_points_cola")));
	SetTrieString(h_Trie, "gas", "give gascan");
	SetTrieValue(h_Trie, "gascost", GetConVarInt(FindConVar("l4d2_points_gascan")));
	SetTrieString(h_Trie, "propane", "give propanetank");
	SetTrieValue(h_Trie, "propanecost", GetConVarInt(FindConVar("l4d2_points_propane")));
	SetTrieString(h_Trie, "fworks", "give fireworkcrate");
	SetTrieValue(h_Trie, "fworkscost", GetConVarInt(FindConVar("l4d2_points_fireworks")));
	SetTrieString(h_Trie, "oxy", "give oxygentank");
	SetTrieValue(h_Trie, "oxycost", GetConVarInt(FindConVar("l4d2_points_oxygen")));
	//upgrades
	SetTrieString(h_Trie, "packex", "give upgradepack_explosive");
	SetTrieValue(h_Trie, "packexcost", GetConVarInt(FindConVar("l4d2_points_explosive_ammo_pack")));
	SetTrieString(h_Trie, "packin", "give upgradepack_incendiary");
	SetTrieValue(h_Trie, "packincost", GetConVarInt(FindConVar("l4d2_points_incendiary_ammo_pack")));
	SetTrieString(h_Trie, "ammo", "give ammo");
	SetTrieValue(h_Trie, "ammocost", GetConVarInt(FindConVar("l4d2_points_refill")));
	SetTrieString(h_Trie, "exammo", "upgrade_add EXPLOSIVE_AMMO");
	SetTrieValue(h_Trie, "exammocost", GetConVarInt(FindConVar("l4d2_points_explosive_ammo")));
	SetTrieString(h_Trie, "inammo", "upgrade_add INCENDIARY_AMMO");
	SetTrieValue(h_Trie, "inammocost", GetConVarInt(FindConVar("l4d2_points_incendiary_ammo")));
	SetTrieString(h_Trie, "laser", "upgrade_add LASER_SIGHT");
	SetTrieValue(h_Trie, "lasercost", GetConVarInt(FindConVar("l4d2_points_laser")));
	//melee
	SetTrieString(h_Trie, "cbar", "give crowbar");
	SetTrieValue(h_Trie, "cbarcost", GetConVarInt(FindConVar("l4d2_points_crowbar")));
	SetTrieString(h_Trie, "cbat", "give cricket_bat");
	SetTrieValue(h_Trie, "cbatcost", GetConVarInt(FindConVar("l4d2_points_cricketbat")));
	SetTrieString(h_Trie, "bat", "give baseball_bat");
	SetTrieValue(h_Trie, "batcost", GetConVarInt(FindConVar("l4d2_points_bat")));
	SetTrieString(h_Trie, "machete", "give machete");
	SetTrieValue(h_Trie, "machetecost", GetConVarInt(FindConVar("l4d2_points_machete")));
	SetTrieString(h_Trie, "tonfa", "give tonfa");
	SetTrieValue(h_Trie, "tonfacost", GetConVarInt(FindConVar("l4d2_points_tonfa")));
	SetTrieString(h_Trie, "katana", "give katana");
	SetTrieValue(h_Trie, "katanacost", GetConVarInt(FindConVar("l4d2_points_katana")));
	SetTrieString(h_Trie, "axe", "give fireaxe");
	SetTrieValue(h_Trie, "axecost", GetConVarInt(FindConVar("l4d2_points_fireaxe")));
	SetTrieString(h_Trie, "guitar", "give electric_guitar");
	SetTrieValue(h_Trie, "guitarcost", GetConVarInt(FindConVar("l4d2_points_guitar")));
	SetTrieString(h_Trie, "pan", "give frying_pan");
	SetTrieValue(h_Trie, "pancost", GetConVarInt(FindConVar("l4d2_points_pan")));
	SetTrieString(h_Trie, "club", "give golfclub");
	SetTrieValue(h_Trie, "clubcost", GetConVarInt(FindConVar("l4d2_points_golfclub")));
	//infected
	SetTrieString(h_Trie, "kill", "kill");
	SetTrieValue(h_Trie, "killcost", GetConVarInt(FindConVar("l4d2_points_suicide")));
	SetTrieString(h_Trie, "boomer", "z_spawn boomer auto");
	SetTrieValue(h_Trie, "boomercost", GetConVarInt(FindConVar("l4d2_points_boomer")));
	SetTrieString(h_Trie, "smoker", "z_spawn smoker auto");
	SetTrieValue(h_Trie, "smokercost", GetConVarInt(FindConVar("l4d2_points_smoker")));
	SetTrieString(h_Trie, "hunter", "z_spawn hunter auto");
	SetTrieValue(h_Trie, "huntercost", GetConVarInt(FindConVar("l4d2_points_hunter")));
	SetTrieString(h_Trie, "spitter", "z_spawn spitter auto");
	SetTrieValue(h_Trie, "spittercost", GetConVarInt(FindConVar("l4d2_points_spitter")));
	SetTrieString(h_Trie, "jockey", "z_spawn jockey auto");
	SetTrieValue(h_Trie, "jockeycost", GetConVarInt(FindConVar("l4d2_points_jockey")));
	SetTrieString(h_Trie, "charger", "z_spawn charger auto");
	SetTrieValue(h_Trie, "chargercost", GetConVarInt(FindConVar("l4d2_points_charger")));
	SetTrieString(h_Trie, "witch", "z_spawn witch auto");
	SetTrieValue(h_Trie, "witchcost", GetConVarInt(FindConVar("l4d2_points_witch")));
	SetTrieString(h_Trie, "bride", "z_spawn witch_bride auto");
	SetTrieValue(h_Trie, "bridecost", GetConVarInt(FindConVar("l4d2_points_witch")));
	SetTrieString(h_Trie, "tank", "z_spawn tank auto");
	SetTrieValue(h_Trie, "tankcost", GetConVarInt(FindConVar("l4d2_points_tank")));
	SetTrieString(h_Trie, "horde", "director_force_panic_event");
	SetTrieValue(h_Trie, "hordecost", GetConVarInt(FindConVar("l4d2_points_horde")));
	SetTrieString(h_Trie, "mob", "z_spawn mob auto");
	SetTrieValue(h_Trie, "mobcost", GetConVarInt(FindConVar("l4d2_points_mob")));
	SetTrieString(h_Trie, "umob", "z_spawn mob");
	SetTrieValue(h_Trie, "umobcost", GetConVarInt(FindConVar("l4d2_points_umob")));
}	

public UpdateBuyTrie()
{
	//health
	SetTrieValue(h_Trie, "pillscost", GetConVarInt(FindConVar("l4d2_points_pills")), true);
	SetTrieValue(h_Trie, "kitcost", GetConVarInt(FindConVar("l4d2_points_kit")), true);
	SetTrieValue(h_Trie, "defibcost", GetConVarInt(FindConVar("l4d2_points_defib")), true);
	SetTrieValue(h_Trie, "adrencost", GetConVarInt(FindConVar("l4d2_points_adrenaline")), true);
	//SetTrieValue(h_Trie, "fhealcost", GetConVarInt(FindConVar(""))) inapplicable for fheal since cost is dependant on 2 different cvars for different teams
	//secondaries
	SetTrieValue(h_Trie, "pistolcost", GetConVarInt(FindConVar("l4d2_points_pistol")), true);
	SetTrieValue(h_Trie, "magnumcost", GetConVarInt(FindConVar("l4d2_points_magnum")), true);
	//smgs
	SetTrieValue(h_Trie, "smgcost", GetConVarInt(FindConVar("l4d2_points_smg")), true);
	SetTrieValue(h_Trie, "ssmgcost", GetConVarInt(FindConVar("l4d2_points_ssmg")), true);
	SetTrieValue(h_Trie, "mp5cost", GetConVarInt(FindConVar("l4d2_points_mp5")), true);
	//rifles
	SetTrieValue(h_Trie, "m16cost", GetConVarInt(FindConVar("l4d2_points_m16")), true);
	SetTrieValue(h_Trie, "scarcost", GetConVarInt(FindConVar("l4d2_points_scar")), true);
	SetTrieValue(h_Trie, "akcost", GetConVarInt(FindConVar("l4d2_points_ak")), true);
	SetTrieValue(h_Trie, "sgcost", GetConVarInt(FindConVar("l4d2_points_sg")), true);
	SetTrieValue(h_Trie, "m60cost", GetConVarInt(FindConVar("l4d2_points_m60")), true);
	//snipers
	SetTrieValue(h_Trie, "huntriflecost", GetConVarInt(FindConVar("l4d2_points_hunting_rifle")), true);
	SetTrieValue(h_Trie, "scoutcost", GetConVarInt(FindConVar("l4d2_points_scout")), true);
	SetTrieValue(h_Trie, "milriflecost", GetConVarInt(FindConVar("l4d2_points_military_sniper")), true);
	SetTrieValue(h_Trie, "awpcost", GetConVarInt(FindConVar("l4d2_points_awp")), true);
	//shotguns
	SetTrieValue(h_Trie, "chromecost", GetConVarInt(FindConVar("l4d2_points_chrome")), true);
	SetTrieValue(h_Trie, "pumpcost", GetConVarInt(FindConVar("l4d2_points_pump")), true);
	SetTrieValue(h_Trie, "spascost", GetConVarInt(FindConVar("l4d2_points_spas")), true);
	SetTrieValue(h_Trie, "autocost", GetConVarInt(FindConVar("l4d2_points_autoshotgun")), true);
	//throwables
	SetTrieValue(h_Trie, "mollycost", GetConVarInt(FindConVar("l4d2_points_molotov")), true);
	SetTrieValue(h_Trie, "pipecost", GetConVarInt(FindConVar("l4d2_points_pipe")), true);
	SetTrieValue(h_Trie, "bilecost", GetConVarInt(FindConVar("l4d2_points_bile")), true);
	//misc
	SetTrieValue(h_Trie, "csawcost", GetConVarInt(FindConVar("l4d2_points_chainsaw")), true);
	SetTrieValue(h_Trie, "launchercost", GetConVarInt(FindConVar("l4d2_points_grenade")), true);
	SetTrieValue(h_Trie, "gnomecost", GetConVarInt(FindConVar("l4d2_points_gnome")), true);
	SetTrieValue(h_Trie, "colacost", GetConVarInt(FindConVar("l4d2_points_cola")), true);
	SetTrieValue(h_Trie, "gascost", GetConVarInt(FindConVar("l4d2_points_gascan")), true);
	SetTrieValue(h_Trie, "propanecost", GetConVarInt(FindConVar("l4d2_points_propane")), true);
	SetTrieValue(h_Trie, "fworkscost", GetConVarInt(FindConVar("l4d2_points_fireworks")), true);
	SetTrieValue(h_Trie, "oxycost", GetConVarInt(FindConVar("l4d2_points_oxygen")), true);
	//upgrades
	SetTrieValue(h_Trie, "packexcost", GetConVarInt(FindConVar("l4d2_points_explosive_ammo_pack")), true);
	SetTrieValue(h_Trie, "packincost", GetConVarInt(FindConVar("l4d2_points_incendiary_ammo_pack")), true);
	SetTrieValue(h_Trie, "ammocost", GetConVarInt(FindConVar("l4d2_points_refill")), true);
	SetTrieValue(h_Trie, "exammocost", GetConVarInt(FindConVar("l4d2_points_explosive_ammo")), true);
	SetTrieValue(h_Trie, "inammocost", GetConVarInt(FindConVar("l4d2_points_incendiary_ammo")), true);
	SetTrieValue(h_Trie, "lasercost", GetConVarInt(FindConVar("l4d2_points_laser")), true);
	//melee
	SetTrieValue(h_Trie, "cbarcost", GetConVarInt(FindConVar("l4d2_points_crowbar")), true);
	SetTrieValue(h_Trie, "cbatcost", GetConVarInt(FindConVar("l4d2_points_cricketbat")), true);
	SetTrieValue(h_Trie, "batcost", GetConVarInt(FindConVar("l4d2_points_bat")), true);
	SetTrieValue(h_Trie, "machetecost", GetConVarInt(FindConVar("l4d2_points_machete")), true);
	SetTrieValue(h_Trie, "tonfacost", GetConVarInt(FindConVar("l4d2_points_tonfa")), true);
	SetTrieValue(h_Trie, "katanacost", GetConVarInt(FindConVar("l4d2_points_katana")), true);
	SetTrieValue(h_Trie, "axecost", GetConVarInt(FindConVar("l4d2_points_fireaxe")), true);
	SetTrieValue(h_Trie, "guitarcost", GetConVarInt(FindConVar("l4d2_points_guitar")), true);
	SetTrieValue(h_Trie, "pancost", GetConVarInt(FindConVar("l4d2_points_pan")), true);
	SetTrieValue(h_Trie, "clubcost", GetConVarInt(FindConVar("l4d2_points_golfclub")), true);
	//infected
	SetTrieValue(h_Trie, "killcost", GetConVarInt(FindConVar("l4d2_points_suicide")), true);
	SetTrieValue(h_Trie, "boomercost", GetConVarInt(FindConVar("l4d2_points_boomer")), true);
	SetTrieValue(h_Trie, "smokercost", GetConVarInt(FindConVar("l4d2_points_smoker")), true);
	SetTrieValue(h_Trie, "huntercost", GetConVarInt(FindConVar("l4d2_points_hunter")), true);
	SetTrieValue(h_Trie, "spittercost", GetConVarInt(FindConVar("l4d2_points_spitter")), true);
	SetTrieValue(h_Trie, "jockeycost", GetConVarInt(FindConVar("l4d2_points_jockey")), true);
	SetTrieValue(h_Trie, "chargercost", GetConVarInt(FindConVar("l4d2_points_charger")), true);
	SetTrieValue(h_Trie, "witchcost", GetConVarInt(FindConVar("l4d2_points_witch")), true);
	SetTrieValue(h_Trie, "bridecost", GetConVarInt(FindConVar("l4d2_points_witch")), true);
	SetTrieValue(h_Trie, "tankcost", GetConVarInt(FindConVar("l4d2_points_tank")), true);
	SetTrieValue(h_Trie, "hordecost", GetConVarInt(FindConVar("l4d2_points_horde")), true);
	SetTrieValue(h_Trie, "mobcost", GetConVarInt(FindConVar("l4d2_points_mob")), true);
	SetTrieValue(h_Trie, "umobcost", GetConVarInt(FindConVar("l4d2_points_umob")), true);
}

public Action:Cmd_Buy(client, args)
{
	if(!GetConVarBool(h_Enable) || !loaded || !IsClientInGame(client) || client > MaxClients) return Plugin_Continue;
	if(!IsPlayerAlive(client) && args > 0)
	{
		ReplyToCommand(client, "[PS] Must Be Alive To Buy Items!");
		return Plugin_Continue;
	}	
	if(args > 1 || args == 0) return Plugin_Continue;
	new String:arg[50];
	GetCmdArg(1, arg, sizeof(arg));
	new String:argval[100];
	if(!GetTrieString(h_Trie, arg, argval, sizeof(argval)))
	{
		return Plugin_Continue;
	}
	else
	{
		new icost = -2; //-2 = invalid
		if(StrEqual(arg, "cola", false))
		{
			new String:map[100];
			GetCurrentMap(map, 100);
			if(StrEqual(map, "c1m2_streets", false))
			{
				PrintToChat(client, "[PS] This item is unavailable during this map");
				return Plugin_Continue;
			}
		}	
		if(StrEqual(arg, "fheal", false) && GetClientTeam(client) == 3)
		{
			if(GetEntProp(client, Prop_Send, "m_zombieClass") == 8)
			{
				PS_SetCost(client, GetConVarInt(FindConVar("l4d2_points_infected_heal"))*GetConVarInt(FindConVar("l4d2_points_tank_heal_mult")));
				icost == GetConVarInt(FindConVar("l4d2_points_infected_heal"))*GetConVarInt(FindConVar("l4d2_points_tank_heal_mult"));
				if(icost == -1)
				{
				PrintToChat(client, "[PS] This item is disabled!");
				return Plugin_Continue;
				}	
			}	
			else
			{
				PS_SetBoughtCost(client, GetConVarInt(FindConVar("l4d2_points_infected_heal")));
				icost == GetConVarInt(FindConVar("l4d2_points_infected_heal"));
				if(icost == -1)
				{
				PrintToChat(client, "[PS] This item is disabled!");
				return Plugin_Continue;
				}	
			}	
			PS_SetBought(client, argval);
			HandleHeal(client);
		}	
		else if(StrEqual(arg, "fheal", false) && GetClientTeam(client) == 2)
		{
			PS_SetBoughtCost(client, GetConVarInt(FindConVar("l4d2_points_survivor_heal")));
			icost = GetConVarInt(FindConVar("l4d2_points_survivor_heal"));
			if(icost == -1)
			{
				PrintToChat(client, "[PS] This item is disabled!");
				return Plugin_Continue;
			}	
			PS_SetBought(client, argval);
			HandleHeal(client);
		}	
		if(StrEqual(arg, "kill", false) && GetClientTeam(client) == 3)
		{
			Format(arg, sizeof(arg), "%scost", arg);
			GetTrieValue(h_Trie, arg, icost);
			if(icost == -1)
			{
				PrintToChat(client, "[PS] This item is disabled!");
				return Plugin_Continue;
			}	
			PS_SetBoughtCost(client, icost);
			PS_SetBought(client, "suicide");
			HandleSuicide(client);
		}
		else if(StrEqual(arg, "umob", false) && GetClientTeam(client) == 3)
		{
			Format(arg, sizeof(arg), "%scost", arg);
			GetTrieValue(h_Trie, arg, icost);
			if(icost == -1)
			{
				PrintToChat(client, "[PS] This item is disabled!");
				return Plugin_Continue;
			}	
			PS_SetBoughtCost(client, icost);
			PS_SetBought(client, argval);
			HandleUMob(client);
		}
		else if(GetClientTeam(client) > 1)
		{
			PS_SetBought(client, argval);
			Format(arg, sizeof(arg), "%scost", arg);
			GetTrieValue(h_Trie, arg, icost);
			if(icost == -1)
			{
				PrintToChat(client, "[PS] This item is disabled!");
				return Plugin_Continue;
			}	
			PS_SetBoughtCost(client, icost);
			if(PS_GetBoughtCost(client) == -2) return Plugin_Continue;
			else HandlePurchase(client);
		}	
	}
	return Plugin_Continue;
}	

stock HandlePurchase(client)
{
	PS_SetCost(client, PS_GetBoughtCost(client));
	if(PS_GetCost(client) > -1 && PS_GetPoints(client) >= PS_GetCost(client))
	{
		RemoveFlags();
		new String:item1[100];
		PS_GetBought(client, item1);
		if(StrEqual(item1, "give ammo", false))
		{
			new wep = GetPlayerWeaponSlot(client, 0);
			if(wep == -1)
			{
				if(IsClientInGame(client)) PrintToChat(client, "[PS] You must have a primary weapon to refill ammo!");
				AddFlags();
				return;
			}
			new m60ammo = 150;
			new nadeammo = 30;
			new Handle:cvar = FindConVar("l4d2_guncontrol_m60ammo");
			new Handle:cvar2 = FindConVar("l4d2_guncontrol_grenadelauncherammo");
			if(cvar != INVALID_HANDLE)
			{
				m60ammo = GetConVarInt(cvar);
				CloseHandle(cvar);
			}	
			if(cvar2 != INVALID_HANDLE)
			{
				nadeammo = GetConVarInt(cvar2);
				CloseHandle(cvar2);
			}	
			new String:class[40];
			GetEdictClassname(wep, class, sizeof(class));
			if(StrEqual(class, "weapon_rifle_m60", false)) SetEntProp(wep, Prop_Data, "m_iClip1", m60ammo, 1);
			else if(StrEqual(class, "weapon_grenade_launcher", false))
			{
				new offset = FindDataMapOffs(client, "m_iAmmo");
				SetEntData(client, offset + 68, nadeammo);
			}
		}	
		PS_SetItem(client, item1);
		FakeClientCommand(client, item1);
		AddFlags();
		PS_SetPoints(client, PS_GetPoints(client) - PS_GetCost(client));
	}
	else if(PS_GetCost(client) == -1)
	{
		PrintToChat(client, "[PS] Item Disabled");
		PS_SetBoughtCost(client, PS_GetBoughtCost(client));
	}
	else
	{
		PS_SetBoughtCost(client, PS_GetBoughtCost(client));
		PrintToChat(client, "[PS] Not Enough Points");
	}	
}	

stock HandleHeal(client)
{
	PS_SetCost(client, PS_GetBoughtCost(client));
	if(PS_GetCost(client) > -1 && PS_GetPoints(client) >= PS_GetCost(client))
	{
		RemoveFlags();
		new String:item1[100];
		PS_GetBought(client, item1);
		PS_SetItem(client, item1);
		FakeClientCommand(client, item1);
		SetEntPropFloat(client, Prop_Send, "m_healthBuffer", 0.0);
		AddFlags();
		PS_SetPoints(client, PS_GetPoints(client) - PS_GetCost(client));
	}
	else if(PS_GetCost(client) == -1)
	{
		PrintToChat(client, "[PS] Item Disabled");
		PS_SetBoughtCost(client, PS_GetBoughtCost(client));
	}
	else
	{
		PS_SetBoughtCost(client, PS_GetBoughtCost(client));
		PrintToChat(client, "[PS] Not Enough Points");
	}	
}	

stock HandleSuicide(client)
{
	PS_SetCost(client, PS_GetBoughtCost(client));
	if(PS_GetCost(client) > -1 && PS_GetPoints(client) >= PS_GetCost(client) && IsClientInGame(client) && IsPlayerAlive(client))
	{
		ForcePlayerSuicide(client);
		PS_SetBought(client, "suicide");
		PS_SetPoints(client, PS_GetPoints(client) - PS_GetCost(client));
	}
	else if(PS_GetCost(client) == -1)
	{
		PrintToChat(client, "[PS] Item Disabled");
		PS_SetBoughtCost(client, PS_GetBoughtCost(client));
	}
	else
	{
		PS_SetBoughtCost(client, PS_GetBoughtCost(client));
		PrintToChat(client, "[PS] Not Enough Points");
	}	
}	

stock HandleUMob(client)
{
	PS_SetCost(client, PS_GetBoughtCost(client));
	if(PS_GetCost(client) > -1 && PS_GetPoints(client) >= PS_GetCost(client))
	{
		PS_SetupUMob(GetConVarInt(FindConVar("z_common_limit")));
		PS_SetItem(client, "z_spawn mob");
		PS_SetPoints(client, PS_GetPoints(client) - PS_GetCost(client));
	}
	else if(PS_GetCost(client) == -1)
	{
		PrintToChat(client, "[PS] Item Disabled");
		PS_SetBoughtCost(client, PS_GetBoughtCost(client));
	}
	else
	{
		PS_SetBoughtCost(client, PS_GetBoughtCost(client));
		PrintToChat(client, "[PS] Not Enough Points");
	}	
}	

RemoveFlags()
{
	new flagsgive = GetCommandFlags("give");
	new flagszspawn = GetCommandFlags("z_spawn");
	new flagsupgradeadd = GetCommandFlags("upgrade_add");
	new flagspanic = GetCommandFlags("director_force_panic_event");
	SetCommandFlags("give", flagsgive & ~FCVAR_CHEAT);
	SetCommandFlags("z_spawn", flagszspawn & ~FCVAR_CHEAT);
	SetCommandFlags("upgrade_add", flagsupgradeadd & ~FCVAR_CHEAT);
	SetCommandFlags("director_force_panic_event", flagspanic & ~FCVAR_CHEAT);
}	

AddFlags()
{
	new flagsgive = GetCommandFlags("give");
	new flagszspawn = GetCommandFlags("z_spawn");
	new flagsupgradeadd = GetCommandFlags("upgrade_add");
	new flagspanic = GetCommandFlags("director_force_panic_event");
	SetCommandFlags("give", flagsgive|FCVAR_CHEAT);
	SetCommandFlags("z_spawn", flagszspawn|FCVAR_CHEAT);
	SetCommandFlags("upgrade_add", flagsupgradeadd|FCVAR_CHEAT);
	SetCommandFlags("director_force_panic_event", flagspanic|FCVAR_CHEAT);
}	