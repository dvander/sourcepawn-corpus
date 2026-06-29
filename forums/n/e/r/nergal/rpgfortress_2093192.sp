#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2>
#include <tf2_stocks>
#include <tf2items>
#include <morecolors>
#undef REQUIRE_EXTENSIONS
#tryinclude <steamtools>
#define REQUIRE_EXTENSIONS
 
/* C R E D I T S
props to mitch for the spells coding
arkarr for suggestions and help, and magic spell timer
Flamin' Sarge for various code snippets from his plugins
noodleboy347 for level mod
Zephyreus for help
TAZ - for LOADS OF help lol
IF IT WEREN'T FOR THESE GUYS, THIS PLUGIN WOULDN'T EXIST.
Props to uberpirates for supporting and giving ideas for this mod :>
*/

/* I D E A S

use cookies for player levels
more crap/buildables for engineer
unlock Spy

*/

#define PLUGIN_VERSION "1.10 BETA"
 
new playerLevel[MAXPLAYERS+1];
new playerExp[MAXPLAYERS+1];
new playerExpMax[MAXPLAYERS+1];

new Handle:levelHUD[MAXPLAYERS+1] = INVALID_HANDLE;
new Handle:hudLevel;
new Handle:hudEXP;
new Handle:hudPlus1;
new Handle:hudPlus2;
new Handle:hudLevelUp;
new Handle:Armortext;
new Handle:Prayertext;

new Handle:playertimerh[MAXPLAYERS+1] = INVALID_HANDLE;
new Handle:prayertimerh[MAXPLAYERS+1] = INVALID_HANDLE;
new Handle:cvar_level_default;
new Handle:cvar_exp_levelup;
new Handle:cvar_level_max;
new Handle:cvar_exp_default;
new Handle:cvar_exp_onkill;
new Handle:cvar_exp_ondmg;

new Float:g_iSpell[MAXPLAYERS+1];
new Float:Cooldown[MAXPLAYERS+1];

new armor[MAXPLAYERS+1];
new MaxArmor[MAXPLAYERS+1];
new ArmorType[MAXPLAYERS+1];
new Float:DamageResistance[MAXPLAYERS+1];

new Handle:rs_enable = INVALID_HANDLE;

new Handle:cvar_fireball_recharge = INVALID_HANDLE;
new Handle:cvar_hellfire_recharge = INVALID_HANDLE;
new Handle:cvar_electric_recharge = INVALID_HANDLE;
new Handle:cvar_meteor_recharge = INVALID_HANDLE;

new Handle:spellsregen[MAXPLAYERS+1] = INVALID_HANDLE;

new Handle:prayer_charge_timer = INVALID_HANDLE;
new Handle:PrayerChargeInt = INVALID_HANDLE;
new PrayerCond[MAXPLAYERS+1];
new PrayerCharge[MAXPLAYERS+1];

new Handle:armor_from_metal = INVALID_HANDLE;
new Handle:allow_armor_damage = INVALID_HANDLE;

new Handle:cvar_prayer_melee_dmgreduce = INVALID_HANDLE;
new Handle:cvar_prayer_ranged_dmgreduce = INVALID_HANDLE;
new Handle:cvar_prayer_magic_dmgreduce = INVALID_HANDLE;

new Handle:maxarmor_melee = INVALID_HANDLE;
new Handle:maxarmor_ranged = INVALID_HANDLE;
new Handle:maxarmor_magic = INVALID_HANDLE;

new Handle:damage_resistance_melee = INVALID_HANDLE;
new Handle:damage_resistance_ranged = INVALID_HANDLE;
new Handle:damage_resistance_magic = INVALID_HANDLE;

new Handle:damage_vuln_melee = INVALID_HANDLE;
new Handle:damage_vuln_ranged = INVALID_HANDLE;
new Handle:damage_vuln_magic = INVALID_HANDLE;

new Handle:player_speed_medic = INVALID_HANDLE;
new Handle:player_speed_engineer = INVALID_HANDLE;
new Handle:player_speed_sniper = INVALID_HANDLE;
new Handle:player_speed_soldier = INVALID_HANDLE;
new Handle:player_speed_spy = INVALID_HANDLE;

#if defined _steamtools_included
new bool:steamtools = false;
#endif
new Handle:advert_timer = INVALID_HANDLE;
 
public Plugin:myinfo = {
        name = "RPG Fortress",
        author = "Assyrian/Nergal & others",
        description = "RPG Fortress for Medieval Mode",
        version = PLUGIN_VERSION,
        url = "http://steamcommunity.com/groups/acvsh | http://forums.alliedmods.net/showthread.php?t=230178"
};
 
public OnPluginStart()
{
        RegConsoleCmd("sm_rpg", RS_Menu, "RPG Fortress menu");

        CreateConVar("rpg_version", PLUGIN_VERSION, "RPG Fortress Version", FCVAR_NOTIFY|FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_DONTRECORD);
        rs_enable = CreateConVar("rpg_enabled", "1", "Enables RPG Fortress mod", FCVAR_PLUGIN, true, 0.0, true, 1.0);

	prayer_charge_timer = CreateConVar("rpg_prayercharge_timer", "1.0", "this cvar will give players a set amount of prayer charge every  seconds", FCVAR_PLUGIN|FCVAR_NOTIFY);
	PrayerChargeInt = CreateConVar("rpg_prayer_charge_amount", "1", "this cvar adds prayer charge every second that is set by rs_prayercharge_timer", FCVAR_PLUGIN|FCVAR_NOTIFY);

	cvar_fireball_recharge = CreateConVar("rpg_fireball_recharge", "4.0", "Every x seconds, 1 fireball spell will be added", FCVAR_PLUGIN|FCVAR_NOTIFY);
        cvar_hellfire_recharge = CreateConVar("rpg_hellfire_recharge", "3.0", "Every x seconds, 1 hellfire spell will be added", FCVAR_PLUGIN|FCVAR_NOTIFY);
        cvar_electric_recharge = CreateConVar("rpg_electric_recharge", "8.0", "Every x seconds, 1 electrical bolt spell will be added", FCVAR_PLUGIN|FCVAR_NOTIFY);
        cvar_meteor_recharge = CreateConVar("rpg_meteor_recharge", "10.0", "Every x seconds, 1 metoer shower spell will be added", FCVAR_PLUGIN|FCVAR_NOTIFY);

	cvar_prayer_melee_dmgreduce = CreateConVar("rpg_melee_dmgreduce", "0.75", "damage multiplier if player has Protect from Melee activated", FCVAR_PLUGIN|FCVAR_NOTIFY);
	cvar_prayer_ranged_dmgreduce = CreateConVar("rpg_ranged_dmgreduce", "0.7", "damage multiplier if player has Protect from Ranged activated", FCVAR_PLUGIN|FCVAR_NOTIFY);
	cvar_prayer_magic_dmgreduce = CreateConVar("rpg_magic_dmgreduce", "0.6", "damage multiplier if player has Protect from Magic activated", FCVAR_PLUGIN|FCVAR_NOTIFY);

        advert_timer = CreateConVar("rpg_advert_timer", "90.0", "amount of time the plugin advert will pop up", FCVAR_PLUGIN|FCVAR_NOTIFY);

	armor_from_metal = CreateConVar("rpg_metaltoarmor", "25", "converts metal, from engineer, to armor for teammates", FCVAR_PLUGIN|FCVAR_NOTIFY);
	allow_armor_damage = CreateConVar("rpg_allow_armor_damage", "1", "Enables if armor goes away from damage", FCVAR_PLUGIN, true, 0.0, true, 1.0);

	maxarmor_melee = CreateConVar("rpg_maxarmor_melee", "100", "how much max melee armor a player can wear", FCVAR_PLUGIN|FCVAR_NOTIFY);
	maxarmor_magic = CreateConVar("rpg_maxarmor_magic", "75", "how much max magic armor a player can wear", FCVAR_PLUGIN|FCVAR_NOTIFY);
	maxarmor_ranged = CreateConVar("rpg_maxarmor_ranged", "100", "how much max ranged armor a player can wear", FCVAR_PLUGIN|FCVAR_NOTIFY);

	damage_resistance_melee = CreateConVar("rpg_armor_resistance_melee", "0.3", "how damage should Armor absorb from melee", FCVAR_PLUGIN|FCVAR_NOTIFY);
	damage_resistance_ranged = CreateConVar("rpg_armor_resistance_ranged", "0.3", "how damage should Armor absorb from ranged", FCVAR_PLUGIN|FCVAR_NOTIFY);
	damage_resistance_magic = CreateConVar("rpg_armor_resistance_magic", "0.6", "how damage should Armor absorb from magic", FCVAR_PLUGIN|FCVAR_NOTIFY);

	damage_vuln_melee = CreateConVar("rpg_damage_vuln_melee", "1.2", "how much vulnerability to melee damage", FCVAR_PLUGIN|FCVAR_NOTIFY);
	damage_vuln_ranged = CreateConVar("rpg_damage_vuln_ranged", "1.2", "how much vulnerability to ranged damage", FCVAR_PLUGIN|FCVAR_NOTIFY);
	damage_vuln_magic = CreateConVar("rpg_damage_vuln_magic", "1.4", "how much vulnerability to magic damage", FCVAR_PLUGIN|FCVAR_NOTIFY);

        HookConVarChange(FindConVar("sv_tags"), cvarChange_Tags); //props to Flamin' Sarge
#if defined _steamtools_included
        steamtools = LibraryExists("SteamTools");
#endif
        cvar_level_default = CreateConVar("rpg_level_default", "1", "Default level for players when they join");
        cvar_level_max = CreateConVar("rpg_level_max", "99", "Maximum level players can reach and use to calculate damage");
        cvar_exp_default = CreateConVar("rpg_exp_default", "83", "Default max experience for players when they join");
        cvar_exp_onkill = CreateConVar("rpg_exp_onkill", "216", "Experience to gain on kill");
	cvar_exp_levelup = CreateConVar("rpg_exp_levelup", "0.833", "Experience increase on level up");
        cvar_exp_ondmg = CreateConVar("rpg_exp_damage_mult", "1.0", "Experience multiplier for damage");

	player_speed_medic = CreateConVar("rpg_playerspeed_medic", "350.0", "speed of Medics in Hammer units");
	player_speed_engineer = CreateConVar("rpg_playerspeed_engie", "350.0", "speed of Engineers in Hammer units");
	player_speed_sniper = CreateConVar("rpg_playerspeed_sniper", "350.0", "speed of Snipers in Hammer units");
	player_speed_soldier = CreateConVar("rpg_playerspeed_soldier", "350.0", "speed of Soldiers in Hammer units");
	player_speed_spy = CreateConVar("rpg_playerspeed_spy", "350.0", "speed of Spies in Hammer units");

        AutoExecConfig(true, "RPG_Fortress");
       
        // = CreateConVar("", "0", "", FCVAR_PLUGIN, true, 0.0, true, 1.0);
        hudLevel = CreateHudSynchronizer();
        hudEXP = CreateHudSynchronizer();
	Armortext = CreateHudSynchronizer();
	Prayertext = CreateHudSynchronizer();
        hudPlus1 = CreateHudSynchronizer();
        hudPlus2 = CreateHudSynchronizer();
        hudLevelUp = CreateHudSynchronizer();
        HookEvent("teamplay_round_start", event_round_start);
        HookEvent("player_spawn", event_player_spawn);
        HookEvent("player_death", event_player_death, EventHookMode_Pre);
        HookEvent("player_hurt", event_hurt, EventHookMode_Pre);
        HookEvent("player_changeclass", event_changeclass);
	//HookEvent("player_builtobject", Event_player_builtobject);
        for (new client = 0; client <= MaxClients; client++)
        {
                if (IsValidClient(client, false))
		{
			SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
			SDKHook(client, SDKHook_TraceAttack, TraceAttack);
		}
        }
}
public OnClientDisconnect(client)
{
	ClearTimer(spellsregen[client]);
	ClearTimer(levelHUD[client]);
	ClearTimer(playertimerh[client]);
	ClearTimer(prayertimerh[client]);
	PrayerCond[client] = -1;
	PrayerCharge[client] = 0;
	armor[client] = 0;
	MaxArmor[client] = 0;
	ArmorType[client] = 0;
	playerLevel[client] = 0;
}
public OnMapStart()
{
	if (GetConVarBool(rs_enable))
        {
		new search = -1;
		while ((search = FindEntityByClassname(search, "func_regenerate")) != -1)
                {
                        AcceptEntityInput(search, "Disable", -1, -1, 0);
                }
		CreateTimer(GetConVarFloat(advert_timer), Timer_Announce, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
        }
}
public Action:Timer_Announce(Handle:hTimer)
{
	CPrintToChatAll("{orange}[RPG Fortress] {default}type {green}!rpg{default} to access menu");
}
public OnConfigsExecuted()
{
	if (GetConVarBool(rs_enable)) 
	{
		TagsCheck("runescape, rs, rpg", true);
#if defined _steamtools_included
        	if (steamtools)
        	{
			decl String:gameDesc[64];
			Format(gameDesc, sizeof(gameDesc), "RPG Fortress (%s)", PLUGIN_VERSION);
			Steam_SetGameDescription(gameDesc);
        	}
#endif
	}
}
public cvarChange_Tags(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (GetConVarBool(rs_enable))
		TagsCheck("runescape, rs, rpg", false);
}
public OnLibraryAdded(const String:name[])
{
#if defined _steamtools_included
	if (strcmp(name, "SteamTools", false) == 0)
                steamtools = true;
#endif
}
public OnLibraryRemoved(const String:name[])
{
#if defined _steamtools_included
	if (strcmp(name, "SteamTools", false) == 0)
		steamtools = false;
#endif
}
/*
new sgShieldProp = CreateEntityByName("prop_dynamic");
new Float:tempVec[3] = {0.0,...}; //vector to teleport it to
DispatchKeyValue(sgShieldProp, "model", "models/buildables/sentry_shield.mdl");
DispatchKeyValue(sgShieldProp, "skin", "0"); //0 is red, 1 is blu
DispatchSpawn(sgShieldProp);
TeleportEntity(sgShieldProp, tempVec, NULL_VECTOR, NULL_VECTOR);
AcceptEntityInput(sgShieldProp, "TurnOn");
*/
public OnClientPutInServer(client)
{
	if (GetConVarBool(rs_enable))
        {
                SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
		SDKHook(client, SDKHook_TraceAttack, TraceAttack);
		PrayerCond[client] = -1;
		PrayerCharge[client] = 0;
		armor[client] = 0;
		MaxArmor[client] = 0;
		ArmorType[client] = 0;
		prayertimerh[client] = CreateTimer(GetConVarFloat(prayer_charge_timer), Timer_PrayerRegen, client, TIMER_REPEAT);
                playerLevel[client] = GetConVarInt(cvar_level_default);
                levelHUD[client] = CreateTimer(0.3, DrawHud, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
                playerExp[client] = 0;
                playerExpMax[client] = GetConVarInt(cvar_exp_default);
        }
}
public Action:DrawHud(Handle:timer, any:client)
{
	if (IsValidClient(client) && IsClientInGame(client) && !IsFakeClient(client) && GetConVarBool(rs_enable))
	{
		if (playerExp[client] >= playerExpMax[client] && playerLevel[client] < GetConVarInt(cvar_level_max))
		{
			LevelUp(client, playerLevel[client] + 1);
		}
		SetHudTextParams(0.14, 0.80, 1.0, 100, 200, 255, 150);
		ShowSyncHudText(client, hudLevel, "Level: %i", playerLevel[client]);
		SetHudTextParams(0.14, 0.83, 1.0, 255, 200, 100, 150);

		if (playerLevel[client] >= GetConVarInt(cvar_level_max))
		{
			ShowSyncHudText(client, hudEXP, "MAX LEVEL REACHED", playerExp[client], playerExpMax[client]);
		}
		else
		{
			ShowSyncHudText(client, hudEXP, "EXP: %i/%i", playerExp[client], playerExpMax[client]);
		}

		SetHudTextParams(0.14, 0.78, 1.0, 255, 90, 30, 150);
		ShowSyncHudText(client, Armortext, "Armor: %i", armor[client]);
		SetHudTextParams(0.14, 0.75, 1.0, 100, 200, 255, 150);
		ShowSyncHudText(client, Prayertext, "Prayer Charge: %i", PrayerCharge[client]);
	}
        return Plugin_Continue;
}
public Action:RS_Menu(client, args)
{
        if (client && IsClientInGame(client) && !IsFakeClient(client) && !IsClientObserver(client) && GetConVarBool(rs_enable))
        {
		new Handle:MainMenu = CreateMenu(MenuHandler_RS1);
 
                SetMenuTitle(MainMenu, "Main Menu - Choose Category:");
                AddMenuItem(MainMenu, "pick_weapon", "Choose a Weapon");
                AddMenuItem(MainMenu, "pick_prayer", "Choose a Prayer");
               
                DisplayMenu(MainMenu, client, MENU_TIME_FOREVER);
        }
        return Plugin_Handled;
}

public MenuHandler_RS1(Handle:menu, MenuAction:action, client, param2)
{  
	new String:info[32];
	GetMenuItem(menu, param2, info, sizeof(info));
	if (action == MenuAction_Select)
        {
		param2++;
		if (param2 == 1)
                {
                        MenuChooseWeapon(client, -1);
                }
		else if (param2 == 2)
                {
                        Prayer_Menu(client, -1);
                }
        }
	else if (action == MenuAction_End)
        {
                CloseHandle(menu);
        }
}
public Action:Prayer_Menu(client, args)
{
	if (client && IsClientInGame(client) && !IsFakeClient(client) && GetConVarBool(rs_enable))
        {
		new Handle:prayMenu = CreateMenu(MenuHandler_Prayer);
 
                SetMenuTitle(prayMenu, "Select Your Prayer; press +attack3 to activate Prayer!");
                AddMenuItem(prayMenu, "none", "Select No Prayer");
                AddMenuItem(prayMenu, "meleeprtct", "Protect from Melee");
                AddMenuItem(prayMenu, "rangedprtct", "Protect from Ranged");
                AddMenuItem(prayMenu, "magicprtct", "Protect from Magic");
                AddMenuItem(prayMenu, "critimmunity", "Immunity from Crits");
		SetMenuExitBackButton(prayMenu, true);
               
                DisplayMenu(prayMenu, client, MENU_TIME_FOREVER);
        }
	return Plugin_Handled;
}
public MenuHandler_Prayer(Handle:menu, MenuAction:action, client, param2)
{
	new String:info6[32];
	GetMenuItem(menu, param2, info6, sizeof(info6));
	if (action == MenuAction_Select)
        {
                param2++;
		if (param2 == 1)
                {
			PrayerCond[client] = -1;
                }
		else if (param2 == 2)
                {
			PrayerCond[client] = _:TFCond_SmallBulletResist;
                }
		else if (param2 == 3)
                {
			PrayerCond[client] = _:TFCond_SmallBlastResist;
                }
		else if (param2 == 4)
                {
			PrayerCond[client] = _:TFCond_SmallFireResist;
                }
		else if (param2 == 5)
                {
			PrayerCond[client] = _:TFCond_DefenseBuffed;
                }
        }
	else if (action == MenuAction_End)
        {
                CloseHandle(menu);
        }
}
public Action:MenuChooseWeapon(client, args)
{
        if (client && IsClientInGame(client) && !IsFakeClient(client) && !IsClientObserver(client) && IsValidClient(client) && IsPlayerAlive(client))
        {
		if (TF2_GetPlayerClass(client) == TFClass_Sniper)
		{
			new Handle:rangeSelect = CreateMenu(MenuHandler_GiveRangeWep);
			SetMenuTitle(rangeSelect, "Choose Your Ranged Weapon:");
			AddMenuItem(rangeSelect, "huntsman", "Huntsman");
			AddMenuItem(rangeSelect, "cleaver", "Cleaver");
			AddMenuItem(rangeSelect, "crossbow", "Crossbow");
			AddMenuItem(rangeSelect, "cannon", "Cannon");
			SetMenuExitBackButton(rangeSelect, true);
			DisplayMenu(rangeSelect, client, MENU_TIME_FOREVER);
		}
                else if (TF2_GetPlayerClass(client) == TFClass_Soldier)
                {
			new Handle:meleemenuSelect = CreateMenu(MenuHandler_GiveMeleeWep);    
			SetMenuTitle(meleemenuSelect, "Choose Your Melee Weapon:");
			AddMenuItem(meleemenuSelect, "bbasher", "Boston Basher: +20% firing speed, 3+ hp regen");
			AddMenuItem(meleemenuSelect, "pan", "Frying Pan: -20% damage penalty, +50% fire rate");
			AddMenuItem(meleemenuSelect, "3rune", "Three-Rune Blade: +25% damage bonus");
			AddMenuItem(meleemenuSelect, "ham", "Ham Shank (Pan Reskin): -20% damage penalty, +60% fire rate");
			AddMenuItem(meleemenuSelect, "equalizer", "The Equalizer: deal more damage as your health lowers");
			AddMenuItem(meleemenuSelect, "katana", "Half-Katana: On Hit: +40 hp");
			AddMenuItem(meleemenuSelect, "maul", "Obsidian Maul: +125% damage bonus, 70% slower fire rate");
			AddMenuItem(meleemenuSelect, "scimmy", "Scimitar: +30% fire rate");
			AddMenuItem(meleemenuSelect, "axting", "Axtinguisher: On Hit: Ignite enemy");
			SetMenuExitBackButton(meleemenuSelect, true);
			DisplayMenu(meleemenuSelect, client, MENU_TIME_FOREVER);
                }
		else if (TF2_GetPlayerClass(client) == TFClass_Medic)
                {
			new Handle:magicSelect = CreateMenu(MenuHandler_GiveMageWep);
			SetMenuTitle(magicSelect, "Choose Your Magic Spell:");
			AddMenuItem(magicSelect, "banner", "Fireballs");
			AddMenuItem(magicSelect, "shrtcrcuit", "Electric Bolts");
			AddMenuItem(magicSelect, "backup", "Hellfire Missiles");
			AddMenuItem(magicSelect, "backup", "Meteor Shower");
			SetMenuExitBackButton(magicSelect, true);
			DisplayMenu(magicSelect, client, MENU_TIME_FOREVER);
                }
		else if (TF2_GetPlayerClass(client) == TFClass_Spy)
		{
			new Handle:rogueSelect = CreateMenu(MenuHandler_GiveRogueWep);
			SetMenuTitle(rogueSelect, "Choose Your Ranged Weapon:");
			AddMenuItem(rogueSelect, "knife", "Knife");
			AddMenuItem(rogueSelect, "yer", "Your Anal Reward");
			AddMenuItem(rogueSelect, "kunai", "Kunai");
			AddMenuItem(rogueSelect, "bigurnur", "Big Earner");
			AddMenuItem(rogueSelect, "sharpdress", "The Sharp Dresser");
			AddMenuItem(rogueSelect, "icepick", "The Spy-cicle");
			AddMenuItem(rogueSelect, "blkrose", "The Black Rose");
			AddMenuItem(rogueSelect, "pan", "Gold Frying Pan");
			AddMenuItem(rogueSelect, "kukri", "Kukri");
			SetMenuExitBackButton(rogueSelect, true);
			DisplayMenu(rogueSelect, client, MENU_TIME_FOREVER);
		}
        }
}
public MenuHandler_GiveRogueWep(Handle:menu, MenuAction:action, client, param2)
{
        new String:info12[32];
        GetMenuItem(menu, param2, info12, sizeof(info12));
        if (action == MenuAction_Select)
        {
		TF2_RemoveAllWeapons(client);
		param2++;
		if (param2 == 1) //knife
		{
		}
		else if (param2 == 2) //YER
		{
		}
		else if (param2 == 3) //kunai
		{
		}
		else if (param2 == 4) //bigearner
		{
		}
		else if (param2 == 5) //sharp dresser
		{
		}
		else if (param2 == 6) //spycicle
		{
		}
		else if (param2 == 7) //blackrose
		{
		}
		else if (param2 == 8) //gold frying pan
		{
		}
		else if (param2 == 9) //kukri
		{
		}
		SpawnWeapon(client, "tf_weapon_builder", 28, 5, 10, "57 ; 5.0 ; 26 ; 25 ; 252 ; 0");
		SpawnWeapon(client, "tf_weapon_invis", 59, 1, 0, "53 ; 1.0 ; 34 ; 1.6 ; 35 ; 2.5");
        }
        else if (action == MenuAction_End)
        {
                CloseHandle(menu);
        }
}
public MenuHandler_GiveRangeWep(Handle:menu, MenuAction:action, client, param2)
{
        new String:info2[32];
        GetMenuItem(menu, param2, info2, sizeof(info2));
        if (action == MenuAction_Select)
        {
		TF2_RemoveAllWeapons(client);
		param2++;
		if (param2 == 1)
		{
                        SpawnWeapon(client, "tf_weapon_compound_bow", 56, 100, 5, "2 ; 1.50");
                        SetAmmo(client, 0, 100);
                }
                else if (param2 == 2)
                {
                        new weapon;
                        weapon = SpawnWeapon(client, "tf_weapon_cleaver", 812, 100, 5, "6 ; 0.75");
                        SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", weapon);
                        SetAmmo(client, 1, 100);
                }
		else if (param2 == 3)
                {
                        SpawnWeapon(client, "tf_weapon_crossbow", 305, 100, 5, "2 ; 2.0");
                        SetAmmo(client, 0, 100);
                }
                else if (param2 == 4)
                {
                        SpawnWeapon(client, "tf_weapon_cannon", 996, 100, 5, "100 ; 0.7 ; 3 ; 0.25 ; 103 ; 2.0 ; 2 ; 1.50");
                        SetAmmo(client, 0, 100);
                }
                SpawnWeapon(client, "tf_weapon_builder", 28, 5, 10, "57 ; 5.0 ; 26 ; 75 ; 252 ; 0");
        }
        else if (action == MenuAction_End)
        {
                CloseHandle(menu);
        }
}
public MenuHandler_GiveMeleeWep(Handle:menu, MenuAction:action, client, param2)
{
        new String:info3[32];
        GetMenuItem(menu, param2, info3, sizeof(info3));
        if (action == MenuAction_Select)
        {
                TF2_RemoveAllWeapons(client);
                param2++;
                if (param2 == 1)
                {
                        SpawnWeapon(client, "tf_weapon_shovel", 325, 100, 5, "6 ; 0.80 ; 57 ; 3.0");//boston basher
                }
                else if (param2 == 2)
                {
                        SpawnWeapon(client, "tf_weapon_shovel", 264, 100, 5, "1 ; 0.8 ; 6 ; 0.50");//pan
                }
                else if (param2 == 3)
                {
                        SpawnWeapon(client, "tf_weapon_shovel", 452, 100, 5, "2 ; 1.25");//3-rune blade
                }
                else if (param2 == 4)
                {
                        SpawnWeapon(client, "tf_weapon_shovel", 1013, 100, 5, "1 ; 0.8 ; 6 ; 0.50");//ham
                }
                else if (param2 == 5)
                {
                        SpawnWeapon(client, "tf_weapon_shovel", 128, 100, 5, "115 ; 1.0");//equalizer
                }
                else if (param2 == 6)
                {
                        SpawnWeapon(client, "tf_weapon_shovel", 357, 100, 5, "16 ; 40");//katana
                }
                else if (param2 == 7)
                {
                        SpawnWeapon(client, "tf_weapon_shovel", 466, 100, 5, "2 ; 2.25 ; 5 ; 1.70");//maul
                }
                else if (param2 == 8)
                {
                        SpawnWeapon(client, "tf_weapon_shovel", 404, 100, 5, "6 ; 0.70");//persian persuader
                }
		else if (param2 == 9)
                {
                        SpawnWeapon(client, "tf_weapon_shovel", 38, 100, 5, "208 ; 1.0");//axtinguisher
                }
                SpawnWeapon(client, "tf_weapon_builder", 28, 5, 10, "57 ; 5.0 ; 252 ; 0");
        }
        else if (action == MenuAction_End)
        {
                CloseHandle(menu);
        }
}
public MenuHandler_GiveMageWep(Handle:menu, MenuAction:action, client, param2)
{
        new String:info4[32];
        GetMenuItem(menu, param2, info4, sizeof(info4));
        if (action == MenuAction_Select)
        {
/*spell list
0 Fireball
1 Missile thingy (bats)
2 Ubercharge - healing aura
3 Bomb
4 Super Jump
5 Invisible
6 Teleport
7 Electric Bolt
8 Small body, big head, speed
9 TEAM MONOCULUS
10 Meteor Shower
11 Skeleton Army (Spawns 3)
*/
		ClearTimer(spellsregen[client]);
                TF2_RemoveAllWeapons(client);
		if (IsValidEntity(FindPlayerBack(client, { 463 , 438, 167, 1015, 477, 30015, 489 }, 7)))
			RemovePlayerBack(client, { 463 , 438, 167, 1015, 477, 30015, 489 }, 7);

		param2++;
                if (param2 == 1)
                {
			SpawnWeapon(client, "tf_weapon_spellbook", 1069, 100, 5, "2 ; 1.0");
			SpawnWeapon(client, "tf_weapon_buff_item", 129, 100, 5, "2 ; 1.0");
			SetSpell(client, 0, 0); //fireball
                }
                else if (param2 == 2)
                {
			SpawnWeapon(client, "tf_weapon_spellbook", 1069, 100, 5, "2 ; 1.0");
			SpawnWeapon(client, "tf_weapon_buff_item", 129, 100, 5, "2 ; 1.0");
                        SetSpell(client, 7, 0); //electrical orb
                }
                else if (param2 == 3)
                {
			SpawnWeapon(client, "tf_weapon_spellbook", 1069, 100, 5, "2 ; 1.0");
			SpawnWeapon(client, "tf_weapon_buff_item", 226, 100, 5, "2 ; 1.0");
			SetSpell(client, 1, 0); //hellfire missiles
                }
                else if (param2 == 4)
                {
			SpawnWeapon(client, "tf_weapon_spellbook", 1069, 100, 5, "2 ; 1.0");
                        SpawnWeapon(client, "tf_weapon_buff_item", 226, 100, 5, "2 ; 1.0");
                        SetSpell(client, 10, 0); //meteor shower
                }
                SpawnWeapon(client, "tf_weapon_builder", 28, 5, 10, "57 ; 2.0 ; 26 ; 25 ; 252 ; 0");
		if (spellsregen[client] == INVALID_HANDLE)
		{
			spellsregen[client] = CreateTimer(0.1, RegenSpells, client, TIMER_REPEAT);
		}
        }
        else if (action == MenuAction_End)
        {
                CloseHandle(menu);
        }
}
public Action:PlayerTimer(Handle:hTimer, any:client)
{
        if (!IsValidClient(client, false))
        {
		return Plugin_Stop;
        }
	new TFClassType:class = TF2_GetPlayerClass(client);
	if (class == TFClass_Engineer)
		SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", GetConVarFloat(player_speed_engineer));
	else if (class == TFClass_Medic)
		SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", GetConVarFloat(player_speed_medic));
	else if (class == TFClass_Sniper)
		SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", GetConVarFloat(player_speed_sniper));
	else if (class == TFClass_Soldier)
		SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", GetConVarFloat(player_speed_soldier));
	else if (class == TFClass_Spy)
		SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", GetConVarFloat(player_speed_spy));

        if (TF2_IsPlayerInCondition(client, TFCond_Bleeding))
                TF2_RemoveCondition(client, TFCond_Bleeding);
	
	new buttons = GetClientButtons(client);
	if ((buttons & IN_ATTACK3) && IsPlayerAlive(client) && IsClientInGame(client) && !IsFakeClient(client) && !IsClientObserver(client))
		Command_ActivatePrayer(client);
	if (!(buttons & IN_ATTACK3) || !IsPlayerAlive(client) || !IsClientInGame(client) || IsClientObserver(client))
		Command_DeactivatePrayer(client);
        return Plugin_Continue;
}
public Action:event_player_spawn(Handle:event, const String:name[], bool:dontBroadcast)
{
        if (GetConVarBool(rs_enable))
        {
                new client = GetClientOfUserId(GetEventInt(event, "userid"));
                if (!IsValidClient(client, false))
                {
                        return Plugin_Continue;
                }
		new TFClassType:playerclass = TF2_GetPlayerClass(client);
		switch (playerclass)
                {
                        case TFClass_Scout, TFClass_Pyro, TFClass_Heavy, TFClass_DemoMan, TFClass_Soldier:
                        {
				TF2_SetPlayerClass(client, TFClass_Soldier, _, false);
				MaxArmor[client] = GetConVarInt(maxarmor_melee);
				ArmorType[client] = 1;
                        }
			case TFClass_Engineer:
			{
				TF2_SetPlayerClass(client, TFClass_Engineer, _, false);
				MaxArmor[client] = GetConVarInt(maxarmor_melee);
				ArmorType[client] = 1;
				SetEntProp(client, Prop_Data, "m_iAmmo", 500, 4, 3);
			}
                        case TFClass_Medic:
			{
				TF2_SetPlayerClass(client, TFClass_Medic, _, false);
				MaxArmor[client] = GetConVarInt(maxarmor_magic);
				ArmorType[client] = 3;
			}
                        case TFClass_Sniper:
			{
				TF2_SetPlayerClass(client, TFClass_Sniper, _, false);
				MaxArmor[client] = GetConVarInt(maxarmor_ranged);
				ArmorType[client] = 2;
			}
			case TFClass_Spy:
			{
				TF2_SetPlayerClass(client, TFClass_Spy, _, false);
				MaxArmor[client] = GetConVarInt(maxarmor_melee);
				ArmorType[client] = 1;
			}
                }
                TF2_RemoveAllWeapons(client);
		new TFClassType:equipclass = TF2_GetPlayerClass(client);
		switch (equipclass)
		{
			case TFClass_Soldier:
			{
				SpawnWeapon(client, "tf_weapon_shovel", 452, 100, 5, "2 ; 1.25");
				SpawnWeapon(client, "tf_weapon_builder", 28, 5, 10, "57 ; 5.0 ; 252 ; 0");
			}
			case TFClass_Engineer:
			{
				SpawnWeapon(client, "tf_weapon_builder", 28, 5, 10, "57 ; 5.0 ; 26 ; 50 ; 252 ; 0 ; 80 ; 2.5");
				SpawnWeapon(client, "tf_weapon_wrench", 7, 100, 5, "1 ; 0.7 ; 6 ; 0.50 ; 92 ; 1.50"); //wrench
			}
			case TFClass_Medic:
			{
				if (IsValidEntity(FindPlayerBack(client, { 463 , 438, 167, 1015, 477, 30015, 489 }, 7)))
					RemovePlayerBack(client, { 463 , 438, 167, 1015, 477, 30015, 489 }, 7);
				SpawnWeapon(client, "tf_weapon_spellbook", 1069, 100, 5, "2 ; 1.0");
				SpawnWeapon(client, "tf_weapon_buff_item", 226, 100, 5, "2 ; 1.0");
				SetSpell(client, 1, 0);
                		SpawnWeapon(client, "tf_weapon_builder", 28, 5, 10, "57 ; 2.0 ; 26 ; 25 ; 252 ; 0");
			}
			case TFClass_Sniper:
			{
				SpawnWeapon(client, "tf_weapon_builder", 28, 5, 10, "57 ; 5.0 ; 26 ; 75 ; 252 ; 0");
				SpawnWeapon(client, "tf_weapon_compound_bow", 56, 100, 5, "2 ; 1.50");
				SetAmmo(client, 0, 100);
			}
			case TFClass_Spy:
			{
				SpawnWeapon(client, "tf_weapon_knife", 4, 100, 5, "2 ; 1.0");
				SpawnWeapon(client, "tf_weapon_builder", 28, 5, 10, "57 ; 5.0 ; 252 ; 0");
				SpawnWeapon(client, "tf_weapon_invis", 59, 1, 0, "53 ; 1.0 ; 34 ; 1.6 ; 35 ; 2.5");
			}
		}
		TF2_AddCondition(client, TFCond_Ubercharged, 3.0);
                playertimerh[client] = CreateTimer(0.2, PlayerTimer, client, TIMER_REPEAT);
                RS_Menu(client, -1);
        }
        return Plugin_Continue;
}
public Action:event_changeclass(Handle:event, const String:name[], bool:dontBroadcast)
{
        if (GetConVarBool(rs_enable))
        {
                new client = GetClientOfUserId(GetEventInt(event, "userid"));
                new TFClassType:changeclass = TF2_GetPlayerClass(client);
                switch (changeclass)
                {
                        case TFClass_Scout, TFClass_Pyro, TFClass_Heavy, TFClass_DemoMan, TFClass_Soldier:
				if (TF2_GetPlayerClass(client) != TFClass_Soldier)
					TF2_SetPlayerClass(client, TFClass_Soldier, _, false);
			case TFClass_Engineer:
				if (TF2_GetPlayerClass(client) != TFClass_Engineer)
					TF2_SetPlayerClass(client, TFClass_Engineer, _, false);
                        case TFClass_Sniper:
                                if (TF2_GetPlayerClass(client) != TFClass_Sniper)
                                        TF2_SetPlayerClass(client, TFClass_Sniper, _, false);
                        case TFClass_Medic:
                                if (TF2_GetPlayerClass(client) != TFClass_Medic)
                                        TF2_SetPlayerClass(client, TFClass_Medic, _, false);
			case TFClass_Spy:
                                if (TF2_GetPlayerClass(client) != TFClass_Spy)
                                        TF2_SetPlayerClass(client, TFClass_Spy, _, false);
                }
		TF2_RemovePlayerDisguise(client);
		armor[client] = 0;    
        }
        return Plugin_Continue;
}
public Action:event_player_death(Handle:event, const String:name[], bool:dontBroadcast)
{
        new client = GetClientOfUserId(GetEventInt(event, "userid"));
        new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
        if (!IsValidClient(client) || !IsValidClient(attacker))
        {
                return Plugin_Continue;
        }
	armor[client] = 0;
	PrayerCharge[client] = 0;

	if (attacker > 0 && attacker <= MaxClients && attacker != client && GetConVarInt(cvar_exp_onkill) >= 1 && playerLevel[attacker] < GetConVarInt(cvar_level_max) && IsClientInGame(attacker))
	{
		new expBoost1 = GetConVarInt(cvar_exp_onkill);
		playerExp[attacker] += expBoost1;
		SetHudTextParams(0.28, 0.93, 1.0, 255, 100, 100, 150, 1);
		ShowSyncHudText(attacker, hudPlus2, "+%i", expBoost1);
	}
        return Plugin_Continue;
}
public Action:event_hurt(Handle:event, const String:name[], bool:dontBroadcast)
{
        if (GetConVarBool(rs_enable))
        {
                new client = GetClientOfUserId(GetEventInt(event, "userid"));
                new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
		new rawDamage = (GetEventInt(event, "damageamount"));
                if (!IsValidClient(attacker) || !IsValidClient(client) || client == attacker)
                {
                        return Plugin_Continue;
                }
		new Float:percent = GetConVarFloat(cvar_exp_ondmg);
		new Float:damage = (rawDamage * percent);
		new experience = RoundToNearest(damage);
		
		if (!(experience <= 0) && attacker > 0 && attacker <= MaxClients && IsClientInGame(attacker) && (attacker != client) && playerLevel[attacker] < GetConVarInt(cvar_level_max))
		{
			if(experience >= playerExpMax[attacker])
			{
				experience = playerExpMax[attacker];
			}
			playerExp[attacker] += experience;
			SetHudTextParams(0.24, 0.93, 1.0, 255, 100, 100, 150, 1);
			ShowSyncHudText(attacker, hudPlus1, "+%i", experience);
		}
	}
        return Plugin_Continue;
}
public Action:event_round_start(Handle:event, const String:name[], bool:dontBroadcast)
{
        if (GetConVarBool(rs_enable))
        {
                new search = -1;
                while ((search = FindEntityByClassname(search, "func_regenerate")) != -1)
                {
                        AcceptEntityInput(search, "Disable", -1, -1, 0);
                }
        }
        return Plugin_Continue;
}
/*public Action:Event_player_builtobject(Handle:event, const String:name[], bool:dontBroadcast)
{
        if (GetConVarBool(rs_enable))
        {
                new engie = GetClientOfUserId(GetEventInt(event, "userid"));
		new iTeam = GetClientTeam(engie);
		new index = -1;
		while ((index = FindEntityByClassname(index, "obj_sentrygun")) != -1)
		{
			new ammunition = GetEntProp(index, Prop_Send, "m_iAmmoShells", 0);
			if (ammunition > 0)
				SetEntProp(index, Prop_Send, "m_iAmmoShells", 0);

			SetEntProp(index, Prop_Send, "m_iHealth", 200);
			SetEntProp(index, Prop_Send, "m_iMaxHealth", 200);
			SetEntProp(index, Prop_Send, "m_iObjectType", _:TFObject_Sentry);
			SetEntProp(index, Prop_Send, "m_iState", 1);
				
			SetEntProp(index, Prop_Send, "m_iTeamNum", iTeam);
			SetEntProp(index, Prop_Send, "m_nSkin", iTeam-2);
			SetEntProp(index, Prop_Send, "m_iUpgradeLevel", 3);
			SetEntProp(index, Prop_Send, "m_iAmmoRockets", 300);
				
			SetEntPropEnt(index, Prop_Send, "m_hBuilder", engie);
				
			SetEntPropFloat(index, Prop_Send, "m_flPercentageConstructed", 1.0);
			SetEntProp(index, Prop_Send, "m_iHighestUpgradeLevel", 3);
			SetEntProp(index, Prop_Send, "m_bPlayerControlled", 1);
			SetEntProp(index, Prop_Send, "m_bHasSapper", 0);
		}
		while ((index = FindEntityByClassname(index, "obj_dispenser")) != -1)
		{
			SetEntProp(index, Prop_Send, "m_iAmmoMetal", 500);
			SetEntProp(index, Prop_Send, "m_iHealth", 200);
			SetEntProp(index, Prop_Send, "m_iMaxHealth", 200);
			SetEntProp(index, Prop_Send, "m_iObjectType", _:TFObject_Dispenser);
			SetEntProp(index, Prop_Send, "m_iTeamNum", iTeam);
			SetEntProp(index, Prop_Send, "m_nSkin", iTeam-2);
			SetEntProp(index, Prop_Send, "m_iHighestUpgradeLevel", 1);
			SetEntPropFloat(index, Prop_Send, "m_flPercentageConstructed", 1.0);
			SetEntPropEnt(index, Prop_Send, "m_hBuilder", engie);
		}
        }
        return Plugin_Continue;
}*/
public Action:Timer_PrayerRegen(Handle:hTimer, any:client) //prayer
{
	if (IsClientInGame(client) && !IsFakeClient(client) && !IsClientObserver(client) && IsValidClient(client))
	{
		if (!TF2_IsPlayerInCondition(client, TFCond_SmallBulletResist) || !TF2_IsPlayerInCondition(client, TFCond_SmallBlastResist) || !TF2_IsPlayerInCondition(client, TFCond_SmallFireResist) || !TF2_IsPlayerInCondition(client, TFCond_DefenseBuffed))
		{
			PrayerCharge[client] += GetConVarInt(PrayerChargeInt);
			if (PrayerCharge[client] > 100)
			{
				PrayerCharge[client] = 100;
			}
		}
	}
        return Plugin_Continue;
}
public Action:Command_ActivatePrayer(client) //activates prayer
{
	if (IsClientInGame(client) && !IsFakeClient(client) && !IsClientObserver(client) && IsPlayerAlive(client))
	{
		if (PrayerCond[client] != -1)
		{
			TF2_AddCondition(client, TFCond:PrayerCond[client], 0.3);
			PrayerCharge[client] -= 1;
		}
		else if (PrayerCond[client] == -1)
		{
			CPrintToChat(client, "{red}You do not have a Prayer set! type !rpg to set it");
			return Plugin_Handled;
		}
		if (PrayerCharge[client] <= 0)
		{
			Command_DeactivatePrayer(client);
			CPrintToChat(client, "{red}Your prayer charge is depleted!");
			return Plugin_Handled;
		}
	}
        return Plugin_Continue;
}
public Action:Command_DeactivatePrayer(client) //deactivates prayer obviously
{
	if (PrayerCond[client] != -1)
	{
		TF2_RemoveCondition(client, TFCond:PrayerCond[client]);
		if (PrayerCharge[client] <= 0)
		{
			PrayerCharge[client] = 0;
		}
	}
	return Plugin_Continue;
}
public Action:TraceAttack(victim, &attacker, &inflictor, &Float:damage, &damagetype, &ammotype, hitbox, hitgroup)
{
	if (IsPlayerAlive(attacker) && IsClientInGame(attacker) && IsValidClient(attacker) && IsPlayerAlive(victim) && IsClientInGame(victim) && IsValidClient(victim))
	{
		if (GetClientTeam(attacker) == GetClientTeam(victim))
		{
			if (TF2_GetPlayerClass(attacker) == TFClass_Engineer) //props to robin walker for engie armor fix code
			{
				new iCurrentMetal = GetEntProp(attacker, Prop_Data, "m_iAmmo", 4, 3);
				new repairamount = GetConVarInt(armor_from_metal);

				new hClientWeapon = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");
				decl String:classname[32];
				if (IsValidEdict(hClientWeapon)) GetEdictClassname(hClientWeapon, classname, sizeof(classname));
				
				if (StrEqual(classname, "tf_weapon_wrench", false) || StrEqual(classname, "tf_weapon_robot_arm", false))
				{
					if (armor[victim] >= 0 && armor[victim] < MaxArmor[victim])
					{
						if (iCurrentMetal < repairamount)
							repairamount = iCurrentMetal;

						if (MaxArmor[victim] - armor[victim] < repairamount)
							repairamount = MaxArmor[victim] - armor[victim];

						armor[victim] += repairamount;
						if (armor[victim] > MaxArmor[victim])
						{
							armor[victim] = MaxArmor[victim];
						}
						new iNewMetal = iCurrentMetal - repairamount;
						SetEntProp(attacker, Prop_Data, "m_iAmmo", iNewMetal, 4, 3);
					}
				}
			}
		}
		else
		{
			return Plugin_Continue;
		}
	}
	return Plugin_Continue;
}
public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3])
{
        if (attacker > 0 && victim != attacker)
        {
                if (damagetype & DMG_CRIT)
                {
                        damage /= 1.5;
                        return Plugin_Changed;
                }
		if (TF2_IsPlayerInCondition(victim, TFCond_SmallBulletResist) && weapon == GetPlayerWeaponSlot(attacker, TFWeaponSlot_Melee))
		{
			damage *= GetConVarFloat(cvar_prayer_melee_dmgreduce);
                        return Plugin_Changed;
		}
		else if (TF2_IsPlayerInCondition(victim, TFCond_SmallBlastResist) && TF2_GetPlayerClass(attacker) == TFClass_Sniper)
		{
			damage *= GetConVarFloat(cvar_prayer_ranged_dmgreduce);
                        return Plugin_Changed;
		}
		else if (TF2_IsPlayerInCondition(victim, TFCond_SmallFireResist) && TF2_GetPlayerClass(attacker) == TFClass_Medic)
		{
			damage *= GetConVarFloat(cvar_prayer_magic_dmgreduce);
                        return Plugin_Changed;
		}
		else if (TF2_IsPlayerInCondition(victim, TFCond_DefenseBuffed) && !(damagetype & DMG_CRIT))
		{
			damage *= 1.54;
                        return Plugin_Changed;
		}
		if (armor[victim] >= 1 && ArmorType[victim] != 0)
		{
			new Float:intdamage;
			intdamage = damage;

			if (ArmorType[victim] == 1)
			{
				if (TF2_GetPlayerClass(attacker) == TFClass_Sniper || weapon == GetPlayerWeaponSlot(attacker, TFWeaponSlot_Melee))
				{
					DamageResistance[victim] = GetConVarFloat(damage_resistance_ranged);
					intdamage *= DamageResistance[victim];
				}
				if (TF2_GetPlayerClass(attacker) == TFClass_Medic)
					intdamage *= GetConVarFloat(damage_vuln_magic);
			}
			else if (ArmorType[victim] == 2)
			{
				if (TF2_GetPlayerClass(attacker) == TFClass_Medic)
				{
					DamageResistance[victim] = GetConVarFloat(damage_resistance_magic);
					intdamage *= DamageResistance[victim];
				}
				if (weapon == GetPlayerWeaponSlot(attacker, TFWeaponSlot_Melee))
					intdamage *= GetConVarFloat(damage_vuln_melee);
			}
			else if (ArmorType[victim] == 3)
			{
				if (weapon == GetPlayerWeaponSlot(attacker, TFWeaponSlot_Melee))
				{
					DamageResistance[victim] = GetConVarFloat(damage_resistance_melee);
					intdamage *= DamageResistance[victim];
				}
				if (TF2_GetPlayerClass(attacker) == TFClass_Sniper)
				{
					intdamage *= GetConVarFloat(damage_vuln_ranged);
				}
			}

			if (GetConVarBool(allow_armor_damage))
			{
				armor[victim] -= RoundToCeil(intdamage);
				damage -= intdamage;
				if (armor[victim] < 1)
				{
					armor[victim] = 0;
				}
				return Plugin_Changed;
			}
			else if (!GetConVarBool(allow_armor_damage))
			{
				damage -= intdamage;
				return Plugin_Changed;
			}
		}
                /*decl Float:vec1[3];
                decl Float:vec2[3];
                GetEntPropVector(attacker, Prop_Send, "m_vecOrigin", vec1); //Spot of attacker
                GetEntPropVector(victim, Prop_Send, "m_vecOrigin", vec2); //Spot of victim
                new Float:dist = GetVectorDistance(vec1, vec2, false); //Calculates the distance between target and attacker*/
 
		//new String:classname[64];
		//if (IsValidEdict(weapon)) GetEdictClassname(weapon, classname, sizeof(classname));
 
/*range damage formula from runescape
ES is the effective strength
R = range level after potions if there are potions
P = prayer bonuses (e.g. hawk eye)
O = other bonuses, focus sight or full slayer helm
V = void bonuses (if ur using void range)
V = floor(R/5+1.6)
ES = floor(R*P*O)+V
RS = ranged strength (I replace this variable with damage)
Max Hit = 5+((ES+8)*(RS+64)/64)
 
melee damage formula from runescape
S = strength level (if your strenght is 95 and u used a potion and ur strength is 102, use S=102)
P = prayer bonuses (e.g. burst of strength)
O = other bonuses(void melee, black mask, salve amulet)
ES = func(S*P*O)
SB = strength bonus
Max Hit = 13+ES+(SB/8)+(ES*SB/64)
*/
        }
	return Plugin_Continue;
}
stock SpawnWeapon(client, String:name[], index, level, qual, String:att[])
{
        new Handle:hWeapon = TF2Items_CreateItem(OVERRIDE_ALL|FORCE_GENERATION);
        if (hWeapon == INVALID_HANDLE)
                return -1;
        TF2Items_SetClassname(hWeapon, name);
        TF2Items_SetItemIndex(hWeapon, index);
        TF2Items_SetLevel(hWeapon, level);
        TF2Items_SetQuality(hWeapon, qual);
        new String:atts[32][32];
        new count = ExplodeString(att, " ; ", atts, 32, 32);
        if (count > 0)
        {
                TF2Items_SetNumAttributes(hWeapon, count/2);
                new i2 = 0;
                for (new i = 0; i < count; i += 2)
                {
                        TF2Items_SetAttribute(hWeapon, i2, StringToInt(atts[i]), StringToFloat(atts[i+1]));
                        i2++;
                }
        }
        else
                TF2Items_SetNumAttributes(hWeapon, 0);
 
        new entity = TF2Items_GiveNamedItem(client, hWeapon);
        CloseHandle(hWeapon);
        EquipPlayerWeapon(client, entity);
        return entity;
}
stock SetSpell(client, spell, charge)
{
        new spellbook = FindSpellbook(client);
        if (spellbook != -1)    //Should probably have a message if no spellbook, but eh.
        {
                SetEntProp(spellbook, Prop_Send, "m_iSpellCharges", charge);
                if (GetEntProp(spellbook, Prop_Send, "m_iSelectedSpellIndex") < 0)
                {
                        SetEntProp(spellbook, Prop_Send, "m_iSelectedSpellIndex", spell);
                }
        }
        else if (spellbook == -1)
        {
                CPrintToChat(client, "{orange}[RPG Fortress] {default}Equip your Spellbook to use Magic!");
        }
}
public Action:RegenSpells(Handle:lTimer, any:client)
{
        if (!IsValidClient(client, false) || !IsClientInGame(client) || IsFakeClient(client))
        {
                return Plugin_Stop;
        }
        new spellbook = FindSpellbook(client);
	new Float:time = GetEngineTime();
        //Add 1 spell
        if (IsValidEntity(spellbook) && g_iSpell[client] < time)
        {
		new warlock = GetEntProp(spellbook, Prop_Send, "m_iSelectedSpellIndex");
		switch (warlock)
		{
			case 0: Cooldown[client] = GetConVarFloat(cvar_fireball_recharge);
			case 7: Cooldown[client] = GetConVarFloat(cvar_electric_recharge);
			case 1: Cooldown[client] = GetConVarFloat(cvar_hellfire_recharge);
			case 10: Cooldown[client] = GetConVarFloat(cvar_meteor_recharge);
		}
		g_iSpell[client] = time + Cooldown[client];
                SetEntProp(spellbook, Prop_Send, "m_iSpellCharges", GetEntProp(spellbook, Prop_Send, "m_iSpellCharges") + 1);
                if (GetEntProp(spellbook, Prop_Send, "m_iSpellCharges") > 1)
                {
                        SetEntProp(spellbook, Prop_Send, "m_iSpellCharges", 1);
                }
        }
        return Plugin_Continue;
}
stock bool:IsValidClient(client, bool:bReplay = true)
{
        if (client <= 0 || client > MaxClients)
                return false;
        if (!IsClientInGame(client))
                return false;
        if (bReplay && (IsClientSourceTV(client) || IsClientReplay(client)))
                return false;
        return true;
}
stock RemovePlayerBack(client, indices[], len) //props to Flamin' Sarge
{
	if (len <= 0) return;
	new edict = MaxClients+1;
	while ((edict = FindEntityByClassname2(edict, "tf_wearable")) != -1)
	{
		decl String:netclass[32];
		if (GetEntityNetClass(edict, netclass, sizeof(netclass)) && StrEqual(netclass, "CTFWearable"))
		{
			new idx = GetEntProp(edict, Prop_Send, "m_iItemDefinitionIndex");
			if (GetEntPropEnt(edict, Prop_Send, "m_hOwnerEntity") == client && !GetEntProp(edict, Prop_Send, "m_bDisguiseWearable"))
			{
				for (new i = 0; i < len; i++)
				{
					if (idx == indices[i]) AcceptEntityInput(edict, "Kill");
				}
			}
		}
	}
	edict = MaxClients+1;
	while ((edict = FindEntityByClassname2(edict, "tf_powerup_bottle")) != -1)
	{
		decl String:netclass[32];
		if (GetEntityNetClass(edict, netclass, sizeof(netclass)) && StrEqual(netclass, "CTFPowerupBottle"))
		{
			new idx = GetEntProp(edict, Prop_Send, "m_iItemDefinitionIndex");
			if (GetEntPropEnt(edict, Prop_Send, "m_hOwnerEntity") == client && !GetEntProp(edict, Prop_Send, "m_bDisguiseWearable"))
			{
				for (new i = 0; i < len; i++)
				{
					if (idx == indices[i]) AcceptEntityInput(edict, "Kill");
				}
			}
		}
	}
}
stock FindPlayerBack(client, indices[], len)
{
	if (len <= 0) return -1;
	new edict = MaxClients+1;
	while ((edict = FindEntityByClassname2(edict, "tf_wearable")) != -1)
	{
		decl String:netclass[32];
		if (GetEntityNetClass(edict, netclass, sizeof(netclass)) && StrEqual(netclass, "CTFWearable"))
		{
			new idx = GetEntProp(edict, Prop_Send, "m_iItemDefinitionIndex");
			if (GetEntPropEnt(edict, Prop_Send, "m_hOwnerEntity") == client && !GetEntProp(edict, Prop_Send, "m_bDisguiseWearable"))
			{
				for (new i = 0; i < len; i++)
				{
					if (idx == indices[i]) return edict;
				}
			}
		}
	}
	edict = MaxClients+1;
	while ((edict = FindEntityByClassname2(edict, "tf_powerup_bottle")) != -1)
	{
		decl String:netclass[32];
		if (GetEntityNetClass(edict, netclass, sizeof(netclass)) && StrEqual(netclass, "CTFPowerupBottle"))
		{
			new idx = GetEntProp(edict, Prop_Send, "m_iItemDefinitionIndex");
			if (GetEntPropEnt(edict, Prop_Send, "m_hOwnerEntity") == client && !GetEntProp(edict, Prop_Send, "m_bDisguiseWearable"))
			{
				for (new i = 0; i < len; i++)
				{
					if (idx == indices[i]) return edict;
				}
			}
		}
	}
	return -1;
}
stock SetAmmo(client, slot, ammo)
{
        new weapon = GetPlayerWeaponSlot(client, slot);
        if (IsValidEntity(weapon))
        {
                new iOffset = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType", 1)*4;
                new iAmmoTable = FindSendPropInfo("CTFPlayer", "m_iAmmo");
                SetEntData(client, iAmmoTable+iOffset, ammo, 4, true);
        }
}
stock TagsCheck(const String:tag[], bool:remove = false)        //DarthNinja
{
        new Handle:hTags = FindConVar("sv_tags");
        decl String:tags[255];
        GetConVarString(hTags, tags, sizeof(tags));
 
        if (StrContains(tags, tag, false) == -1 && !remove)
        {
                decl String:newTags[255];
                Format(newTags, sizeof(newTags), "%s,%s", tags, tag);
                ReplaceString(newTags, sizeof(newTags), ",,", ",", false);
                SetConVarString(hTags, newTags);
                GetConVarString(hTags, tags, sizeof(tags));
        }
        else if (StrContains(tags, tag, false) > -1 && remove)
        {
                ReplaceString(tags, sizeof(tags), tag, "", false);
                ReplaceString(tags, sizeof(tags), ",,", ",", false);
                SetConVarString(hTags, tags);
        }
//      CloseHandle(hTags);
}
stock FindEntityByClassname2(startEnt, const String:classname[])
{
	/* If startEnt isn't valid shifting it back to the nearest valid one */
	while (startEnt > -1 && !IsValidEntity(startEnt)) startEnt--;
	return FindEntityByClassname(startEnt, classname);
}
stock FindSpellbook(client)
{
        new i = -1;
        while ((i = FindEntityByClassname(i, "tf_weapon_spellbook")) != -1)
        {
                if (IsValidEntity(i) && GetEntPropEnt(i, Prop_Send, "m_hOwnerEntity") == client && !GetEntProp(i, Prop_Send, "m_bDisguiseWeapon"))
                {
                        return i;
                }
        }
        return -1;
}
stock ClearTimer(&Handle:Timer)
{
	if (Timer != INVALID_HANDLE)
	{
		CloseHandle(Timer);
		Timer = INVALID_HANDLE;
	}
}
stock LevelUp(client, level)
{
	playerLevel[client] = level;
	playerExp[client] -= playerExpMax[client];
	SetHudTextParams(0.22, 0.90, 5.0, 100, 255, 100, 150, 2);
	ShowSyncHudText(client, hudLevelUp, "LEVEL UP!");
	playerExpMax[client] += RoundToNearest(playerExpMax[client] * GetConVarFloat(cvar_exp_levelup));
	if (level == GetConVarInt(cvar_level_max))
	{
		playerExpMax[client] = 0;
	}
}
