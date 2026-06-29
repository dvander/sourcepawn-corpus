#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

ConVar rng_sinkroll;
ConVar rng_assaultrifle_max;
ConVar rng_smg_max;
ConVar rng_shotgun_max;
ConVar rng_autoshotgun_max;
ConVar rng_huntingrifle_max;
ConVar rng_sniperrifle_max;
ConVar rng_grenadelauncher_max;
ConVar rng_m60_max;
ConVar rng_baseballbat;
ConVar rng_cricket_bat;
ConVar rng_crowbar;
ConVar rng_electric_guitar;
ConVar rng_fireaxe;
ConVar rng_frying_pan;
ConVar rng_golfclub;
ConVar rng_katana;
ConVar rng_machete;
ConVar rng_tonfa;
ConVar rng_knife;
ConVar rng_pitchfork;
ConVar rng_shovel;
ConVar rng_weapon_chainsaw;
ConVar rng_weapon_adrenaline;
ConVar rng_weapon_defibrillator;
ConVar rng_weapon_first_aid_kit;
ConVar rng_weapon_pain_pills;
ConVar rng_weapon_fireworkcrate;
ConVar rng_weapon_gascan;
ConVar rng_weapon_oxygentank;
ConVar rng_weapon_propanetank;
ConVar rng_weapon_molotov;
ConVar rng_weapon_pipe_bomb;
ConVar rng_weapon_vomitjar;
ConVar rng_weapon_ammo_spawn;
ConVar rng_upgrade_laser_sight;
ConVar rng_weapon_upgradepack_explosive;
ConVar rng_weapon_upgradepack_incendiary;
ConVar rng_weapon_gnome;
ConVar rng_weapon_cola_bottles;
ConVar rng_weapon_pistol;
ConVar rng_weapon_pistol_magnum;
ConVar rng_weapon_autoshotgun;
ConVar rng_weapon_hunting_rifle;
ConVar rng_weapon_pumpshotgun;
ConVar rng_weapon_grenade_launcher;
ConVar rng_weapon_rifle;
ConVar rng_weapon_rifle_ak47;
ConVar rng_weapon_rifle_desert;
ConVar rng_weapon_rifle_m60;
ConVar rng_weapon_rifle_sg552;
ConVar rng_weapon_shotgun_chrome;
ConVar rng_weapon_shotgun_spas;
ConVar rng_weapon_smg;
ConVar rng_weapon_smg_mp5;
ConVar rng_weapon_smg_silenced;
ConVar rng_weapon_sniper_awp;
ConVar rng_weapon_sniper_military;
ConVar rng_weapon_sniper_scout;

public Plugin myinfo = 
{
	name = "[L4D2] Navigation Loot Spawner",
	author = "BHaType, RainyDagger, Shao",
	description = "Spawn randomly any items anywhere on the nav_mesh.",
	version = "1.0",
	url = ""
};

static const char szWeapons[][] =
{
	"baseball_bat",
	"cricket_bat",
	"crowbar",
	"electric_guitar",
	"fireaxe",
	"frying_pan",
	"golfclub",
	"katana",
	"machete",
	"tonfa",
	"knife",
	"pitchfork",
	"shovel",
	"weapon_chainsaw",
	"weapon_adrenaline",
	"weapon_defibrillator",
	"weapon_first_aid_kit",
	"weapon_pain_pills",
	"weapon_fireworkcrate",
	"weapon_gascan",
	"weapon_oxygentank",
	"weapon_propanetank",
	"weapon_molotov",
	"weapon_pipe_bomb",
	"weapon_vomitjar",
	"weapon_ammo_spawn",
	"upgrade_laser_sight",
	"weapon_upgradepack_explosive",
	"weapon_upgradepack_incendiary",
	"weapon_gnome",
	"weapon_cola_bottles",
	"weapon_pistol",
    "weapon_pistol_magnum",
    "weapon_autoshotgun",
    "weapon_hunting_rifle",
    "weapon_pumpshotgun",
	"weapon_grenade_launcher",
    "weapon_rifle",
    "weapon_rifle_ak47",
    "weapon_rifle_desert",
    "weapon_rifle_m60",
    "weapon_rifle_sg552",
    "weapon_shotgun_chrome",
    "weapon_shotgun_spas",
    "weapon_smg",
    "weapon_smg_mp5",
    "weapon_smg_silenced",
    "weapon_sniper_awp",
    "weapon_sniper_military",
    "weapon_sniper_scout"
};

static int gChances[sizeof(szWeapons)];

ConVar g_hLootCount, g_hNavBits, g_hCheckReachable;
bool g_bLoaded, g_alreadyspawned;
Address TheNavAreas;
int TheCount, g_iLootCount, g_iNavFlagsCheck, g_iReachableCheck;
Handle g_hReachableCheck;


public void OnPluginStart()
{
	g_hLootCount 						= CreateConVar("sm_nav_loot_spawner_count", 			"30", "How much items do we spawn?", FCVAR_NONE);
	g_hNavBits 							= CreateConVar("sm_nav_loot_spawn_flags",				"0", "Should we spawn items in flags zones?", FCVAR_NONE, true, 0.0, true, 1.0);
	g_hCheckReachable 					= CreateConVar("sm_nav_loot_check_position_reachable", 	"0", "Should we check if position is reachable? (Windows only)", FCVAR_NONE, true, 0.0, true, 1.0);
	
	rng_sinkroll 						= CreateConVar("rng_sinkroll_enabled", 					"0", "Chance of not spawning anything?", FCVAR_NONE, true, 0.0, true, 100.0);
	rng_assaultrifle_max 				= CreateConVar("rng_spawnweapon_assaultammo", 			"180", "How much Ammo for AK74, M4A1, SG552 and Desert Rifle.", 0);
	rng_smg_max 						= CreateConVar("rng_spawnweapon_smgammo", 				"325", "How much Ammo for SMG, Silenced SMG and MP5", 0);
	rng_shotgun_max 					= CreateConVar("rng_spawnweapon_shotgunammo", 			"36", "How much Ammo for Shotgun and Chrome Shotgun.", 0);
	rng_autoshotgun_max 				= CreateConVar("rng_spawnweapon_autoshotgunammo",		"45", "How much Ammo for Autoshotgun and SPAS.", 0);
	rng_huntingrifle_max 				= CreateConVar("rng_spawnweapon_huntingrifleammo", 		"75", "How much Ammo for the Hunting Rifle.", 0);
	rng_sniperrifle_max 				= CreateConVar("rng_spawnweapon_sniperrifleammo", 		"90", "How much Ammo for the Military Sniper Rifle, AWP and Scout.", 0);
	rng_grenadelauncher_max 			= CreateConVar("rng_spawnweapon_grenadelauncherammo", 	"30", "How much Ammo for the Grenade Launcher.", 0);
	rng_m60_max 						= CreateConVar("rng_spawnweapon_m60ammo", 				"100", "How much Ammo for the M60.", 0);
	rng_baseballbat 					= CreateConVar("rng_chance_baseballbat", 				"50", "Chances to spawn a Baseball Bat", 0);
	rng_cricket_bat 					= CreateConVar("rng_chance_cricket_bat", 				"50", "Chances to spawn a Cricket Bat", 0);
	rng_crowbar							= CreateConVar("rng_chance_crowbar", 					"50", "Chances to spawn a Crowbar", 0);
	rng_electric_guitar					= CreateConVar("rng_chance_electric_guitar", 			"50", "Chances to spawn a Electric Guitar", 0);
	rng_fireaxe							= CreateConVar("rng_chance_fireaxe", 					"50", "Chances to spawn a Fireaxe", 0);
	rng_frying_pan						= CreateConVar("rng_chance_frying_pan", 				"50", "Chances to spawn a Frying Pan", 0);
	rng_golfclub						= CreateConVar("rng_chance_golfclub", 					"50", "Chances to spawn a Golf Club", 0);
	rng_katana							= CreateConVar("rng_chance_katana", 					"50", "Chances to spawn a Katana", 0);
	rng_machete							= CreateConVar("rng_chance_machete", 					"50", "Chances to spawn a Machete", 0);
	rng_tonfa							= CreateConVar("rng_chance_tonfa", 						"50", "Chances to spawn a Tonfa", 0);
	rng_knife							= CreateConVar("rng_chance_knife", 						"50", "Chances to spawn a Knife", 0);
	rng_pitchfork						= CreateConVar("rng_chance_pitchfork", 					"50", "Chances to spawn a Pitchfork", 0);
	rng_shovel							= CreateConVar("rng_chance_shovel", 					"50", "Chances to spawn a Shovel", 0);
	rng_weapon_chainsaw					= CreateConVar("rng_chance_chainsaw", 					"50", "Chances to spawn a Chainsaw", 0);
	rng_weapon_adrenaline				= CreateConVar("rng_chance_adrenaline", 				"50", "Chances to spawn a Adrenaline", 0);
	rng_weapon_defibrillator			= CreateConVar("rng_chance_defibrillator", 				"50", "Chances to spawn a Defibrillator", 0);
	rng_weapon_first_aid_kit			= CreateConVar("rng_chance_first_aid_kit", 				"50", "Chances to spawn a First Aid Kit", 0);
	rng_weapon_pain_pills				= CreateConVar("rng_chance_pain_pills", 				"50", "Chances to spawn a Pain Pills", 0);
	rng_weapon_fireworkcrate			= CreateConVar("rng_chance_fireworkcrate", 				"50", "Chances to spawn a Firework Crate", 0);
	rng_weapon_gascan					= CreateConVar("rng_chance_gascan", 					"50", "Chances to spawn a Gascan", 0);
	rng_weapon_oxygentank				= CreateConVar("rng_chance_oxygentank", 				"50", "Chances to spawn a Oxygen Tank", 0);
	rng_weapon_propanetank				= CreateConVar("rng_chance_propanetank", 				"50", "Chances to spawn a Propane Tank", 0);
	rng_weapon_molotov					= CreateConVar("rng_chance_molotov", 					"50", "Chances to spawn a Molotov", 0);
	rng_weapon_pipe_bomb				= CreateConVar("rng_chance_pipe_bomb", 					"50", "Chances to spawn a Pipe Bomb", 0);
	rng_weapon_vomitjar					= CreateConVar("rng_chance_vomitjar", 					"50", "Chances to spawn a Vomit Jar", 0);
	rng_weapon_ammo_spawn				= CreateConVar("rng_chance_ammo_spawn", 				"50", "Chances to spawn a Ammo Pile", 0);
	rng_upgrade_laser_sight				= CreateConVar("rng_chance_upgrade_laser_sight", 		"50", "Chances to spawn a Laser Sight Box", 0);
	rng_weapon_upgradepack_explosive 	= CreateConVar("rng_chance_upgradepack_explosive", 		"50", "Chances to spawn a Explosive Ammo Box", 0);
	rng_weapon_upgradepack_incendiary	= CreateConVar("rng_chance_upgradepack_incendiary", 	"50", "Chances to spawn a Incendiary Ammo Box", 0);
	rng_weapon_gnome					= CreateConVar("rng_chance_gnome", 						"50", "Chances to spawn a Gnome", 0);
	rng_weapon_cola_bottles				= CreateConVar("rng_chance_cola_bottles", 				"50", "Chances to spawn a Cola Bottles", 0);
	rng_weapon_pistol					= CreateConVar("rng_chance_pistol", 					"50", "Chances to spawn a Pistol", 0);
	rng_weapon_pistol_magnum			= CreateConVar("rng_chance_pistol_magnum", 				"50", "Chances to spawn a Magnum", 0);
	rng_weapon_autoshotgun				= CreateConVar("rng_chance_autoshotgun", 				"50", "Chances to spawn a Autoshotgun", 0);
	rng_weapon_hunting_rifle			= CreateConVar("rng_chance_hunting_rifle", 				"50", "Chances to spawn a Hunting Rifle", 0);
	rng_weapon_pumpshotgun				= CreateConVar("rng_chance_pumpshotgun", 				"50", "Chances to spawn a Pumpshotgun", 0);
	rng_weapon_grenade_launcher			= CreateConVar("rng_chance_grenade_launcher", 			"50", "Chances to spawn a Grenade Launcher", 0);
	rng_weapon_rifle					= CreateConVar("rng_chance_rifle", 						"50", "Chances to spawn a M16 Rifle", 0);
	rng_weapon_rifle_ak47				= CreateConVar("rng_chance_rifle_ak47", 				"50", "Chances to spawn a AK47 Rifle", 0);
	rng_weapon_rifle_desert				= CreateConVar("rng_chance_rifle_desert", 				"50", "Chances to spawn a Desert Rifle", 0);
	rng_weapon_rifle_m60				= CreateConVar("rng_chance_rifle_m60", 					"50", "Chances to spawn a M60 Rifle", 0);
	rng_weapon_rifle_sg552				= CreateConVar("rng_chance_rifle_sg552", 				"50", "Chances to spawn a SG552 Rifle", 0);
	rng_weapon_shotgun_chrome			= CreateConVar("rng_chance_shotgun_chrome", 			"50", "Chances to spawn a Chrome Shotgun", 0);
	rng_weapon_shotgun_spas				= CreateConVar("rng_chance_shotgun_spas", 				"50", "Chances to spawn a Spas Shotgun", 0);
	rng_weapon_smg						= CreateConVar("rng_chance_smg", 						"50", "Chances to spawn a SMG", 0);
	rng_weapon_smg_mp5					= CreateConVar("rng_chance_smg_mp5", 					"50", "Chances to spawn a MP5", 0);
	rng_weapon_smg_silenced				= CreateConVar("rng_chance_smg_silenced", 				"50", "Chances to spawn a Silenced SMG", 0);
	rng_weapon_sniper_awp				= CreateConVar("rng_chance_sniper_awp", 				"50", "Chances to spawn a AWP", 0);
	rng_weapon_sniper_military			= CreateConVar("rng_chance_sniper_military", 			"50", "Chances to spawn a Autosniper", 0);
	rng_weapon_sniper_scout				= CreateConVar("rng_chance_sniper_scout", 				"50", "Chances to spawn a Scout", 0);
	
	g_hLootCount.AddChangeHook(OnConVarChanged);
	g_hNavBits.AddChangeHook(OnConVarChanged);
	g_hCheckReachable.AddChangeHook(OnConVarChanged);
	rng_sinkroll.AddChangeHook(OnConVarChanged);
	rng_assaultrifle_max.AddChangeHook(OnConVarChanged);
	rng_smg_max.AddChangeHook(OnConVarChanged);
	rng_shotgun_max.AddChangeHook(OnConVarChanged);
	rng_autoshotgun_max.AddChangeHook(OnConVarChanged);
	rng_huntingrifle_max.AddChangeHook(OnConVarChanged);
	rng_sniperrifle_max.AddChangeHook(OnConVarChanged);
	rng_grenadelauncher_max.AddChangeHook(OnConVarChanged);
	rng_m60_max.AddChangeHook(OnConVarChanged);
	rng_baseballbat.AddChangeHook(OnConVarChanged);
	rng_cricket_bat.AddChangeHook(OnConVarChanged);
	rng_crowbar.AddChangeHook(OnConVarChanged);
	rng_electric_guitar.AddChangeHook(OnConVarChanged);
	rng_fireaxe.AddChangeHook(OnConVarChanged);
	rng_frying_pan.AddChangeHook(OnConVarChanged);
	rng_golfclub.AddChangeHook(OnConVarChanged);
	rng_katana.AddChangeHook(OnConVarChanged);
	rng_machete.AddChangeHook(OnConVarChanged);
	rng_tonfa.AddChangeHook(OnConVarChanged);
	rng_knife.AddChangeHook(OnConVarChanged);
	rng_pitchfork.AddChangeHook(OnConVarChanged);
	rng_shovel.AddChangeHook(OnConVarChanged);
	rng_weapon_chainsaw.AddChangeHook(OnConVarChanged);
	rng_weapon_adrenaline.AddChangeHook(OnConVarChanged);
	rng_weapon_defibrillator.AddChangeHook(OnConVarChanged);
	rng_weapon_first_aid_kit.AddChangeHook(OnConVarChanged);
	rng_weapon_pain_pills.AddChangeHook(OnConVarChanged);
	rng_weapon_fireworkcrate.AddChangeHook(OnConVarChanged);
	rng_weapon_gascan.AddChangeHook(OnConVarChanged);
	rng_weapon_oxygentank.AddChangeHook(OnConVarChanged);
	rng_weapon_propanetank.AddChangeHook(OnConVarChanged);
	rng_weapon_molotov.AddChangeHook(OnConVarChanged);
	rng_weapon_pipe_bomb.AddChangeHook(OnConVarChanged);
	rng_weapon_vomitjar.AddChangeHook(OnConVarChanged);
	rng_weapon_ammo_spawn.AddChangeHook(OnConVarChanged);
	rng_upgrade_laser_sight.AddChangeHook(OnConVarChanged);
	rng_weapon_upgradepack_explosive.AddChangeHook(OnConVarChanged);
	rng_weapon_upgradepack_incendiary.AddChangeHook(OnConVarChanged);
	rng_weapon_gnome.AddChangeHook(OnConVarChanged);
	rng_weapon_cola_bottles.AddChangeHook(OnConVarChanged);
	rng_weapon_pistol.AddChangeHook(OnConVarChanged);
	rng_weapon_pistol_magnum.AddChangeHook(OnConVarChanged);
	rng_weapon_autoshotgun.AddChangeHook(OnConVarChanged);
	rng_weapon_hunting_rifle.AddChangeHook(OnConVarChanged);
	rng_weapon_pumpshotgun.AddChangeHook(OnConVarChanged);
	rng_weapon_grenade_launcher.AddChangeHook(OnConVarChanged);
	rng_weapon_rifle.AddChangeHook(OnConVarChanged);
	rng_weapon_rifle_ak47.AddChangeHook(OnConVarChanged);
	rng_weapon_rifle_desert.AddChangeHook(OnConVarChanged);
	rng_weapon_rifle_m60.AddChangeHook(OnConVarChanged);
	rng_weapon_rifle_sg552.AddChangeHook(OnConVarChanged);
	rng_weapon_shotgun_chrome.AddChangeHook(OnConVarChanged);
	rng_weapon_shotgun_spas.AddChangeHook(OnConVarChanged);
	rng_weapon_smg.AddChangeHook(OnConVarChanged);
	rng_weapon_smg_mp5.AddChangeHook(OnConVarChanged);
	rng_weapon_smg_silenced.AddChangeHook(OnConVarChanged);
	rng_weapon_sniper_awp.AddChangeHook(OnConVarChanged);
	rng_weapon_sniper_military.AddChangeHook(OnConVarChanged);
	rng_weapon_sniper_scout.AddChangeHook(OnConVarChanged);
	
	AutoExecConfig(true, "l4d2_nav_loot_spawner");
}

public void OnConVarChanged(Handle hConVar, const char[] oldValue, const char[] newValue)
{
	g_iLootCount = g_hLootCount.IntValue;
	g_iNavFlagsCheck = g_hNavBits.IntValue;
	g_iReachableCheck = g_hCheckReachable.IntValue;
	
	gChancesUpdate();
}

public void gChancesUpdate()
{
	gChances[0]  = rng_baseballbat.IntValue;
	gChances[1]  = rng_cricket_bat.IntValue;
	gChances[2]  = rng_crowbar.IntValue;
	gChances[3]  = rng_electric_guitar.IntValue;
	gChances[4]  = rng_fireaxe.IntValue;
	gChances[5]  = rng_frying_pan.IntValue;
	gChances[6]  = rng_golfclub.IntValue;
	gChances[7]  = rng_katana.IntValue;
	gChances[8]  = rng_machete.IntValue;
	gChances[9]  = rng_tonfa.IntValue;
	gChances[10] = rng_knife.IntValue;
	gChances[11] = rng_pitchfork.IntValue;
	gChances[12] = rng_shovel.IntValue;
	gChances[13] = rng_weapon_chainsaw.IntValue;
	gChances[14] = rng_weapon_adrenaline.IntValue;
	gChances[15] = rng_weapon_defibrillator.IntValue;
	gChances[16] = rng_weapon_first_aid_kit.IntValue;
	gChances[17] = rng_weapon_pain_pills.IntValue;
	gChances[18] = rng_weapon_fireworkcrate.IntValue;
	gChances[19] = rng_weapon_gascan.IntValue;
	gChances[20] = rng_weapon_oxygentank.IntValue;
	gChances[21] = rng_weapon_propanetank.IntValue;
	gChances[22] = rng_weapon_molotov.IntValue;
	gChances[23] = rng_weapon_pipe_bomb.IntValue;
	gChances[24] = rng_weapon_vomitjar.IntValue;
	gChances[25] = rng_weapon_ammo_spawn.IntValue;
	gChances[26] = rng_upgrade_laser_sight.IntValue;
	gChances[27] = rng_weapon_upgradepack_explosive.IntValue;
	gChances[28] = rng_weapon_upgradepack_incendiary.IntValue;
	gChances[29] = rng_weapon_gnome.IntValue;
	gChances[30] = rng_weapon_cola_bottles.IntValue;
	gChances[31] = rng_weapon_pistol.IntValue;
	gChances[32] = rng_weapon_pistol_magnum.IntValue;
	gChances[33] = rng_weapon_autoshotgun.IntValue;
	gChances[34] = rng_weapon_hunting_rifle.IntValue;
	gChances[35] = rng_weapon_pumpshotgun.IntValue;
	gChances[36] = rng_weapon_grenade_launcher.IntValue;
	gChances[37] = rng_weapon_rifle.IntValue;
	gChances[38] = rng_weapon_rifle_ak47.IntValue;
	gChances[39] = rng_weapon_rifle_desert.IntValue;
	gChances[40] = rng_weapon_rifle_m60.IntValue;
	gChances[41] = rng_weapon_rifle_sg552.IntValue;
	gChances[42] = rng_weapon_shotgun_chrome.IntValue;
	gChances[43] = rng_weapon_shotgun_spas.IntValue;
	gChances[44] = rng_weapon_smg.IntValue;
	gChances[45] = rng_weapon_smg_mp5.IntValue;
	gChances[46] = rng_weapon_smg_silenced.IntValue;
	gChances[47] = rng_weapon_sniper_awp.IntValue;
	gChances[48] = rng_weapon_sniper_military.IntValue;
	gChances[49] = rng_weapon_sniper_scout.IntValue;
}

public void OnMapStart()
{
	GameData hData = new GameData("l4d2_nav_loot");
	
	TheNavAreas = hData.GetAddress("TheNavAreas");
	TheCount = LoadFromAddress(hData.GetAddress("TheCount"), NumberType_Int32);
	
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(hData, SDKConf_Signature, "SurvivorBot::IsReachable");
	PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	g_hReachableCheck = EndPrepSDKCall();
	
	delete hData;
	
	if (TheNavAreas == Address_Null || !TheCount || g_hReachableCheck == null)
		SetFailState("[Navigation Spawner] Bad data, please check your gamedata");
	
	HookEvent("player_left_safe_area", eEvent);
	
	g_bLoaded = true;
}

public Action tSpawn (Handle timer)
{
	if(!g_alreadyspawned) 
	{
		CreateRandomLoot(g_iLootCount);
		g_alreadyspawned = true;
	}
}

public void OnMapEnd()
{
	g_bLoaded = false;
}

public void eEvent (Event event, const char[] name, bool dontbroadcast)
{
	if (!g_bLoaded)
		return;
	g_alreadyspawned = false;
	gChancesUpdate();
	CreateTimer(1.0, tSpawn);
}

void CreateRandomLoot (int count)
{
	Address iRandomArea;
	int entity;
	float vMins[3], vMaxs[3], vOrigin[3], vAngles[3];
	bool bContinue;
	
	int sum = 0;
		
	for (int g = 0; g < sizeof gChances; g++)
	{
		PrintToServer("%i - %i : %s", sum, (sum+gChances[g]),szWeapons[g]);
		sum += gChances[g];
	}
	
	for (int i = 0; i < count; i++)
	{
		if(rng_sinkroll.FloatValue >= GetRandomInt(1,100))
			return;
		
		PrintToServer("VALUE Count: %i i: %i", count, i);
		iRandomArea = view_as<Address>(LoadFromAddress(TheNavAreas + view_as<Address>(4 * GetRandomInt(0, TheCount)), NumberType_Int32));
		
		if (iRandomArea == Address_Null || (g_iNavFlagsCheck && LoadFromAddress(iRandomArea + view_as<Address>(84), NumberType_Int32) != 0x20000000))
			continue;
		
		
		vMins[0] = view_as<float>(LoadFromAddress(iRandomArea + view_as<Address>(4), NumberType_Int32));
		vMins[1] = view_as<float>(LoadFromAddress(iRandomArea + view_as<Address>(8), NumberType_Int32));
		vMins[2] = view_as<float>(LoadFromAddress(iRandomArea + view_as<Address>(12), NumberType_Int32));
		
		vMaxs[0] = view_as<float>(LoadFromAddress(iRandomArea + view_as<Address>(16), NumberType_Int32));
		vMaxs[1] = view_as<float>(LoadFromAddress(iRandomArea + view_as<Address>(20), NumberType_Int32));
		vMaxs[2] = view_as<float>(LoadFromAddress(iRandomArea + view_as<Address>(24), NumberType_Int32));

		AddVectors(vMins, vMaxs, vOrigin);
		ScaleVector(vOrigin, 0.5);
		
		if (g_iReachableCheck)
		{
			for (int l = 1; l <= MaxClients; l++) 
			{
				if (!IsClientInGame(l) || GetClientTeam(l) != 2 || !IsFakeClient(l))
					continue;
					
				if (SDKCall(g_hReachableCheck, l, vOrigin) != 1)
					bContinue = true;
				break;
			}
			
			if (bContinue)
				continue;
		}
		
		vAngles[1] = GetRandomFloat(-179.0, 179.0);
		
		int iRandom;
		
		int zWeapon = GetRandomInt(1,sum);
		PrintToServer("%i", zWeapon);
		
		for (int k = 0; zWeapon > 0; k++)
		{
			zWeapon -= gChances[k];
			iRandom = k;
		}
		PrintToServer("%s, %i", szWeapons[iRandom], iRandom);
		
		if (iRandom != 25 || iRandom != 26)
			vOrigin[2] += 21.0;
		else vOrigin[2] -= 100.0;

		if (iRandom <= 12)
		{
			Melee(szWeapons[iRandom], vOrigin, vAngles);
			continue;
		}
		
		entity = CreateEntityByName(szWeapons[iRandom]);
		
		if(!IsValidEntity(entity))
			return;

		int maxammo = 69;
		
		if (StrEqual(szWeapons[iRandom], "weapon_rifle", false) || StrEqual(szWeapons[iRandom], "weapon_rifle_ak47", false) || StrEqual(szWeapons[iRandom], "weapon_rifle_desert", false) || StrEqual(szWeapons[iRandom], "weapon_rifle_sg552", false))
		{
			maxammo = GetConVarInt(rng_assaultrifle_max);
		}
		else if (StrEqual(szWeapons[iRandom], "weapon_smg", false) || StrEqual(szWeapons[iRandom], "weapon_smg_silenced", false) || StrEqual(szWeapons[iRandom], "weapon_smg_mp5", false))
		{
			maxammo = GetConVarInt(rng_smg_max);
		}		
		else if (StrEqual(szWeapons[iRandom], "weapon_pumpshotgun", false) || StrEqual(szWeapons[iRandom], "weapon_shotgun_chrome", false))
		{
			maxammo = GetConVarInt(rng_shotgun_max);
		}
		else if (StrEqual(szWeapons[iRandom], "weapon_autoshotgun", false) || StrEqual(szWeapons[iRandom], "weapon_shotgun_spas", false))
		{
			maxammo = GetConVarInt(rng_autoshotgun_max);
		}
		else if (StrEqual(szWeapons[iRandom], "weapon_hunting_rifle", false))
		{
			maxammo = GetConVarInt(rng_huntingrifle_max);
		}
		else if  (StrEqual(szWeapons[iRandom], "weapon_sniper_awp", false) || StrEqual(szWeapons[iRandom], "weapon_sniper_scout", false) || StrEqual(szWeapons[iRandom], "weapon_sniper_military", false))
		{
			maxammo = GetConVarInt(rng_sniperrifle_max);
		}
		else if (StrEqual(szWeapons[iRandom], "weapon_grenade_launcher", false))
		{
			maxammo = GetConVarInt(rng_grenadelauncher_max);
		}
		else if (StrEqual(szWeapons[iRandom], "weapon_rifle_m60", false))
		{
			maxammo = GetConVarInt(rng_m60_max);
		}
		
		DispatchSpawn(entity);
		
		if (iRandom > 32)
		{
			SetEntProp(entity, Prop_Send, "m_iExtraPrimaryAmmo", maxammo ,4);
		}
		
		if (entity <= MaxClients)
			continue;
			
		TeleportEntity(entity, vOrigin, vAngles, NULL_VECTOR);
		
		PrintToServer("Spawned weapon at %f %f %f", vOrigin[0], vOrigin[1], vOrigin[2]);
	}
}

void Melee(const char[] szMelee, float vOrigin[3], float vAngles[3])
{
	int iWeapon = CreateEntityByName("weapon_melee");
	
	if (iWeapon <= MaxClients)
		return;
	
	DispatchKeyValue(iWeapon, "melee_script_name", szMelee);
	DispatchSpawn(iWeapon);
	TeleportEntity(iWeapon, vOrigin, vAngles, NULL_VECTOR);
	
	char szName[PLATFORM_MAX_PATH];
	GetEntPropString(iWeapon, Prop_Data, "m_ModelName", szName, sizeof szName); 
	
	if (StrContains(szName, "hunter") != -1)
		AcceptEntityInput(iWeapon, "kill");
		
	PrintToServer("Spawned weapon at %f %f %f", vOrigin[0], vOrigin[1], vOrigin[2]);
}