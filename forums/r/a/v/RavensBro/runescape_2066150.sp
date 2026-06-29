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
Zephyrues for help
TAZ - for LOADS OF help lol
IF IT WEREN'T FOR THESE GUYS, THIS PLUGIN WOULDN'T EXIST.
*/

/*IDEAS
money system to buy certain weapons with certain damage, abilities, or otherwise with ammo amount
prayer with vaccinator thing.
*/
 
/*new MagicLevel[MAXPLAYERS+1];
new AttackLevel[MAXPLAYERS+1];
new StrengthLevel[MAXPLAYERS+1];
new DefenseLevel[MAXPLAYERS+1];
new RangedLevel[MAXPLAYERS+1];
new playerExp[MAXPLAYERS+1];
new playerExpMax[MAXPLAYERS+1];
new Handle:levelHUD[MAXPLAYERS+1] = INVALID_HANDLE;
new Handle:hudLevel;
new Handle:hudEXP;
new Handle:hudPlus1;
new Handle:hudPlus2;
new Handle:hudLevelUp;
new Handle:cvar_level_default;
new Handle:cvar_level_max;
new Handle:cvar_exp_default;
new Handle:cvar_exp_onkill;
new Handle:cvar_exp_ondmg;
new Handle:levelcookie;
new Handle:attackcookie;
new Handle:strengthcookie;
new Handle:defensecookie;
new Handle:magiccookie;
new Handle:rangedcookie;*/
#define PLUGIN_VERSION "1.7 BETA"
//#define MAX_SPELLS 4

enum Magic
{
	Fireball = 0,
	Bolt,
	Missile,
	Shower
};
/*
new bool:spellReady[MAXPLAYERS+1][MAX_SPELLS];*/
new Float:g_iSpell[MAXPLAYERS+1];

new Handle:rs_enable = INVALID_HANDLE;
new Handle:cvar_fireball_charges = INVALID_HANDLE;
new Handle:cvar_hellfire_charges = INVALID_HANDLE;
new Handle:cvar_electric_charges = INVALID_HANDLE;
new Handle:cvar_meteor_charges = INVALID_HANDLE;
//new Handle:fireball_regen[MAXPLAYERS+1] = INVALID_HANDLE;
//new Handle:hellfire_regen[MAXPLAYERS+1] = INVALID_HANDLE;
//new Handle:electric_regen[MAXPLAYERS+1] = INVALID_HANDLE;
//new Handle:meteor_regen[MAXPLAYERS+1] = INVALID_HANDLE;
new Handle:spellsregen[MAXPLAYERS+1] = INVALID_HANDLE;

#if defined _steamtools_included
new bool:steamtools = false;
#endif
new Handle:advert_timer = INVALID_HANDLE;
 
public Plugin:myinfo = {
        name = "Runescape Mod",
        author = "Assyrian/Nergal edit by RavensBro",
        description = "Runescape mod for Medieval Mode",
        version = PLUGIN_VERSION,
        url = "http://steamcommunity.com/groups/acvsh | http://forums.alliedmods.net/showthread.php?t=230178"
};
 
public OnPluginStart()
{
        RegConsoleCmd("sm_rs", RS_Menu, "Runescape menu");
        CreateConVar("rs_version", PLUGIN_VERSION, "Runescape Version", FCVAR_NOTIFY|FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_DONTRECORD);
        rs_enable = CreateConVar("rs_enabled", "1", "Enables Runescape mod", FCVAR_PLUGIN, true, 0.0, true, 1.0);
        cvar_fireball_charges = CreateConVar("rs_fireball_charges", "10.0", "Every x seconds, 1 fireball spell will be added", FCVAR_PLUGIN);
        cvar_hellfire_charges = CreateConVar("rs_hellfire_charges", "10.0", "Every x seconds, 1 hellfire spell will be added", FCVAR_PLUGIN);
        cvar_electric_charges = CreateConVar("rs_electric_charges", "10.0", "Every x seconds, 1 electrical bolt spell will be added", FCVAR_PLUGIN);
        cvar_meteor_charges = CreateConVar("rs_meteor_charges", "10.0", "Every x seconds, 1 metoer shower spell will be added", FCVAR_PLUGIN);
        advert_timer = CreateConVar("rs_advert_timer", "90.0", "amount of time the plugin advert will pop up");
        HookConVarChange(FindConVar("sv_tags"), cvarChange_Tags); //props to Flamin' Sarge
#if defined _steamtools_included
        steamtools = LibraryExists("SteamTools");
#endif
        /*cvar_level_default = CreateConVar("rs_level_default", "1", "Default level for players when they join");
        cvar_level_max = CreateConVar("rs_level_max", "99", "Maximum level players can reach and use to calculate damage");
        cvar_exp_default = CreateConVar("rs_exp_default", "83", "Default max experience for players when they join");
        cvar_exp_onkill = CreateConVar("rs_exp_onkill", "216", "Experience to gain on kill");
        cvar_exp_ondmg = CreateConVar("rs_exp_damage_mult", "1", "Experience multiplier for damage");
        RegAdminCmd("rs_setmylevel", Command_SetLevel, ADMFLAG_ROOT);
        levelcookie = RegClientCookie("rs_level_cookie", "stores players main levels", CookieAccess_Protected);
        attackcookie = RegClientCookie("rs_attack_level", "stores players attack levels", CookieAccess_Protected);
        strengthcookie = RegClientCookie("rs_strength_level", "stores players strength levels", CookieAccess_Protected);
        defensecookie = RegClientCookie("rs_defense_level", "stores players defense levels", CookieAccess_Protected);
        magiccookie = RegClientCookie("rs_magic_level", "stores players magic levels", CookieAccess_Protected);
        rangedcookie = RegClientCookie("rs_ranged_level", "stores players ranged levels", CookieAccess_Protected);*/
        AutoExecConfig(true, "runescape-mod");
       
        // = CreateConVar("", "0", "", FCVAR_PLUGIN, true, 0.0, true, 1.0);
        /*hudLevel = CreateHudSynchronizer();
        hudEXP = CreateHudSynchronizer();
        hudPlus1 = CreateHudSynchronizer();
        hudPlus2 = CreateHudSynchronizer();
        hudLevelUp = CreateHudSynchronizer();*/
        HookEvent("teamplay_round_start", event_round_start);
        HookEvent("player_spawn", event_player_spawn);
        HookEvent("player_death", event_player_death, EventHookMode_Pre);
        HookEvent("player_hurt", event_hurt, EventHookMode_Pre);
        HookEvent("player_changeclass", event_changeclass);
        for (new client = 0; client <= MaxClients; client++)
        {
                if (IsValidClient(client, false)) SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
        }
}
public OnClientDisconnect(client)
{
	//ClearTimer(fireball_regen[client]);
	//ClearTimer(hellfire_regen[client]);
	//ClearTimer(electric_regen[client]);
	//ClearTimer(meteor_regen[client]);
	ClearTimer(spellsregen[client]);
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
        CPrintToChatAll("{orange}[RuneScape] {default}type {green}!rs{default} to access menu");
}
public OnConfigsExecuted()
{
        if (GetConVarBool(rs_enable)) TagsCheck("runescape", true);
#if defined _steamtools_included
        if (steamtools)
        {
                decl String:gameDesc[64];
                Format(gameDesc, sizeof(gameDesc), "Runescape Fortress (%s)", PLUGIN_VERSION);
                Steam_SetGameDescription(gameDesc);
        }
#endif
}
public cvarChange_Tags(Handle:convar, const String:oldValue[], const String:newValue[])
{
        if (GetConVarBool(rs_enable)) TagsCheck("runescape", false);
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
		//SDKHook(client, SDKHook_FireBulletsPost, FireSpellHook);
                /*MagicLevel[client] = GetConVarInt(cvar_level_default);
                AttackLevel[client] = GetConVarInt(cvar_level_default);
                StrengthLevel[client] = GetConVarInt(cvar_level_default);
                DefenseLevel[client] = GetConVarInt(cvar_level_default);
                RangedLevel[client] = GetConVarInt(cvar_level_default);
                levelHUD[client]= CreateTimer(0.5, DrawHud, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
                playerExp[client] = 0;
                playerExpMax[client] = GetConVarInt(cvar_exp_default);
                Format(MagicLevel[client], sizeof(MagicLevel[]), "");
                Format(AttackLevel[client], sizeof(AttackLevel[]), "");
                Format(StrengthLevel[client], sizeof(StrengthLevel[]), "");
                Format(DefenseLevel[client], sizeof(DefenseLevel[]), "");
                Format(RangedLevel[client], sizeof(RangedLevel[]), "");
                GetClientCookie(client, magiccookie, MagicLevel[client], sizeof(MagicLevel[]));
                GetClientCookie(client, attackcookie, AttackLevel[client], sizeof(AttackLevel[]));
                GetClientCookie(client, strengthcookie, StrengthLevel[client], sizeof(StrengthLevel[]));
                GetClientCookie(client, defensecookie, DefenseLevel[client], sizeof(DefenseLevel[]));
                GetClientCookie(client, rangedcookie, RangedLevel[client], sizeof(RangedLevel[]));*/
        }
}
/*public Action:DrawHud(Handle:timer, any:client)
{
        if (IsClientInGame(client))
        {
                if (TF2_GetPlayerClass(client) == TFClass_Sniper)
                {
                        if (playerExp[client] >= playerExpMax[client] && RangedLevel[client] < GetConVarInt(cvar_level_max))
                        {
                                LevelUp(client, RangedLevel[client] + 1);
                        }
                        SetHudTextParams(0.14, 0.90, 2.0, 100, 200, 255, 150);
                        ShowSyncHudText(client, hudLevel, "Ranged Level: %i", RangedLevel[client]);
                        SetHudTextParams(0.14, 0.95, 2.0, 255, 200, 100, 150);
                        if (RangedLevel[client] >= GetConVarInt(cvar_level_max))
                        {
                                ShowSyncHudText(client, hudEXP, "MAX LEVEL REACHED", playerExp[client], playerExpMax[client]);
                        }
                        else
                        {
                                ShowSyncHudText(client, hudEXP, "EXP: %i/%i", playerExp[client], playerExpMax[client]);
                        }
                }
                if (TF2_GetPlayerClass(client) == TFClass_Soldier)
                {
                        if (playerExp[client] >= playerExpMax[client] && AttackLevel[client] < GetConVarInt(cvar_level_max))
                        {
                                LevelUp(client, AttackLevel[client] + 1);
                        }
                        if (playerExp[client] >= playerExpMax[client] && StrengthLevel[client] < GetConVarInt(cvar_level_max))
                        {
                                LevelUp(client, StrengthLevel[client] + 1);
                        }
                        if (playerExp[client] >= playerExpMax[client] && DefenseLevel[client] < GetConVarInt(cvar_level_max))
                        {
                                LevelUp(client, DefenseLevel[client] + 1);
                        }
                        SetHudTextParams(0.14, 0.90, 2.0, 100, 200, 255, 150);
                        ShowSyncHudText(client, hudLevel, "Attack Level: %i", AttackLevel[client]);
                        SetHudTextParams(0.14, 0.100, 2.0, 255, 90, 30, 150);
                        ShowSyncHudText(client, hudLevel, "Strength Level: %i", StrengthLevel[client]);
                        SetHudTextParams(0.14, 0.110, 2.0, 150, 100, 150, 150);
                        ShowSyncHudText(client, hudLevel, "Defense Level: %i", DefenseLevel[client]);
 
                        SetHudTextParams(0.14, 0.93, 2.0, 255, 200, 100, 150);
                        if (AttackLevel[client] >= GetConVarInt(cvar_level_max) || StrengthLevel[client] >= GetConVarInt(cvar_level_max) || DefenseLevel[client] >= GetConVarInt(cvar_level_max))
                        {
                                ShowSyncHudText(client, hudEXP, "MAX LEVEL REACHED", playerExp[client], playerExpMax[client]);
                        }
                        else
                        {
                                ShowSyncHudText(client, hudEXP, "EXP: %i/%i", playerExp[client], playerExpMax[client]);
                        }
                }
                if (TF2_GetPlayerClass(client) == TFClass_Medic)
                {
                        if (playerExp[client] >= playerExpMax[client] && MagicLevel[client] < GetConVarInt(cvar_level_max))
                        {
                                LevelUp(client, MagicLevel[client] + 1);
                        }
                        SetHudTextParams(0.14, 0.90, 2.0, 100, 200, 255, 150);
                        ShowSyncHudText(client, hudLevel, "Magic Level: %i", MagicLevel[client]);
                        SetHudTextParams(0.14, 0.93, 2.0, 255, 200, 100, 150);
                        if (MagicLevel[client] >= GetConVarInt(cvar_level_max))
                        {
                                ShowSyncHudText(client, hudEXP, "MAX LEVEL REACHED", playerExp[client], playerExpMax[client]);
                        }
                        else
                        {
                                ShowSyncHudText(client, hudEXP, "EXP: %i/%i", playerExp[client], playerExpMax[client]);
                        }
                }
        }
        return Plugin_Continue;
}*/
/*public Action:Equipment(Handle:hTimer, any:clientid)
{
        new client = GetClientOfUserId(clientid);
        if (!IsValidClient(client) || !IsPlayerAlive(client))
                return Plugin_Continue;
        new weapon = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
        new index = -1;
        if (weapon > MaxClients && IsValidEdict(weapon))
        {
                index = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
                switch (index)
                {
                }
        }
        weapon = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
        if (weapon > MaxClients && IsValidEdict(weapon))
        {
                index = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
                switch (index)
                {
                }
        }
        weapon = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);
        if (weapon > MaxClients && IsValidEdict(weapon))
        {
                index = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
                switch (index)
                {
                }
        }
        return Plugin_Continue;
}*/
public Action:RS_Menu(client, args)
{
        if (client && IsClientInGame(client) && !IsFakeClient(client) && (GetClientTeam(client) != 1 || GetClientTeam(client) != 0))
        {
                new Handle:MainMenu = CreateMenu(MenuHandler_RS1);
 
                SetMenuTitle(MainMenu, "Main Menu - Choose Category:");
                AddMenuItem(MainMenu, "pick_weapon", "Pick Your Weapon");
               
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
        }
        else if (action == MenuAction_End)
        {
                CloseHandle(menu);
        }
}
public Action:MenuChooseWeapon(client, args)
{
        if (client && IsClientInGame(client) && !IsFakeClient(client) && (GetClientTeam(client) != 1 || GetClientTeam(client) != 0) && IsValidClient(client) && IsPlayerAlive(client))
        {
                if (TF2_GetPlayerClass(client) == TFClass_Sniper)
                {
                        new Handle:rangeSelect = CreateMenu(MenuHandler_GiveRangeWep);
                        SetMenuTitle(rangeSelect, "Pick Your Archer Weapon:");
                        AddMenuItem(rangeSelect, "huntsman", "Huntsman");
                        AddMenuItem(rangeSelect, "cleaver", "Cleaver");
                        AddMenuItem(rangeSelect, "crossbow", "Crossbow");
                        AddMenuItem(rangeSelect, "cannon", "Cannon");
                        SetMenuExitBackButton(rangeSelect, true);
                        DisplayMenu(rangeSelect, client, MENU_TIME_FOREVER);
                }
                if (TF2_GetPlayerClass(client) == TFClass_Soldier)
                {
                        new Handle:meleemenuSelect = CreateMenu(MenuHandler_GiveMeleeWep);    
                        SetMenuTitle(meleemenuSelect, "Pick Your Melee Weapon:");
                        AddMenuItem(meleemenuSelect, "bbasher", "Boston Basher: +20% firing speed, 3+ hp regen");
                        AddMenuItem(meleemenuSelect, "pan", "Frying Pan: -20% damage penalty, +50% fire rate");
                        AddMenuItem(meleemenuSelect, "3rune", "Three-Rune Blade: +25% damage bonus");
                        AddMenuItem(meleemenuSelect, "ham", "Ham Shank (Pan Reskin): -20% damage penalty, +60% fire rate");
                        AddMenuItem(meleemenuSelect, "equalizer", "The Equalizer: deal more damage as your health lowers");
                        AddMenuItem(meleemenuSelect, "katana", "Half-Katana: On Hit: +40 hp");
                        AddMenuItem(meleemenuSelect, "maul", "Obsidian Maul: +100% damage bonus, 70% slower fire rate");
                        AddMenuItem(meleemenuSelect, "scimmy", "Scimitar: +30% fire rate");
                        AddMenuItem(meleemenuSelect, "axting", "Axtinguisher: On Hit: Ignite enemy");
                        SetMenuExitBackButton(meleemenuSelect, true);
                        DisplayMenu(meleemenuSelect, client, MENU_TIME_FOREVER);
                }
                if (TF2_GetPlayerClass(client) == TFClass_Medic)
                {
                        new Handle:magicSelect = CreateMenu(MenuHandler_GiveMageWep);
                        SetMenuTitle(magicSelect, "Pick Your Magic Spell:");
                        AddMenuItem(magicSelect, "banner", "Fireballs");
                        AddMenuItem(magicSelect, "shrtcrcuit", "Electric Bolts");
                        AddMenuItem(magicSelect, "backup", "Hellfire Missiles");
                        AddMenuItem(magicSelect, "backup", "Meteor Shower");
                        SetMenuExitBackButton(magicSelect, true);
                        DisplayMenu(magicSelect, client, MENU_TIME_FOREVER);
                }
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
                if (param2 == 2)
                {
                        new weapon;
                        weapon = SpawnWeapon(client, "tf_weapon_cleaver", 812, 100, 5, "6 ; 0.75");
                        SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", weapon);
                        SetAmmo(client, 1, 100);
                }
                if (param2 == 3)
                {
                        SpawnWeapon(client, "tf_weapon_crossbow", 305, 100, 5, "2 ; 2.0");
                        SetAmmo(client, 0, 100);
                }
                if (param2 == 4)
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
                if (param2 == 2)
                {
                        SpawnWeapon(client, "tf_weapon_shovel", 264, 100, 5, "1 ; 0.8 ; 6 ; 0.50");//pan
                }
                if (param2 == 3)
                {
                        SpawnWeapon(client, "tf_weapon_shovel", 452, 100, 5, "2 ; 1.25");//3-rune blade
                }
                if (param2 == 4)
                {
                        SpawnWeapon(client, "tf_weapon_shovel", 1013, 100, 5, "1 ; 0.8 ; 6 ; 0.50");//ham
                }
                if (param2 == 5)
                {
                        SpawnWeapon(client, "tf_weapon_shovel", 128, 100, 5, "115 ; 1.0");//equalizer
                }
                if (param2 == 6)
                {
                        SpawnWeapon(client, "tf_weapon_shovel", 357, 100, 5, "16 ; 40");//katana
                }
                if (param2 == 7)
                {
                        SpawnWeapon(client, "tf_weapon_shovel", 466, 100, 5, "2 ; 2.25 ; 5 ; 1.60");//maul
                }
                if (param2 == 8)
                {
                        SpawnWeapon(client, "tf_weapon_shovel", 404, 100, 5, "6 ; 0.70");//persian persuader
                }
                if (param2 == 9)
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
                param2++;
                if (param2 == 1)
                {
			SpawnWeapon(client, "tf_weapon_buff_item", 129, 100, 5, "2 ; 1.0");
			SpawnWeapon(client, "tf_weapon_spellbook", 1070, 0, 0, "2 ; 1.0");
			SetSpell(client, 0, 0);
			//g_iSpell[client] = (param2 - 1);
                }
                if (param2 == 2)
                {
                        SpawnWeapon(client, "tf_weapon_mechanical_arm", 528, 100, 5, "2 ; 1.0");
                        SpawnWeapon(client, "tf_weapon_spellbook", 1070, 0, 0, "2 ; 1.0");
                        SetSpell(client, 7, 0);
			//g_iSpell[client] = (param2 - 2);
                }
                if (param2 == 3)
                {
                        SpawnWeapon(client, "tf_weapon_buff_item", 226, 100, 5, "2 ; 1.0");
                        SpawnWeapon(client, "tf_weapon_spellbook", 1070, 0, 0, "2 ; 1.0");
                        SetSpell(client, 1, 0);
			//g_iSpell[client] = (param2 - 3);
                }
                if (param2 == 4)
                {
                        SpawnWeapon(client, "tf_weapon_buff_item", 226, 100, 5, "2 ; 1.0");
                        SpawnWeapon(client, "tf_weapon_spellbook", 1070, 0, 0, "2 ; 1.0");
                        SetSpell(client, 10, 0);
			//g_iSpell[client] = (param2 - 4);
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
		return Plugin_Handled;
        }
        new Float:speed = 3.5*100.5;
        SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", speed);
        if (TF2_IsPlayerInCondition(client, TFCond_Bleeding))
        {
                TF2_RemoveCondition(client, TFCond_Bleeding);
        }
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
                        case TFClass_Scout, TFClass_Engineer, TFClass_Pyro, TFClass_Spy, TFClass_Heavy, TFClass_DemoMan:
                        {
                                new randomclass = GetRandomInt(0, 2);
                                switch (randomclass)
                                {
                                        case 0: TF2_SetPlayerClass(client, TFClass_Soldier, _, false);
                                        case 1: TF2_SetPlayerClass(client, TFClass_Medic, _, false);
                                        case 2: TF2_SetPlayerClass(client, TFClass_Sniper, _, false);
                                }
                        }
                        case TFClass_Soldier:   TF2_SetPlayerClass(client, TFClass_Soldier, _, false);
                        case TFClass_Medic:     TF2_SetPlayerClass(client, TFClass_Medic, _, false);
                        case TFClass_Sniper:    TF2_SetPlayerClass(client, TFClass_Sniper, _, false);
                }
                TF2_RemoveAllWeapons(client);
                CreateTimer(0.2, PlayerTimer, client, TIMER_REPEAT);
                //CreateTimer(0.5, DrawHud, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
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
                        case TFClass_Scout, TFClass_Engineer, TFClass_Pyro, TFClass_Spy, TFClass_Heavy, TFClass_DemoMan:                               
								if (TF2_GetPlayerClass(client) != TFClass_Soldier)
                                        TF2_SetPlayerClass(client, TFClass_Soldier, _, false);
                        case TFClass_Sniper:
                                if (TF2_GetPlayerClass(client) != TFClass_Sniper)
                                        TF2_SetPlayerClass(client, TFClass_Sniper, _, false);
                        case TFClass_Medic:
                                if (TF2_GetPlayerClass(client) != TFClass_Medic)
                                        TF2_SetPlayerClass(client, TFClass_Medic, _, false);
                }
                TF2_RemovePlayerDisguise(client);      
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
                /*if (TF2_GetPlayerClass(attacker) == TFClass_Sniper)
                {
                        if ((attacker > 0) && (attacker <= MaxClients) && (attacker != client) && (GetConVarInt(cvar_exp_onkill) >= 1) &&       (RangedLevel[attacker] < GetConVarInt(cvar_level_max)) && (IsClientInGame(attacker)))
                        {
                                new expBoost1 = GetConVarInt(cvar_exp_onkill);
                                playerExp[attacker] = expBoost1;
                                SetHudTextParams(0.28, 0.93, 1.0, 255, 100, 100, 150, 1);
                                ShowSyncHudText(attacker, hudPlus2, "+%i", expBoost1);
                        }
                }
                if (TF2_GetPlayerClass(attacker) == TFClass_Soldier)
                {
                        if ((attacker > 0) && (attacker <= MaxClients) && (attacker != client) && (GetConVarInt(cvar_exp_onkill) >= 1) &&       (StrengthLevel[attacker] < GetConVarInt(cvar_level_max)) && (IsClientInGame(attacker)))
                        {
                                new expBoost1 = GetConVarInt(cvar_exp_onkill);
                                playerExp[attacker] = expBoost1;
                                SetHudTextParams(0.28, 0.93, 1.0, 255, 100, 100, 150, 1);
                                ShowSyncHudText(attacker, hudPlus2, "+%i", expBoost1);
                        }
                }
                if (TF2_GetPlayerClass(attacker) == TFClass_Medic)
                {
                        if ((attacker > 0) && (attacker <= MaxClients) && (attacker != client) && (GetConVarInt(cvar_exp_onkill) >= 1) &&       (MagicLevel[attacker] < GetConVarInt(cvar_level_max)) && (IsClientInGame(attacker)))
                        {
				new expBoost1 = GetConVarInt(cvar_exp_onkill);
				playerExp[attacker] = expBoost1;
				SetHudTextParams(0.28, 0.93, 1.0, 255, 100, 100, 150, 1);
				ShowSyncHudText(attacker, hudPlus2, "+%i", expBoost1);
                        }
                }*/
        return Plugin_Continue;
}
public Action:event_hurt(Handle:event, const String:name[], bool:dontBroadcast)
{
    if (GetConVarBool(rs_enable))
    {
        new client = GetClientOfUserId(GetEventInt(event, "userid"));
        new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
        if (!IsValidClient(attacker) || !IsValidClient(client) || client == attacker)
        {
            return Plugin_Continue;
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
/*public FireSpellHook(client, shots, const String:weaponname[])
{
	if (StrContains(weaponname, "spellbook"))
	{
		spellReady[client][g_iSpell[client]] = false;
		switch (g_iSpell[client])
		{
			case 0: CreateTimer(GetConVarFloat(cvar_fireball_charges), RegenSpell, client);
			case 1: CreateTimer(GetConVarFloat(cvar_electric_charges), RegenSpell, client);
			case 2: CreateTimer(GetConVarFloat(cvar_hellfire_charges), RegenSpell, client);
			case 3: CreateTimer(GetConVarFloat(cvar_meteor_charges), RegenSpell, client);
		}
	}
}*/
/*public Action:RegenSpell(Handle:timer, any:client)
{
	if (!IsValidClient(client, false) || !IsClientInGame(client) || IsFakeClient(client) || !IsPlayerAlive(client))
        {
		return Plugin_Stop;
        }
	spellReady[client][g_iSpell[client]] = true;
        return Plugin_Continue;
}*/
public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3])
{
        if (attacker > 0 && victim != attacker)
        {
                if (damagetype & DMG_CRIT)
                {
                        damage /= 1.5;
                        return Plugin_Changed;
                }
                /*decl Float:vec1[3];
                decl Float:vec2[3];
                GetEntPropVector(attacker, Prop_Send, "m_vecOrigin", vec1); //Spot of attacker
                GetEntPropVector(victim, Prop_Send, "m_vecOrigin", vec2); //Spot of victim
                new Float:dist = GetVectorDistance(vec1, vec2, false); //Calculates the distance between target and attacker*/
 
		new String:classname[64];
		if (IsValidEdict(weapon)) GetEdictClassname(weapon, classname, sizeof(classname));
		if (strcmp(classname, "spellbook_meteor", false) == 0)
		{
			damage *= 0.3;
		}
                /*new rangelevel = RangedLevel[attacker];
                new attacklevel = AttackLevel[attacker];
                new resistance = DefenseLevel[victim];
                new strength = StrengthLevel[attacker];
                new magicks = MagicLevel[attacker];
               
                if (strcmp(classname, "tf_weapon_cannon", false) == 0 || strcmp(classname, "tf_weapon_shotgun_building_rescue", false) == 0 || strcmp(classname, "tf_weapon_compound_bow", false) == 0 || strcmp(classname, "tf_weapon_crossbow", false) == 0 || strcmp(classname, "tf_weapon_cleaver", false) == 0)
                {
                        new Float:totalrange = (rangelevel/5+1.6);
                        new Float:totaldamage = 5+(totalrange+8)*(damage+64)/16.0;
                        damage = totaldamage/resistance;
                        return Plugin_Changed;
                }
                if (weapon == GetPlayerWeaponSlot(attacker, TFWeaponSlot_Melee) && IsValidEdict(weapon))
                {
                        //divide the attacker's attack level with victims defense level to determine hit accuracy which will be multiplied with the total damage
                        new Float:DamageHit = 13+(strength/damage)+(strength*damage/16);
                        damage = (DamageHit*GetRandomFloat(0.5, 1.5));
                        if (damage < 20)
                                damage = 20.0;
                        return Plugin_Changed;
                }
                if (TF2_GetPlayerClass(attacker) == TFClass_Medic)
                {
                        damage += magicks;
                }*/
 
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
stock SetSpell(client, spell, uses)
{
	new ent = GetSpellBook(client);
	if(!IsValidEntity(ent)) return -1;
	{
        if (GetEntProp(ent, Prop_Send, "m_iSelectedSpellIndex", spell) == -1)
        SetEntProp(ent, Prop_Send, "m_iSelectedSpellIndex", spell);		
        if (GetEntProp(ent, Prop_Send, "m_iSpellCharges", uses) < 0)
        SetEntProp(ent, Prop_Send, "m_iSpellCharges", uses);
        
		else
	    
		{
            CPrintToChat(client, "{orange}[RuneScape] {default}Equip your Spellbook to use Magic!");
        }
	}
	return 0;	
}
public Action:RegenSpells(Handle:lTimer, any:client)
{
        if (!IsValidClient(client, false) || !IsClientInGame(client) || IsFakeClient(client))
        {
                return Plugin_Stop;
        }
        new spellbook = GetSpellBook(client);
	new Float:time = GetEngineTime();
	new Float:Cooldown[MAXPLAYERS+1];
        //Add 1 spell
        if (IsValidEntity(spellbook) && g_iSpell[client] < time)
        {
		new warlock = GetEntProp(spellbook, Prop_Send, "m_iSelectedSpellIndex");
		switch (warlock)
		{
			case 0: Cooldown[client] = GetConVarFloat(cvar_fireball_charges);
			case 7: Cooldown[client] = GetConVarFloat(cvar_electric_charges);
			case 1: Cooldown[client] = GetConVarFloat(cvar_hellfire_charges);
			case 10: Cooldown[client] = GetConVarFloat(cvar_meteor_charges);
		}
		g_iSpell[client] = (time + Cooldown[client]);
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
 
stock GetSpellBook(client)
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
	if(Timer != INVALID_HANDLE)
	{
		CloseHandle(Timer);
		Timer = INVALID_HANDLE;
	}
}
/*
public Action:Command_SetLevel(client, args)
{
        new String:arg1[64];
        GetCmdArg(1, arg1, sizeof(arg1));
        new newLevel = StringToInt(arg1);
        LevelUp(client, newLevel);
        return Plugin_Handled;
}*/
/*stock LevelUp(client, level)
{
        MagicLevel[client] = level;
        AttackLevel[client] = level;
        StrengthLevel[client] = level;
        DefenseLevel[client] = level;
        RangedLevel[client] = level;
        playerExp[client] -= playerExpMax[client];
        SetHudTextParams(0.22, 0.90, 5.0, 100, 255, 100, 150, 2);
        ShowSyncHudText(client, hudLevelUp, "LEVEL UP!");
        playerExpMax[client] += RoundFloat((playerExpMax[client]*1.05));
        if (level == GetConVarInt(cvar_level_max))
        {
                playerExpMax[client] = 0;
        }
}*/
/*
ShootProjectile(client, spell) //props to mitch
{
        new Float:vAngles[3]; // original
        new Float:vPosition[3]; // original
        GetClientEyeAngles(client, vAngles);
        GetClientEyePosition(client, vPosition);
        new String:strEntname[45] = "";
        switch(spell)
        {
                case FIREBALL:          strEntname = "tf_projectile_spellfireball";
                case LIGHTNING:         strEntname = "tf_projectile_lightningorb";
                case PUMPKIN:           strEntname = "tf_projectile_spellmirv";
                case PUMPKIN2:          strEntname = "tf_projectile_spellpumpkin";
                case BATS:                      strEntname = "tf_projectile_spellbats";
                case METEOR:            strEntname = "tf_projectile_spellmeteorshower";
                case TELE:                      strEntname = "tf_projectile_spelltransposeteleport";
                case ZOMBIEH:           strEntname = "tf_projectile_spellspawnhorde";
        }
        new iTeam = GetClientTeam(client);
        new iSpell = CreateEntityByName(strEntname);
       
        if(!IsValidEntity(iSpell))
                return -1;
       
        decl Float:vVelocity[3];
        decl Float:vBuffer[3];
       
        GetAngleVectors(vAngles, vBuffer, NULL_VECTOR, NULL_VECTOR);
       
        vVelocity[0] = vBuffer[0]*1100.0; //Speed of a tf2 rocket.
        vVelocity[1] = vBuffer[1]*1100.0;
        vVelocity[2] = vBuffer[2]*1100.0;
       
        SetEntPropEnt(iSpell, Prop_Send, "m_hOwnerEntity", client);
        SetEntProp(iSpell,    Prop_Send, "m_bCritical", (GetRandomInt(0, 100) <= 5)? 1 : 0, 1);
        SetEntProp(iSpell,    Prop_Send, "m_iTeamNum",     iTeam, 1);
        SetEntProp(iSpell,    Prop_Send, "m_nSkin", (iTeam-2));
       
        TeleportEntity(iSpell, vPosition, vAngles, NULL_VECTOR);
        switch(spell)
        {
                //These spells have arcs.
                case BATS, METEOR, TELE:
                {
                        vVelocity[2] += 32.0;
                }
        }//
        TeleportEntity(iSpell, NULL_VECTOR, NULL_VECTOR, vVelocity);
       
        return iSpell;
}*/
