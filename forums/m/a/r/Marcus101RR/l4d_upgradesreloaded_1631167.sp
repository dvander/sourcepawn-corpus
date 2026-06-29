#pragma semicolon 1
/**
 * \x01 - Default
 * \x02 - Team Color
 * \x03 - Light Green
 * \x04 - Orange
 * \x05 - Olive
 * \x06
 */

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define PLUGIN_VERSION		"1.7.2"
#define UPGRADEID		45
#define MAX_UPGRADES		45
#define AWARDID			128
#define CVAR_FLAGS		FCVAR_PLUGIN|FCVAR_NOTIFY
#define UPGRADE_LOAD_TIME	0.5

#define	HUNTING_RIFLE_OFFSET_AMMO	8
#define	RIFLE_OFFSET_AMMO		12
#define	SMG_OFFSET_AMMO			20
#define	SHOTGUN_OFFSET_AMMO		24

#define ENTITY_GASCAN	"models/props_junk/gascan001a.mdl"
#define ENTITY_PROPANE	"models/props_junk/propanecanister001a.mdl"

public Plugin:myinfo =
{
    name = "[L4D] Survivor Upgrades Reloaded",
    author = "Marcus101RR, Whosat & Jerrith",
    description = "Survivor Upgrades Returns, Reloaded!",
    version = PLUGIN_VERSION,
    url = "http://forums.alliedmods.net"
}

new Handle:UpgradeEnabled[MAX_UPGRADES] = { INVALID_HANDLE, ... };
new Handle:AwardIndex[AWARDID + 1] = { INVALID_HANDLE, ... };
new Handle:MorphogenicTimer[MAXPLAYERS + 1] = INVALID_HANDLE;
new Handle:RegenerationTimer[MAXPLAYERS + 1] = INVALID_HANDLE;
new Handle:AwardsCooldownTimer[MAXPLAYERS + 1] = INVALID_HANDLE;
new Handle:CasingDispenserTimer[MAXPLAYERS + 1] = INVALID_HANDLE;
new Handle:SetClientUpgrades[MAXPLAYERS + 1] = INVALID_HANDLE;
new Handle:g_PerkMode = INVALID_HANDLE;
new Handle:PerkSlots = INVALID_HANDLE;
new Handle:PerkBonusSlots = INVALID_HANDLE;
new Handle:hDatabase;

new UpgradeIndex[MAX_UPGRADES];
new String:UpgradeTitle[MAX_UPGRADES][256];
new String:UpgradeShort[MAX_UPGRADES][256];
new String:AwardTitle[AWARDID + 1][256];
new iBitsUpgrades[MAXPLAYERS + 1];
new iUpgrade[MAXPLAYERS + 1][UPGRADEID + 1];
new iUpgradeDisabled[MAXPLAYERS + 1][UPGRADEID + 1];
new iCount[MAXPLAYERS + 1][AWARDID + 1];
new AwardsCooldownID[MAXPLAYERS + 1];
new iPerkBonusSlots[MAXPLAYERS + 1] = 0;

new bool:b_round_end;
new bool:IsDatabaseLoaded = false;
new RefreshRewards[MAXPLAYERS + 1] = 0;
new iAnnounceText[MAXPLAYERS + 1] = 0;
new iSaveFeature[MAXPLAYERS + 1] = 0;
new String:PerkTitle[MAX_UPGRADES][256];

// Single CVAR Variables
new Handle:penalty_upgrades;
new Float:FirstAidDuration;
new Float:PipeBombDuration;
new iLargePainPills[MAXPLAYERS + 1];
new iLargeFirstAidKit[MAXPLAYERS + 1];
new iGrenadePouch[MAXPLAYERS + 1];
new iLastStand[MAXPLAYERS + 1];
new String:g_msgType[64];

new iCountTimer[MAXPLAYERS + 1];
static g_iSelectedClient;

public OnPluginStart()
{
	decl String:game_name[64];
	GetGameFolderName(game_name, sizeof(game_name));
	if (!StrEqual(game_name, "left4dead", false))
	{
		SetFailState("Plugin Supports Left 4 Dead Only.");
	}

	CreateConVar("sm_upgradesreloaded_version", PLUGIN_VERSION, "Survivor Upgrades Reloaded Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	penalty_upgrades = CreateConVar("survivor_upgrade_awards_death_amount", "2", "Number of Upgrades Lost per Death", CVAR_FLAGS, true, 1.0, true, 10.0);
	g_PerkMode = CreateConVar("survivor_upgrade_perk_mode", "0", "Option for Perk style gameplay", CVAR_FLAGS, true, 0.0, true, 1.0);
	PerkSlots = CreateConVar("survivor_upgrade_perk_slots", "4", "The number of perks allowed in the game.", CVAR_FLAGS, true, 0.0, true, 6.0);
	PerkBonusSlots = CreateConVar("survivor_upgrade_perk_bonus_slots", "2", "The number of bonus perks obtainable in the game.", CVAR_FLAGS, true, 0.0, true, 6.0);
	
	AwardIndex[0] = CreateConVar("survivor_upgrade_awards_death", "3", "Lose All Upgrades (0 - Disable, 1 - Bots Only, 2 - Humans Only, 3 - All Players", CVAR_FLAGS, true, 0.0, true, 10.0);
	AwardTitle[0] = "\x05Death Penalty\x01";
	AwardIndex[14] = CreateConVar("survivor_upgrade_awards_blind_luck", "1", "Number of Blind Luck Awards To Earn Upgrade", CVAR_FLAGS, true, 0.0, true, 10.0);
	AwardTitle[14] = "\x05Blind Luck Award\x01";
	AwardIndex[15] = CreateConVar("survivor_upgrade_awards_pyrotechnician", "2", "Number of Pyrotechnician Awards To Earn Upgrade", CVAR_FLAGS, true, 0.0, true, 10.0);
	AwardTitle[15] = "\x05Pyrotechnician Award\x01";
	AwardIndex[18] = CreateConVar("survivor_upgrade_awards_witch_hunter", "1", "Number of Witch Hunter Awards To Earn Upgrade", CVAR_FLAGS, true, 0.0, true, 10.0);
	AwardTitle[18] = "\x05Witch Hunter Award\x01";
	AwardIndex[19] = CreateConVar("survivor_upgrade_awards_crowned", "1", "Number of Crowned Awards To Earn Upgrade", CVAR_FLAGS, true, 0.0, true, 10.0);
	AwardTitle[19] = "\x05Crowned Award\x01";
	AwardIndex[21] = CreateConVar("survivor_upgrade_awards_dead_stop", "1", "Number of Dead Stop Awards To Earn Upgrade", CVAR_FLAGS, true, 0.0, true, 10.0);
	AwardTitle[21] = "\x05Dead Stop Award\x01";
	AwardIndex[26] = CreateConVar("survivor_upgrade_awards_boom_cork", "1", "Number of Boom-Cork Awards To Earn Upgrade", CVAR_FLAGS, true, 0.0, true, 10.0);
	AwardTitle[26] = "\x05Boom-Cork Award\x01";
	AwardIndex[27] = CreateConVar("survivor_upgrade_awards_tongue_twister", "1", "Number of Tongue Twister Awards To Earn Upgrade", CVAR_FLAGS, true, 0.0, true, 10.0);
	AwardTitle[27] = "\x05Tongue Twister Award\x01";
	AwardIndex[66] = CreateConVar("survivor_upgrade_awards_helping_hand", "4", "Number of Helping Hand Awards To Earn Upgrade", CVAR_FLAGS, true, 0.0, true, 10.0);
	AwardTitle[66] = "\x05Helping Hand Award\x01";
	AwardIndex[67] = CreateConVar("survivor_upgrade_awards_my_bodyguard", "4", "Number of My Bodyguard Awards To Earn Upgrade", CVAR_FLAGS, true, 0.0, true, 10.0);
	AwardTitle[67] = "\x05My Bodyguard Award\x01";
	AwardIndex[68] = CreateConVar("survivor_upgrade_awards_pharm_assist", "4", "Number of Pharm-Assist Awards To Earn Upgrade", CVAR_FLAGS, true, 0.0, true, 10.0);
	AwardTitle[68] = "\x05Pharm-Assist Award\x01";
	AwardIndex[69] = CreateConVar("survivor_upgrade_awards_medic", "4", "Number of Medic Awards To Earn Upgrade", CVAR_FLAGS, true, 0.0, true, 10.0);
	AwardTitle[69] = "\x05Medic Award\x01";
	AwardIndex[70] = CreateConVar("survivor_upgrade_awards_brain_salad", "30", "Number of Brain Salad Awards To Earn Upgrade", CVAR_FLAGS, true, 0.0, true, 100.0);
	AwardTitle[70] = "\x05Brain Salad Award\x01";
	AwardIndex[71] = CreateConVar("survivor_upgrade_awards_spinal_tap", "5", "Number of Spinal Tap Awards To Earn Upgrade", CVAR_FLAGS, true, 0.0, true, 10.0);
	AwardTitle[71] = "\x05Spinal Tap Award\x01";
	AwardIndex[72] = CreateConVar("survivor_upgrade_awards_man_vs_tank", "1", "Number of Man Vs. Tank Awards To Earn Upgrade", CVAR_FLAGS, true, 0.0, true, 10.0);
	AwardTitle[72] = "\x05Man Vs. Tank Award\x01";
	AwardIndex[73] = CreateConVar("survivor_upgrade_awards_tank_killer", "1", "Number of Tank Killer To Earn Upgrade", CVAR_FLAGS, true, 0.0, true, 10.0);
	AwardTitle[73] = "\x05Tank Killer Award\x01";
	AwardIndex[75] = CreateConVar("survivor_upgrade_awards_special_savior", "4", "Number of Special Savior Awards To Earn Upgrade", CVAR_FLAGS, true, 0.0, true, 10.0);
	AwardTitle[75] = "\x05Special Savior Award\x01";
	AwardIndex[79] = CreateConVar("survivor_upgrade_awards_hero_closet", "1", "Number of Hero Closet Awards To Earn Upgrade", CVAR_FLAGS, true, 0.0, true, 10.0);
	AwardTitle[79] = "\x05Hero Closet Award\x01";
	AwardIndex[80] = CreateConVar("survivor_upgrade_awards_tankbusters", "1", "Number of Tankbusters Award To Earn Upgrade", CVAR_FLAGS, true, 0.0, true, 10.0);
	AwardTitle[80] = "\x05Tankbusters Award\x01";
	AwardIndex[83] = CreateConVar("survivor_upgrade_awards_teamkill", "1", "Number of Team Kill Penalties To Lose Upgrade", CVAR_FLAGS, true, 0.0, true, 10.0);
	AwardTitle[83] = "\x05Team-Kill Penalty\x01";
	AwardIndex[84] = CreateConVar("survivor_upgrade_awards_teamincapacitate", "1", "Number of Team-Incapacitate Penalty To Lose Upgrade", CVAR_FLAGS, true, 0.0, true, 10.0);
	AwardTitle[84] = "\x05Team-Incapacitate Penalty\x01";
	AwardIndex[85] = CreateConVar("survivor_upgrade_awards_leftfordead", "1", "Number of Left 4 Dead Penalty To Lose Upgrade", CVAR_FLAGS, true, 0.0, true, 10.0);
	AwardTitle[85] = "\x05Left 4 Dead Penalty\x01";
	AwardIndex[86] = CreateConVar("survivor_upgrade_awards_friendly_fire", "2", "Number of Friendly-Fire Penalty To Lose Upgrade", CVAR_FLAGS, true, 0.0, true, 10.0);
	AwardTitle[86] = "\x05Friendly-Fire Penalty\x01";
	AwardIndex[94] = CreateConVar("survivor_upgrade_awards_zombieroom", "1", "Number of Zombie Room Penalty To Lose Upgrade", CVAR_FLAGS, true, 0.0, true, 10.0);
	AwardTitle[94] = "\x05Zombie Room Penalty\x01";
	AwardIndex[99] = CreateConVar("survivor_upgrade_awards_teamabandoned", "1", "Number of Team-Abandoned Penalty To Lose Upgrade", CVAR_FLAGS, true, 0.0, true, 10.0);
	AwardTitle[99] = "\x05Team-Abandoned Penalty\x01";
	AwardIndex[100] = CreateConVar("survivor_upgrade_awards_101_cremations", "101", "Number of 101 Cremations To Earn Upgrade", CVAR_FLAGS, true, 0.0, true, 101.0);
	AwardTitle[100] = "\x05101 Cremations Award\x01";
	AwardIndex[101] = CreateConVar("survivor_upgrade_awards_incapicated", "1", "Number of Incapacitated Penalty To Lose Upgrade", CVAR_FLAGS, true, 0.0, true, 10.0);
	AwardTitle[101] = "\x05Incapacitated Penalty\x01";
	AwardIndex[102] = CreateConVar("survivor_upgrade_awards_barf_bagged", "1", "Number of Barf Bagged Penalty To Lose Upgrade", CVAR_FLAGS, true, 0.0, true, 10.0);
	AwardTitle[102] = "\x05Barf Bagged Penalty\x01";
	AwardIndex[103] = CreateConVar("survivor_upgrade_awards_vomit_bomb", "1", "Number of Vomit Bomb Penalty To Lose Upgrade", CVAR_FLAGS, true, 0.0, true, 10.0);
	AwardTitle[103] = "\x05Vomit Bomb Penalty\x01";
	
	RegConsoleCmd("sm_upgrades", PrintToChatUpgrades, "List Upgrades.");
	RegConsoleCmd("sm_laser", UpgradeLaserSightToggle, "Toggle the Laser Sight.");
	RegConsoleCmd("sm_save", UpgradeSaveToggle, "Toggle the Save Mode.");
	RegConsoleCmd("sm_perks", OpenPerkMenu, "Opens up the Perk Menu.");
	RegAdminCmd("sm_giveupgrade", CommandGiveUpgrade, ADMFLAG_CHEATS,  "Give player specfied upgrade.");
	RegAdminCmd("sm_giverandomupgrade", CommandGiveRandomUpgrade, ADMFLAG_CHEATS,  "Give player random upgrade.");
	RegAdminCmd("sm_toggleupgrade", CommandToggleUpgrade, ADMFLAG_CHEATS,  "Toggle player specfied upgrade.");

	UpgradeIndex[0] = 1;
	UpgradeTitle[0] = "\x03Hydration Belt \x01(\x04Increased Pain Pills Capacity\x01)";
	UpgradeShort[0] = "\x03Hydration Belt\x01";
	UpgradeEnabled[0] = CreateConVar("survivor_upgrade_hydration_belt_enable", "1", "Enable/Disable Hydration Belt", CVAR_FLAGS, true, 0.0, true, 1.0);
	PerkTitle[0] = "Hydration Belt";

	UpgradeIndex[1] = 2;
	UpgradeTitle[1] = "\x03Kevlar Body Armor \x01(\x04Decreased Damage\x01)";
	UpgradeShort[1] = "\x03Kevlar Body Armor\x01";
	UpgradeEnabled[1] = CreateConVar("survivor_upgrade_kevlar_armor_enable", "1", "Enable/Disable Kevlar Body Armor", CVAR_FLAGS, true, 0.0, true, 1.0);
	PerkTitle[1] = "Kevlar Body Armor";

	UpgradeIndex[2] = 4;
	UpgradeTitle[2] = "\x03Steroids \x01(\x04Increased Pain Pills Effect\x01)";
	UpgradeShort[2] = "\x03Steroids\x01";
	UpgradeEnabled[2] = CreateConVar("survivor_upgrade_steroids_enable", "1", "Enable/Disable Steroids", CVAR_FLAGS, true, 0.0, true, 1.0);
	PerkTitle[2] = "Steroids";

	UpgradeIndex[3] = 8;
	UpgradeTitle[3] = "\x03Bandages \x01(\x04Increased Revive Buffer\x01)";
	UpgradeShort[3] = "\x03Bandages\x01";
	UpgradeEnabled[3] = CreateConVar("survivor_upgrade_bandages_enable", "1", "Enable/Disable Bandages", CVAR_FLAGS, true, 0.0, true, 1.0);
	PerkTitle[3] = "Bandages";

	UpgradeIndex[4] = 16;
	UpgradeTitle[4] = "\x03Beta-Blockers \x01(\x04Increased Incapacitation Health\x01)";
	UpgradeShort[4] = "\x03Beta-Blockers\x01";
	UpgradeEnabled[4] = CreateConVar("survivor_upgrade_beta_blockers_enable", "1", "Enable/Disable Beta-Blockers", CVAR_FLAGS, true, 0.0, true, 1.0);
	PerkTitle[4] = "Beta-Blockers";

	UpgradeIndex[5] = 32;
	UpgradeTitle[5] = "\x03Morphogenic Cells \x01(\x04Limited Health Regeneration\x01)";
	UpgradeShort[5] = "\x03Morphogenic Cells\x01";
	UpgradeEnabled[5] = CreateConVar("survivor_upgrade_morphogenic_cells_enable", "1", "Enable/Disable Morphogenic Cells", CVAR_FLAGS, true, 0.0, true, 1.0);
	PerkTitle[5] = "Morphogenic Cells";

	UpgradeIndex[6] = 64;
	UpgradeTitle[6] = "\x03Air Boots \x01(\x04Increased Jump Height\x01)";
	UpgradeShort[6] = "\x03Air Boots\x01";
	UpgradeEnabled[6] = CreateConVar("survivor_upgrade_air_boots_enable", "1", "Enable/Disable Air Boots", CVAR_FLAGS, true, 0.0, true, 1.0);
	PerkTitle[6] = "Air Boots";

	UpgradeIndex[7] = 128;
	UpgradeTitle[7] = "\x03Ammo Pouch \x01(\x04Increased Ammunition Reserve\x01)";
	UpgradeShort[7] = "\x03Ammo Pouch\x01";
	UpgradeEnabled[7] = CreateConVar("survivor_upgrade_ammo_pouch_enable", "1", "Enable/Disable Ammo Pouch", CVAR_FLAGS, true, 0.0, true, 1.0);
	PerkTitle[7] = "Ammo Pouch";

	UpgradeIndex[8] = 256;
	UpgradeTitle[8] = "\x03Boomer Neutralizer \x01(\x04Anti-Boomer Special Attack\x01)";
	UpgradeShort[8] = "\x03Boomer Neutralizer\x01";
	UpgradeEnabled[8] = CreateConVar("survivor_upgrade_boomer_neutralizer_enable", "1", "Enable/Disable Boomer Neutralizer", CVAR_FLAGS, true, 0.0, true, 1.0);
	PerkTitle[8] = "Boomer Neutralizer";

	UpgradeIndex[9] = 512;
	UpgradeTitle[9] = "\x03Smoker Neutralizer \x01(\x04Anti-Smoker Special Attack\x01)";
	UpgradeShort[9] = "\x03Smoker Neutralizer\x01";
	UpgradeEnabled[9] = CreateConVar("survivor_upgrade_smoker_neutralizer_enable", "1", "Enable/Disable Smoker Neutralizer", CVAR_FLAGS, true, 0.0, true, 1.0);
	PerkTitle[9] = "Smoker Neutralizer";

	UpgradeIndex[10] = 1024;
	UpgradeTitle[10] = "\x03Medical Belt \x01(\x04Increased First Aid Kit Capacity\x01)";
	UpgradeShort[10] = "\x03Medical Belt\x01";
	UpgradeEnabled[10] = CreateConVar("survivor_upgrade_dual_satchel_enable", "1", "Enable/Disable Dual Satchel", CVAR_FLAGS, true, 0.0, true, 1.0);
	PerkTitle[10] = "Medical Belt";

	UpgradeIndex[11] = 2048;
	UpgradeTitle[11] = "\x03Climbing Chalk \x01(\x04Self-Ledge Save\x01)";
	UpgradeShort[11] = "\x03Climbing Chalk\x01";
	UpgradeEnabled[11] = CreateConVar("survivor_upgrade_climbing_chalk_enable", "1", "Enable/Disable Climbing Chalk", CVAR_FLAGS, true, 0.0, true, 1.0);
	PerkTitle[11] = "Climbing Chalk";

	UpgradeIndex[12] = 4096;
	UpgradeTitle[12] = "\x03Second Wind \x01(\x04Self-Revive Save\x01)";
	UpgradeShort[12] = "\x03Second Wind\x01";
	UpgradeEnabled[12] = CreateConVar("survivor_upgrade_second_wind_enable", "1", "Enable/Disable Second Wind", CVAR_FLAGS, true, 0.0, true, 1.0);
	PerkTitle[12] = "Second Wind";

	UpgradeIndex[13] = 8192;
	UpgradeTitle[13] = "\x03Goggles \x01(\x04See-Through Boomer Vomit\x01)";
	UpgradeShort[13] = "\x03Goggles\x01";
	UpgradeEnabled[13] = CreateConVar("survivor_upgrade_goggles_enable", "1", "Enable/Disable Goggles", CVAR_FLAGS, true, 0.0, true, 1.0);
	PerkTitle[13] = "Goggles";

	UpgradeIndex[14] = 16384;
	UpgradeTitle[14] = "\x03Morphine \x01(\x04Resistant Against Limp Pain\x01)";
	UpgradeShort[14] = "\x03Morphine\x01";
	UpgradeEnabled[14] = CreateConVar("survivor_upgrade_morphine_enable", "1", "Enable/Disable Morphine", CVAR_FLAGS, true, 0.0, true, 1.0);
	PerkTitle[14] = "Morphine";

	UpgradeIndex[15] = 32768;
	UpgradeTitle[15] = "\x03Adrenaline Implant \x01(\x04Increased Movement Speed\x01)";
	UpgradeShort[15] = "\x03Adrenaline Implant\x01";
	UpgradeEnabled[15] = CreateConVar("survivor_upgrade_adrenaline_implant_enable", "1", "Enable/Disable Adrenaline Implant", CVAR_FLAGS, true, 0.0, true, 1.0);
	PerkTitle[15] = "Adrenaline Implant";

	UpgradeIndex[16] = 65536;
	UpgradeTitle[16] = "\x03Hot Meal \x01(\x04Restore Health On Next Saferoom\x01)";
	UpgradeShort[16] = "\x03Hot Meal\x01";
	UpgradeEnabled[16] = CreateConVar("survivor_upgrade_hot_meal_enable", "1", "Enable/Disable Hot Meal", CVAR_FLAGS, true, 0.0, true, 1.0);
	PerkTitle[16] = "Hot Meal";

	UpgradeIndex[17] = 131072;
	UpgradeTitle[17] = "\x03Laser Sight \x01(\x04Increased Accuracy\x01)";
	UpgradeShort[17] = "\x03Laser Sight\x01";
	UpgradeEnabled[17] = CreateConVar("survivor_upgrade_laser_sight_enable", "1", "Enable/Disable Laser Sight", CVAR_FLAGS, true, 0.0, true, 1.0);
	PerkTitle[17] = "Laser Sight";

	UpgradeIndex[18] = 262144;
	UpgradeTitle[18] = "\x03Silencer \x01(\x04Silenced Gunfire & Muzzle Flash\x01)";
	UpgradeShort[18] = "\x03Silencer\x01";
	UpgradeEnabled[18] = CreateConVar("survivor_upgrade_silencer_enable", "1", "Enable/Disable Silencer", CVAR_FLAGS, true, 0.0, true, 1.0);
	PerkTitle[18] = "Silencer";

	UpgradeIndex[19] = 524288;
	UpgradeTitle[19] = "\x03Combat Sling \x01(\x04Reduced Recoil\x01)";
	UpgradeShort[19] = "\x03Combat Sling\x01";
	UpgradeEnabled[19] = CreateConVar("survivor_upgrade_combat_sling_enable", "1", "Enable/Disable Combat Sling", CVAR_FLAGS, true, 0.0, true, 1.0);
	PerkTitle[19] = "Combat Sling";

	UpgradeIndex[20] = 1048576;
	UpgradeTitle[20] = "\x03High Capacity Magazine \x01(\x04Increased Magazine Size\x01)";
	UpgradeShort[20] = "\x03High Capacity Magazine\x01";
	UpgradeEnabled[20] = CreateConVar("survivor_upgrade_extended_magazine_enable", "1", "Enable/Disable High Capacity Magazine", CVAR_FLAGS, true, 0.0, true, 1.0);
	PerkTitle[20] = "High Capacity Magazine";

	UpgradeIndex[21] = 2097152;
	UpgradeTitle[21] = "\x03Hollow Point Ammunition \x01(\x04Increased Bullet Damage\x01)";
	UpgradeShort[21] = "\x03Hollow Point Ammunition\x01";
	UpgradeEnabled[21] = CreateConVar("survivor_upgrade_hollow_point_enable", "1", "Enable/Disable Hollow Point Ammunition", CVAR_FLAGS, true, 0.0, true, 1.0);
	PerkTitle[21] = "Hollow Point Ammunition";

	UpgradeIndex[22] = 4194304;
	UpgradeTitle[22] = "\x03Night Vision Goggles \x01(\x04Increased Dark Vision\x01)";
	UpgradeShort[22] = "\x03Night Vision Goggles\x01";
	UpgradeEnabled[22] = CreateConVar("survivor_upgrade_night_vision_enable", "1", "Enable/Disable Night Vision Goggles", CVAR_FLAGS, true, 0.0, true, 1.0);
	PerkTitle[22] = "Night Vision Goggles";

	UpgradeIndex[23] = 8388608;
	UpgradeTitle[23] = "\x03Safety Fuse \x01(\x04Increased Pipebomb Duration\x01)";
	UpgradeShort[23] = "\x03Safety Fuse\x01";
	UpgradeEnabled[23] = CreateConVar("survivor_upgrade_safety_fuse_enable", "1", "Enable/Disable Safety Fuse", CVAR_FLAGS, true, 0.0, true, 1.0);
	PerkTitle[23] = "Safety Fuse";

	UpgradeIndex[24] = 16777216;
	UpgradeTitle[24] = "\x03Sniper Scope \x01(\x04Sniper Zoom Attachment\x01)";
	UpgradeShort[24] = "\x03Sniper Scope\x01";
	UpgradeEnabled[24] = CreateConVar("survivor_upgrade_scope_enable", "1", "Enable/Disable Sniper Scope", CVAR_FLAGS, true, 0.0, true, 1.0);
	PerkTitle[24] = "Sniper Scope";

	UpgradeIndex[25] = 33554432;
	UpgradeTitle[25] = "\x03Sniper Scope Accuracy \x01(\x04Increased Zoom Accuracy\x01)";
	UpgradeShort[25] = "\x03Sniper Scope Accuracy\x01";
	UpgradeEnabled[25] = CreateConVar("survivor_upgrade_scope_accuracy_enable", "1", "Enable/Disable Sniper Scope Accuracy", CVAR_FLAGS, true, 0.0, true, 1.0);
	PerkTitle[25] = "Sniper Scope Accuracy";

	UpgradeIndex[26] = 67108864;
	UpgradeTitle[26] = "\x03Knife \x01(\x04Self-Save Pinned\x01)";
	UpgradeShort[26] = "\x03Knife\x01";
	UpgradeEnabled[26] = CreateConVar("survivor_upgrade_knife_enable", "1", "Enable/Disable Knife", CVAR_FLAGS, true, 0.0, true, 1.0);
	PerkTitle[26] = "Knife";

	UpgradeIndex[27] = 134217728;
	UpgradeTitle[27] = "\x03Smelling Salts \x01(\x04Reduced Revive Duration\x01)";
	UpgradeShort[27] = "\x03Smelling Salts\x01";
	UpgradeEnabled[27] = CreateConVar("survivor_upgrade_smelling_salts_enable", "1", "Enable/Disable Smelling Salts", CVAR_FLAGS, true, 0.0, true, 1.0);
	PerkTitle[27] = "Smelling Salts";

	UpgradeIndex[28] = 268435456;
	UpgradeTitle[28] = "\x03Ointment \x01(\x04Increased Healing Effect\x01)";
	UpgradeShort[28] = "\x03Ointment\x01";
	UpgradeEnabled[28] = CreateConVar("survivor_upgrade_ointment_enable", "1", "Enable/Disable Ointment", CVAR_FLAGS, true, 0.0, true, 1.0);
	PerkTitle[28] = "Ointment";

	UpgradeIndex[29] = 536870912;
	UpgradeTitle[29] = "\x03Slight of Hand \x01(\x04Increase Reload Speed\x01)";
	UpgradeShort[29] = "\x03Slight of Hand\x01";
	UpgradeEnabled[29] = CreateConVar("survivor_upgrade_reloader_enable", "1", "Enable/Disable Slight of Hand", CVAR_FLAGS, true, 0.0, true, 1.0);
	PerkTitle[29] = "Slight of Hand";

	UpgradeIndex[30] = 1073741824;
	UpgradeTitle[30] = "\x03Stimpacks \x01(\x04Reduced Healing Duration\x01)";
	UpgradeShort[30] = "\x03Stimpacks\x01";
	UpgradeEnabled[30] = CreateConVar("survivor_upgrade_quick_heal_enable", "1", "Enable/Disable Stimpacks", CVAR_FLAGS, true, 0.0, true, 1.0);
	PerkTitle[30] = "Stimpacks";

	UpgradeIndex[31] = 1;
	UpgradeTitle[31] = "\x03Grenade Pouch \x01(\x04Increased Grenade Slots\x01)";
	UpgradeShort[31] = "\x03Grenade Pouch\x01";
	UpgradeEnabled[31] = CreateConVar("survivor_upgrade_grenade_pouch_enable", "1", "Enable/Disable Grenade Pouch", CVAR_FLAGS, true, 0.0, true, 1.0);
	PerkTitle[31] = "Grenade Pouch";

	UpgradeIndex[32] = 1;
	UpgradeTitle[32] = "\x03Pickpocket Hook \x01(\x04Steal Items On Stealth Kills\x01)";
	UpgradeShort[32] = "\x03Pickpocket Hook\x01";
	UpgradeEnabled[32] = CreateConVar("survivor_upgrade_pickpocket_hook_enable", "1", "Enable/Disable Pickpocket Hook", CVAR_FLAGS, true, 0.0, true, 1.0);
	PerkTitle[32] = "Pickpocket Hook";

	UpgradeIndex[33] = 1;
	UpgradeTitle[33] = "\x03Ocular Implants \x01(\x04Infected Drop Items\x01)";
	UpgradeShort[33] = "\x03Ocular Implants\x01";
	UpgradeEnabled[33] = CreateConVar("survivor_upgrade_ocular_implants_enable", "1", "Enable/Disable Ocular Implants", CVAR_FLAGS, true, 0.0, true, 1.0);
	PerkTitle[33] = "Ocular Implants";

	UpgradeIndex[34] = 1;
	UpgradeTitle[34] = "\x03Pyro Pouch \x01(\x04Explosives Are More Effective\x01)";
	UpgradeShort[34] = "\x03Pyro Pouch\x01";
	UpgradeEnabled[34] = CreateConVar("survivor_upgrade_pyro_pouch_enable", "1", "Enable/Disable Pyro Pouch", CVAR_FLAGS, true, 0.0, true, 1.0);
	PerkTitle[34] = "Pyro Kit";

	UpgradeIndex[35] = 1;
	UpgradeTitle[35] = "\x03Transfusion Box \x01(\x04Allow Health Recovery From Melee\x01)";
	UpgradeShort[35] = "\x03Transfusion Box\x01";
	UpgradeEnabled[35] = CreateConVar("survivor_upgrade_transfusion_box_enable", "1", "Enable/Disable Transfusion Box", CVAR_FLAGS, true, 0.0, true, 1.0);
	PerkTitle[35] = "Transfusion Box";

	UpgradeIndex[36] = 1;
	UpgradeTitle[36] = "\x03Arm Guards \x01(\x04Increased Maximum Health\x01)";
	UpgradeShort[36] = "\x03Arm Guards\x01";
	UpgradeEnabled[36] = CreateConVar("survivor_upgrade_arm_guards_enable", "1", "Enable/Disable Arm Guards", CVAR_FLAGS, true, 0.0, true, 1.0);
	PerkTitle[36] = "Arm Guards";

	UpgradeIndex[37] = 1;
	UpgradeTitle[37] = "\x03Shin Guards \x01(\x04Increased Maximum Health\x01)";
	UpgradeShort[37] = "\x03Shin Guards\x01";
	UpgradeEnabled[37] = CreateConVar("survivor_upgrade_shin_guards_enable", "1", "Enable/Disable Shin Guards", CVAR_FLAGS, true, 0.0, true, 1.0);
	PerkTitle[37] = "Shin Guards";

	UpgradeIndex[38] = 1;
	UpgradeTitle[38] = "\x03Autoinjectors \x01(\x04Increased Incapacitation Limit\x01)";
	UpgradeShort[38] = "\x03Autoinjectors\x01";
	UpgradeEnabled[38] = CreateConVar("survivor_upgrade_autoinjectors_enable", "1", "Enable/Disable Autoinjectors", CVAR_FLAGS, true, 0.0, true, 1.0);
	PerkTitle[38] = "Autoinjectors";

	UpgradeIndex[39] = 1;
	UpgradeTitle[39] = "\x03Kerosene \x01(\x04Increased Molotov Burn Duration\x01)";
	UpgradeShort[39] = "\x03Kerosene\x01";
	UpgradeEnabled[39] = CreateConVar("survivor_upgrade_kerosene_enable", "1", "Enable/Disable Kerosene", CVAR_FLAGS, true, 0.0, true, 1.0);
	PerkTitle[39] = "Kerosene";

	UpgradeIndex[40] = 1;
	UpgradeTitle[40] = "\x03Weapon Holster \x01(\x04Increased Primary Weapon Capacity\x01)";
	UpgradeShort[40] = "\x03Weapon Holster\x01";
	UpgradeEnabled[40] = CreateConVar("survivor_upgrade_weapon_holster_enable", "1", "Enable/Disable Weapon Holster", CVAR_FLAGS, true, 0.0, true, 1.0);
	PerkTitle[40] = "Weapon Holster";
	
	UpgradeIndex[41] = 1;
	UpgradeTitle[41] = "\x03Casing Dispenser \x01(\x04Regenerate Ammunition Slowly\x01)";
	UpgradeShort[41] = "\x03Casing Dispenser\x01";
	UpgradeEnabled[41] = CreateConVar("survivor_upgrade_casing_dispenser_enable", "1", "Enable/Disable Casing Dispenser", CVAR_FLAGS, true, 0.0, true, 1.0);
	PerkTitle[41] = "Casing Dispenser";
	
	UpgradeIndex[42] = 1;
	UpgradeTitle[42] = "\x03Helmet \x01(\x04Increased Maximum Health\x01)";
	UpgradeShort[42] = "\x03Helmet\x01";
	UpgradeEnabled[42] = CreateConVar("survivor_upgrade_helmet_enable", "1", "Enable/Disable Helmet", CVAR_FLAGS, true, 0.0, true, 1.0);
	PerkTitle[42] = "Helmet";
	
	UpgradeIndex[43] = 1;
	UpgradeTitle[43] = "\x03Medical Chart \x01(\x04Heal Other Players Nearby\x01)";
	UpgradeShort[43] = "\x03Medical Chart\x01";
	UpgradeEnabled[43] = CreateConVar("survivor_upgrade_medical_chart_enable", "1", "Enable/Disable Medical Chart", CVAR_FLAGS, true, 0.0, true, 1.0);
	PerkTitle[43] = "Medical Chart";
	
	UpgradeIndex[44] = 1;
	UpgradeTitle[44] = "\x03Pill Box \x01(\x04Consuming Pills Affects Other Players\x01)";
	UpgradeShort[44] = "\x03Pill Box\x01";
	UpgradeEnabled[44] = CreateConVar("survivor_upgrade_pill_box_enable", "1", "Enable/Disable Pill Box", CVAR_FLAGS, true, 0.0, true, 1.0);
	PerkTitle[44] = "Pill Box";

	HookUserMessage(GetUserMessageId("SayText"), SayTextHook, true);

	HookEvent("player_spawn", event_PlayerSpawn, EventHookMode_Post);
	HookEvent("player_death", event_PlayerDeath);
	HookEvent("player_team", event_PlayerTeam);	
	HookEvent("survivor_rescued", event_Rescued);
	HookEvent("award_earned", event_AwardEarned);
	HookEvent("round_start", round_start);
	HookEvent("round_end", round_end, EventHookMode_Pre);
	HookEvent("heal_success", event_HealSuccess);
	HookEvent("heal_begin", event_HealBegin, EventHookMode_Pre);	
	HookEvent("bot_player_replace", event_BotPlayerReplace, EventHookMode_Post);
		
	HookEvent("map_transition", round_end, EventHookMode_Pre);

	HookEvent("weapon_fire", event_WeaponFire, EventHookMode_Pre);
	HookEvent("pills_used", event_PillsUsed, EventHookMode_Post);
	HookEvent("revive_success", event_ReviveSuccess);
	HookEvent("player_incapacitated", event_PlayerIncapacitated);
	HookEvent("player_hurt", event_PlayerHurt, EventHookMode_Post);
	HookEvent("player_jump", event_PlayerJump);
	HookEvent("player_use", event_PlayerUse, EventHookMode_Post); // Left 4 Dead 2 Style Ammo Pickup
	HookEvent("item_pickup", event_ItemPickup, EventHookMode_Post); // Left 4 Dead 2 Style Ammo Pickup
	HookEvent("ammo_pickup", event_AmmoPickup, EventHookMode_Post); // Left 4 Dead 2 Style Ammo Pickup
	HookEvent("weapon_given", event_WeaponGiven, EventHookMode_Post);	
	HookEvent("break_prop", event_BreakProp, EventHookMode_Post);
	HookEvent("entity_shoved", event_EntityShoved, EventHookMode_Post);
	//HookEvent("player_left_checkpoint", event_LeftCheckpoint, EventHookMode_Post);
	
	// Custom Awards
	HookEvent("infected_death", event_InfectedDeath);
	HookEvent("infected_hurt", event_InfectedHurt);
	HookEvent("melee_kill", event_MeleeKill, EventHookMode_Pre);
	HookEvent("tank_killed", event_TankKilled);
	HookEvent("player_now_it", event_PlayerNowIt);

	SetConVarInt(FindConVar("first_aid_kit_max_heal"), 250, false, false);
	SetConVarInt(FindConVar("pain_pills_health_threshold"), 250, false, false);
	SetConVarInt(FindConVar("first_aid_kit_use_duration"), 5, false, false);
	SetConVarInt(FindConVar("survivor_revive_duration"), 5, false, false);
	SetConVarInt(FindConVar("pipe_bomb_timer_duration"), 6, false, false);
	SetConVarInt(FindConVar("pain_pills_health_value"), 50, false, false);
	
	FirstAidDuration = GetConVarFloat(FindConVar("first_aid_kit_use_duration"));
	PipeBombDuration = GetConVarFloat(FindConVar("pipe_bomb_timer_duration"));
	AutoExecConfig(true, "l4d_upgradesreloaded");
	if (!IsDatabaseLoaded)
	{
		IsDatabaseLoaded = true;
		MySQL_Init();
	}
}

MySQL_Init()
{	
	decl String:Error[192];

	hDatabase = SQLite_UseDatabase("SurvivorUpgradesReloaded", Error, sizeof(Error));
	
	if(hDatabase == INVALID_HANDLE)
		SetFailState("SQL error: %s", Error);

	SQL_FastQuery(hDatabase, "CREATE TABLE IF NOT EXISTS accounts (steamid TEXT PRIMARY KEY, saveenabled SMALLINT, notifications SMALLINT, perkbonus SMALLINT, upgrades_binary VARCHAR(44), disabled_binary VARCHAR(44));");
}

stock SaveData(client)
{
	if(iSaveFeature[client] == 1 && GetClientTeam(client) != 3)
	{
		decl String:TQuery[3000], String:SteamID[64], String:UpgradeBinary[64] = "", String:DisabledBinary[64] = "";
		for(new i = 0; i < MAX_UPGRADES; i++)
		{
			if(iUpgrade[client][i] > 0)
				Format(UpgradeBinary, sizeof(UpgradeBinary), "%s1", UpgradeBinary);
			else
				Format(UpgradeBinary, sizeof(UpgradeBinary), "%s0", UpgradeBinary);

			if(iUpgradeDisabled[client][i] > 0)
				Format(DisabledBinary, sizeof(DisabledBinary), "%s1", DisabledBinary);
			else
				Format(DisabledBinary, sizeof(DisabledBinary), "%s0", DisabledBinary);
		}
		GetClientAuthId(client, AuthId_Steam2, SteamID, sizeof(SteamID));
		new m_survivorCharacter = GetEntProp(client, Prop_Send, "m_survivorCharacter");
		if(IsFakeClient(client) && m_survivorCharacter >= 0)
		{
			Format(SteamID, sizeof(SteamID), "%s_%d", SteamID, m_survivorCharacter);
		}
		Format(TQuery, sizeof(TQuery), "INSERT OR REPLACE INTO accounts VALUES ('%s', %d, %d, %d, '%s', '%s');", SteamID, iSaveFeature[client], iAnnounceText[client], iPerkBonusSlots[client],UpgradeBinary, DisabledBinary);
		SQL_FastQuery(hDatabase, TQuery);
	}
}

public OnClientPostAdminCheck(client)
{
	iSaveFeature[client] = 0;
	iAnnounceText[client] = 0;
	iPerkBonusSlots[client] = 0;
	for(new i = 0; i < MAX_UPGRADES; i++)
	{
		iUpgrade[client][i] = 0;
		iUpgradeDisabled[client][i] = 0;
	}
	if(GetClientTeam(client) != 3)
		CreateTimer(0.2, timer_LoadData, client);
	SDKHook(client, SDKHook_WeaponCanUse, OnWeaponCanUse);
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
	//PrintToChatAll("%s", m_attacker);
	if(iUpgrade[victim][1] > 0 && GetClientTeam(victim) == 2)
	{
		//PrintToChat(victim, "Damage: %f, New: %f", damage, damage*0.5);
		damage = damage * 0.5;
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

public Action:timer_LoadData(Handle:hTimer, any:client)
{
	LoadData(client);
}

stock LoadData(client)
{
	if(IsClientConnected(client))
	{
		decl String:TQuery[192], String:SteamID[64];

		GetClientAuthId(client, AuthId_Steam2, SteamID, sizeof(SteamID));
		new m_survivorCharacter = GetEntProp(client, Prop_Send, "m_survivorCharacter");
		if(IsFakeClient(client) && m_survivorCharacter >= 0)
		{
			Format(SteamID, sizeof(SteamID), "%s_%d", SteamID, m_survivorCharacter);
		}
		Format(TQuery, sizeof(TQuery), "SELECT * FROM accounts WHERE steamId = '%s';", SteamID);
		SQL_TQuery(hDatabase, LoadPlayerData, TQuery, client);
	}
}

public LoadPlayerData(Handle:owner, Handle:hndl, const String:error[], any:client)
{
	if(hndl == INVALID_HANDLE || SQL_GetRowCount(hndl) == 0 || (IsClientInGame(client) && GetClientTeam(client) == 3))
	{
		return;
	}

	iBitsUpgrades[client] = 0;

	decl String:UpgradeBinary[64], String:DisabledBinary[64];

	iSaveFeature[client] = SQL_FetchInt(hndl, 1);
	iAnnounceText[client] = SQL_FetchInt(hndl, 2);
	iPerkBonusSlots[client] = SQL_FetchInt(hndl, 3);
	SQL_FetchString(hndl, 4, UpgradeBinary, sizeof(UpgradeBinary));
	SQL_FetchString(hndl, 5, DisabledBinary, sizeof(DisabledBinary));

	new len = strlen(UpgradeBinary);
	for (new i = 0; i <= len; i++)
	{
		if(UpgradeBinary[i] == '1')
		{
			iUpgrade[client][i] = UpgradeIndex[i];
		}
	}

	len = strlen(DisabledBinary);
	for (new i = 0; i <= len; i++)
	{
		if(DisabledBinary[i] == '1')
		{
			iUpgradeDisabled[client][i] = 1;
		}
	}
	if(IsValidEntity(client))
		LogMessage("Loading Client %N - %d, %d, %s", client, iSaveFeature[client], iAnnounceText[client], UpgradeBinary);
}

public event_WeaponGiven(Handle:event, const String:name[], bool:dontBroadcast) 
{
	new client = GetClientOfUserId(GetEventInt(event,"giver"));
	new weapon = GetClientOfUserId(GetEventInt(event,"weapon"));

	if(weapon == 0)
	{
		iLargePainPills[client] = 0;
	}
}

public Action:CommandGiveUpgrade(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage:sm_giveupgrade <#userid|name> <index>");
		return Plugin_Handled;
	}
	decl String:arg[MAX_NAME_LENGTH], String:arg2[32];
	GetCmdArg(1, arg, sizeof(arg));
	if (args > 1)
	{
		GetCmdArg(2, arg2, sizeof(arg2));
	}
	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
	new targetclient;
	if ((target_count = ProcessTargetString(
			arg,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_ALIVE,
			target_name,
			sizeof(target_name),
			tn_is_ml)) > 0)
	{
		for (new i = 0; i < target_count; i++)
		{
			targetclient = target_list[i];
			GiveUpgrade(targetclient, StringToInt(arg2));
		}
	}
	else
	{
		ReplyToTargetError(client, target_count);
	}
	return Plugin_Handled;
}

public Action:CommandGiveRandomUpgrade(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage:sm_giverandomupgrade <#userid|name> <index>");
		return Plugin_Handled;
	}
	decl String:arg[MAX_NAME_LENGTH], String:arg2[32];
	GetCmdArg(1, arg, sizeof(arg));
	if (args > 1)
	{
		GetCmdArg(2, arg2, sizeof(arg2));
	}
	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
	new targetclient;
	if ((target_count = ProcessTargetString(
			arg,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_ALIVE,
			target_name,
			sizeof(target_name),
			tn_is_ml)) > 0)
	{
		for (new i = 0; i < target_count; i++)
		{
			targetclient = target_list[i];
			GiveSurvivorUpgrade(targetclient, StringToInt(arg2), 0);
		}
	}
	else
	{
		ReplyToTargetError(client, target_count);
	}
	return Plugin_Handled;
}

public Action:CommandToggleUpgrade(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage:sm_giveupgrade <#userid|name> <index>");
		return Plugin_Handled;
	}
	decl String:arg[MAX_NAME_LENGTH], String:arg2[32];
	GetCmdArg(1, arg, sizeof(arg));
	if (args > 1)
	{
		GetCmdArg(2, arg2, sizeof(arg2));
	}
	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
	new targetclient;
	if ((target_count = ProcessTargetString(
			arg,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_ALIVE,
			target_name,
			sizeof(target_name),
			tn_is_ml)) > 0)
	{
		for (new i = 0; i < target_count; i++)
		{
			targetclient = target_list[i];
			new upgrade = StringToInt(arg2);
			if(iUpgradeDisabled[targetclient][upgrade] == 0)
			{
				iUpgradeDisabled[targetclient][upgrade] = 1;
				if(iUpgrade[targetclient][upgrade] > 0)
				{
					iUpgrade[targetclient][upgrade] = 0;
					SetClientUpgradesCheck(targetclient);
				}
			}
			else
			{
				iUpgradeDisabled[targetclient][upgrade] = 0;
			}
		}
	}
	else
	{
		ReplyToTargetError(client, target_count);
	}
	return Plugin_Handled;
}

public Action:OnWeaponCanUse(client, weapon)
{
	if(IsClientInGame(client) && IsFakeClient(client))
	{
		return Plugin_Continue;
	}
	new String:iWeaponName[32];
	GetEdictClassname(weapon, iWeaponName, sizeof(iWeaponName));

	if(iUpgrade[client][31] > 0 && iGrenadePouch[client] == 1)
	{
		if(StrContains(iWeaponName, "molotov", false) != -1 || StrContains(iWeaponName, "pipe_bomb", false) != -1)
		{
			return Plugin_Handled;
		}
	}
	if(iUpgrade[client][40] > 0 && PlayerSlotEmpty(client) == true && GetPlayerWeaponSlot(client, 0) > 0)
	{
		if(StrEqual(iWeaponName, "weapon_pumpshotgun") || StrEqual(iWeaponName, "weapon_autoshotgun") || StrEqual(iWeaponName, "weapon_smg") || StrEqual(iWeaponName, "weapon_rifle") || StrEqual(iWeaponName, "weapon_hunting_rifle"))
		{
			GiveSecondary(client, weapon, false);
			return Plugin_Handled;
		}	
	}
	else if(iUpgrade[client][40] > 0 && PlayerSlotEmpty(client) == false && GetPlayerWeaponSlot(client, 0) > 0)
	{
		if(StrEqual(iWeaponName, "weapon_pumpshotgun") || StrEqual(iWeaponName, "weapon_autoshotgun") || StrEqual(iWeaponName, "weapon_smg") || StrEqual(iWeaponName, "weapon_rifle") || StrEqual(iWeaponName, "weapon_hunting_rifle"))
		{
			GiveSecondary(client, weapon, true);
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}

public bool:PlayerSlotEmpty(client)
{
		decl String:iWeaponName[32];
		new iTotal = 0;
		new iWeapon;
		new myweaponsoffset = FindSendPropOffs("CBasePlayer", "m_hMyWeapons");		
		for(new i = 0; i < 10; i++) 
		{
			iWeapon = GetEntDataEnt2(client, myweaponsoffset + i * 4);
			if(iWeapon > 0) 
			{
				GetEdictClassname(iWeapon, iWeaponName, sizeof(iWeaponName));
				if(StrEqual(iWeaponName, "weapon_pumpshotgun") || StrEqual(iWeaponName, "weapon_autoshotgun") || StrEqual(iWeaponName, "weapon_smg") || StrEqual(iWeaponName, "weapon_rifle") || StrEqual(iWeaponName, "weapon_hunting_rifle"))
				{
					iTotal++;
				}
			}
		}
		if(iTotal >= 2)
		{
			return false;
		}
		return true;
}

public GiveSecondary(client, weapon, bool:IsTakeAway)
{
	if(IsTakeAway == false)
	{
		SetConVarInt(FindConVar("survivor_slots"), 1, false, false);
		EquipPlayerWeapon(client, weapon);
		SetConVarInt(FindConVar("survivor_slots"), 0, false, false);
	}
	else if(IsTakeAway == true)
	{
		decl String:iWeaponName[32];
		new iWeapon;

		new myweaponsoffset = FindSendPropOffs("CBasePlayer", "m_hMyWeapons");
		for(new i = 0; i < 10; i++)
		{
			iWeapon = GetEntDataEnt2(client, myweaponsoffset + i * 4);
			if(iWeapon > 0 && iWeapon == GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon"))
			{
				GetEdictClassname(iWeapon, iWeaponName, sizeof(iWeaponName));
				//PrintToChat(client, "Active Weapon: %s / %d / %d", iWeaponName, iWeapon, weapon);
				if(StrEqual(iWeaponName, "weapon_pumpshotgun") || StrEqual(iWeaponName, "weapon_autoshotgun") || StrEqual(iWeaponName, "weapon_smg") || StrEqual(iWeaponName, "weapon_rifle") || StrEqual(iWeaponName, "weapon_hunting_rifle"))
				{
					decl Float:f_TargetPos[3], Float:f_ClientPos[3], Float:f_Distance, String:s_EdictNeeded[40];

					GetClientEyePosition(client, f_ClientPos);		// Get the bots eye origin
					
					GetEdictClassname(iWeapon, s_EdictNeeded, sizeof(s_EdictNeeded));
					StrCat(s_EdictNeeded, sizeof(s_EdictNeeded), "_spawn");
					new ent = -1;
					while((ent = FindEntityByClassname(ent, s_EdictNeeded)) != -1)
					{
						GetEntPropVector(ent, Prop_Send, "m_vecOrigin", f_TargetPos);
						f_Distance = GetVectorDistance(f_ClientPos, f_TargetPos);

						if(f_Distance <= 200)
						{
							PrintToChat(client, "Give Weapon");
							new itemCount = GetEntProp(ent, Prop_Data, "m_itemCount");
							SetEntProp(ent, Prop_Data, "m_itemCount", itemCount+1);
							RemovePlayerItem(client, iWeapon);
							AcceptEntityInput(iWeapon, "kill");
							SetConVarInt(FindConVar("survivor_slots"), 1, false, false);
							EquipPlayerWeapon(client, weapon);
							SetConVarInt(FindConVar("survivor_slots"), 0, false, false);
							return;
						}
						else
						{
							RemovePlayerItem(client, iWeapon);
							AcceptEntityInput(iWeapon, "kill");
							GivePlayerItem(client, iWeaponName);
							SetConVarInt(FindConVar("survivor_slots"), 1, false, false);
							EquipPlayerWeapon(client, weapon);
							SetConVarInt(FindConVar("survivor_slots"), 0, false, false);
							return;
						}
					}
				}				
			}
		}
	}
}

public Action:UpgradeSaveToggle(client, args)
{
	if(iSaveFeature[client] != 1)
	{
		iSaveFeature[client] = 1;
		PrintToChat(client, "\x01Save Feature is \x04On\x01.");
	}
	else
	{
		iSaveFeature[client] = 0;
		PrintToChat(client, "\x01Save Feature is \x04Off\x01.");
	}
}

public Action:SayTextHook(UserMsg:msg_id, Handle:bf, const players[], playersNum, bool:reliable, bool:init)
{
	BfReadShort(bf);
	BfReadShort(bf);
	BfReadString(bf, g_msgType, sizeof(g_msgType), false);	

	if(StrContains(g_msgType, "prevent_it_expire") != -1)
	{
		CreateTimer(0.1, DelayPrintExpire, 8);
		return Plugin_Handled;
	}
	if(StrContains(g_msgType, "Smoker's Tongue attack") != -1)
	{
		CreateTimer(0.1, DelayPrintExpire, 9);
		return Plugin_Handled;
	}
	if(StrContains(g_msgType, "ledge_save_expire") != -1)
	{
		CreateTimer(0.1, DelayPrintExpire, 11);
		return Plugin_Handled;
	}
	if(StrContains(g_msgType, "revive_self_expire") != -1)
	{
		CreateTimer(0.1, DelayPrintExpire, 12);
		return Plugin_Handled;
	}
	if(StrContains(g_msgType, "knife_expire") != -1)
	{
		CreateTimer(0.1, DelayPrintExpire, 26);
		return Plugin_Handled;
	}
	if(StrContains(g_msgType, "_expire") != -1)
	{
		return Plugin_Handled;
	}
	if(StrContains(g_msgType, "#L4D_Upgrade") != -1 && StrContains(g_msgType, "description") != -1)
	{
		return Plugin_Handled;
	}	
	if(StrContains(g_msgType, "NOTIFY_VOMIT_ON") != -1)
	{
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action:DelayPrintExpire(Handle:hTimer, any:type)
{
	new client = GetClientUsedUpgrade(type);
	if(client == 0)
		return;

	decl String:ClientUserName[MAX_TARGET_LENGTH];
	GetClientName(client, ClientUserName, sizeof(ClientUserName));

	if(type == 8)
	{
		PrintToChatAll("%s neutralized the Boomer's Vomit attack!", ClientUserName);
	}
	else if(type == 9)
	{
		PrintToChatAll("%s neutralized the Smoker's Tongue attack!", ClientUserName);
	}
	else if(type == 11)
	{
		PrintToChatAll("%s used Climbing Chalk!", ClientUserName);
	}
	else if(type == 12)
	{
		PrintToChatAll("%s used Second Wind!", ClientUserName);
	}
	else if(type == 26)
	{
		PrintToChatAll("%s used a Knife!", ClientUserName);
	}
}

public OnMapEnd()
{
	OnGameEnd();
}

OnGameEnd()
{
	for(new i = 1; i <= MaxClients; i++)
	{
		if(MorphogenicTimer[i] != INVALID_HANDLE)
		{
			CloseHandle(MorphogenicTimer[i]);
			MorphogenicTimer[i] = INVALID_HANDLE;
		}
		if(RegenerationTimer[i] != INVALID_HANDLE)
		{
			CloseHandle(RegenerationTimer[i]);
			RegenerationTimer[i] = INVALID_HANDLE;
		}
		if(CasingDispenserTimer[i] != INVALID_HANDLE)
		{
			CloseHandle(CasingDispenserTimer[i]);
			CasingDispenserTimer[i] = INVALID_HANDLE;
		}
		if(SetClientUpgrades[i] != INVALID_HANDLE)
		{
			CloseHandle(SetClientUpgrades[i]);
			SetClientUpgrades[i] = INVALID_HANDLE;
		}
		if(AwardsCooldownTimer[i] != INVALID_HANDLE)
		{
			CloseHandle(AwardsCooldownTimer[i]);
			AwardsCooldownTimer[i] = INVALID_HANDLE;
		}
	}
}

public SetClientUpgradesCheck(client)
{
	if(SetClientUpgrades[client] != INVALID_HANDLE)
	{
		CloseHandle(SetClientUpgrades[client]);
		SetClientUpgrades[client] = INVALID_HANDLE;
	}

	if(SetClientUpgrades[client] == INVALID_HANDLE)
	{
		SetClientUpgrades[client] = CreateTimer(UPGRADE_LOAD_TIME, SetSurvivorUpgrades, client);
	}
	
}

public event_PlayerSpawn(Handle:event, const String:name[], bool:Broadcast) 
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(client > 0 && IsClientInGame(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client))
	{
		SetClientUpgradesCheck(client);
	}
}

public event_PlayerDeath(Handle:event, const String:name[], bool:Broadcast) 
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new entityid = GetEventInt(event, "entityid");
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new bool:headshot = GetEventBool(event, "headshot");

	if(client > 0 && IsClientInGame(client) && GetClientTeam(client) == 3)
		return;

	// 0 - Disabled
	if(GetConVarInt(AwardIndex[0]) == 0)
	{
		return;
	}
	if(GetConVarInt(g_PerkMode) == 0)
	{
		// 1 - Bots Only
		if(client > 0 && GetConVarInt(AwardIndex[0]) == 1 && IsFakeClient(client) && GetClientTeam(client) == 2)
			RemoveSurvivorUpgrade(client, GetConVarInt(penalty_upgrades), 0);
		// 2 - Humans Only
		if(client > 0 && GetConVarInt(AwardIndex[0]) == 2 && !IsFakeClient(client) && GetClientTeam(client) == 2)
			RemoveSurvivorUpgrade(client, GetConVarInt(penalty_upgrades), 0);
		// 3 - All Players
		if(client > 0 && GetConVarInt(AwardIndex[0]) == 3 && GetClientTeam(client) == 2)
			RemoveSurvivorUpgrade(client, GetConVarInt(penalty_upgrades), 0);
	}
	if(iLargePainPills[client] == 1)
	{
		GivePlayerItem(client, "weapon_pain_pills");
		iLargePainPills[client] = 0;
	}
	if(iLargeFirstAidKit[client] == 1)
	{
		GivePlayerItem(client, "weapon_first_aid_kit");
		iLargeFirstAidKit[client] = 0;
	}
	if(headshot == true && entityid > 0)
	{
		UpgradeOcularImplants(attacker, entityid);
	}
}

public event_PlayerTeam(Handle:event, const String:name[], bool:Broadcast) 
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new team  = GetEventInt(event, "team");

	if(client > 0 && IsClientInGame(client) && team == 1)
	{
		if(iLargePainPills[client] == 1)
		{
			iLargePainPills[client] = 0;
		}
		if(iLargeFirstAidKit[client] == 1)
		{
			iLargeFirstAidKit[client] = 0;
		}
	}
}

public event_Rescued(Handle:event, const String:name[], bool:dontBroadcast) 
{
	new client = GetClientOfUserId(GetEventInt(event,"victim"));
	if(client > 0 && IsClientInGame(client) && !IsClientObserver(client) && GetClientTeam(client) == 2)
	{
		SetClientUpgradesCheck(client);
	}
}

public event_BotReplacedPlayer(Handle:event, const String:name[], bool:dontBroadcast) 
{
	new bot = GetClientOfUserId(GetEventInt(event,"bot"));

	if(bot > 0 && IsClientInGame(bot) && !IsClientObserver(bot) && GetClientTeam(bot) == 2)
	{
		SetClientUpgradesCheck(bot);
	}
}

public event_PlayerReplacedBot(Handle:event, const String:name[], bool:dontBroadcast) 
{
	new client = GetClientOfUserId(GetEventInt(event,"player"));

	if(client > 0 && IsClientInGame(client) && !IsClientObserver(client) && GetClientTeam(client) == 2)
	{		
		SetClientUpgradesCheck(client);
	}
}

public Action:SetSurvivorUpgrades(Handle:timer, any:client)
{
	SetClientUpgrades[client] = INVALID_HANDLE;
	if(b_round_end == true)
	{
		return;
	}
	if(client > 0 && IsClientInGame(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client) && !HasIdlePlayer(client))
	{
		if(IsFakeClient(client) && iUpgradeDisabled[client][18] != 1)
		{
			if(iUpgrade[client][18] > 0)
			{
				iUpgrade[client][18] = 0;
			}
			iUpgradeDisabled[client][18] = 1;
		}

		iBitsUpgrades[client] = SetUpgradeBitVec(client);
		if(GetEntProp(client, Prop_Send, "m_upgradeBitVec") != iBitsUpgrades[client])
		{
			SetEntProp(client, Prop_Send, "m_upgradeBitVec", iBitsUpgrades[client]);
		}
		if(iUpgrade[client][36] > 0 || iUpgrade[client][37] > 0 || iUpgrade[client][42] > 0)
		{
			new iMaxHealth = 0;
			if(iUpgrade[client][36] > 0)
				iMaxHealth += 50;
			if(iUpgrade[client][37] > 0)
				iMaxHealth += 50;
			if(iUpgrade[client][42] > 0)
				iMaxHealth += 50;

			SetEntProp(client, Prop_Send, "m_iMaxHealth", 100 + iMaxHealth);
		}
		else
		{
			SetEntProp(client, Prop_Send, "m_iMaxHealth", 100);
		}
		if(iUpgrade[client][22] > 0)
		{
			SetEntProp(client, Prop_Send, "m_bNightVisionOn", 1, 4);
			SetEntProp(client, Prop_Send, "m_bHasNightVision", 1, 4);

		}
		else
		{
			SetEntProp(client, Prop_Send, "m_bNightVisionOn", 0, 4);
			SetEntProp(client, Prop_Send, "m_bHasNightVision", 0, 4);
		}
		if(iUpgrade[client][0] > 0 && iLargePainPills[client] == 2)
		{
			UpgradeLargePainPills(client);
			iLargePainPills[client] = 1;
		}
		if(iUpgrade[client][10] > 0 && iLargeFirstAidKit[client] == 2)
		{
			UpgradeLargeFirstAidKit(client);
			iLargeFirstAidKit[client] = 1;
		}
		if(iUpgrade[client][31] > 0 && iGrenadePouch[client] == 2)
		{
			UpgradeGrenadePouch(client, "random");
			iGrenadePouch[client] = 1;
		}
		else if(iUpgrade[client][31] > 0 && iGrenadePouch[client] == 1)
		{
			iGrenadePouch[client] = 1;
		}
		else
		{
			iGrenadePouch[client] = 0;
		}
		if(iUpgrade[client][41] > 0)
		{
			UpgradeCasingDispenser(client);
		}
	}
	if(IsClientInGame(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client) && GetSurvivorUpgrades(client) > 0)
	{
		EmitSoundToClient(client, "player/orch_hit_Csharp_short.wav");
	}
}

public event_ItemPickup(Handle:event, const String:name[], bool:Broadcast) 
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new String:iWeaponName[32];
	GetEventString(event, "item", iWeaponName, 32);
	
	if(StrContains(iWeaponName, "smg", false) != -1 || StrContains(iWeaponName, "rifle", false) != -1 || StrContains(iWeaponName, "shotgun", false) != -1)
	{
		GivePlayerAmmoX(client);
	}
	if(iUpgrade[client][31] > 0)
	{
		if(StrContains(iWeaponName, "molotov", false) != -1 || StrContains(iWeaponName, "pipe_bomb", false) != -1 )
		{
			iGrenadePouch[client] = 1;
			UpgradeGrenadePouch(client, iWeaponName);
		}
	}
}
public event_AmmoPickup(Handle:event, const String:name[], bool:Broadcast) 
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	GivePlayerAmmoX(client);
}

public Action:event_PlayerUse(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	decl String:item[64];
	new targetid = GetEventInt(event, "targetid");
	GetEdictClassname(targetid, item, sizeof(item));

	if(StrContains(item, "ammo", false) != -1)
	{
		ClearPlayerAmmo(client);
		CheatCommand(client, "give", "ammo", "");
		GivePlayerAmmoX(client);
	}
	
	if(iUpgrade[client][0] > 0 && GetPlayerWeaponSlot(client, 4) > 0 && iLargePainPills[client] == 0)
	{
		if(StrContains(item, "pain_pills", false) != -1)
		{
			if(StrContains(item, "_spawn", false) != -1 && GetEntProp(targetid, Prop_Data, "m_itemCount") > 0)
			{
				PrintToChat(client, "You picked up an Extra Pain Pills.");
				AcceptEntityInput(targetid, "kill");
				SetEntProp(targetid, Prop_Data, "m_itemCount", 0);
				new newitem = GivePlayerItem(client, "weapon_pain_pills");
				EquipPlayerWeapon(client, newitem);
				iLargePainPills[client] = 1;
			}
			else if(StrContains(item, "_spawn", false) == -1 && GetEntPropEnt(targetid, Prop_Data, "m_hOwner") != client)
			{
				PrintToChat(client, "You picked up an Extra Pain Pills.");
				EquipPlayerWeapon(client, targetid);
				iLargePainPills[client] = 1;
			}
		}
	}
	if(iUpgrade[client][10] > 0 && GetPlayerWeaponSlot(client, 3) > 0 && iLargeFirstAidKit[client] == 0)
	{
		if(StrContains(item, "first_aid_kit", false) != -1)
		{
			if(StrContains(item, "_spawn", false) != -1 && GetEntProp(targetid, Prop_Data, "m_itemCount") > 0)
			{
				PrintToChat(client, "You picked up an Extra First Aid Kit.");
				AcceptEntityInput(targetid, "kill");
				SetEntProp(targetid, Prop_Data, "m_itemCount", 0);
				new newitem = GivePlayerItem(client, "weapon_first_aid_kit");
				EquipPlayerWeapon(client, newitem);
				iLargeFirstAidKit[client] = 1;
			}
			else if(StrContains(item, "_spawn", false) == -1 && GetEntPropEnt(targetid, Prop_Data, "m_hOwner") != client)
			{
				PrintToChat(client, "You picked up an Extra First Aid Kit.");
				EquipPlayerWeapon(client, targetid);
				iLargeFirstAidKit[client] = 1;
			}
		}
	}
}

GivePlayerAmmoX(client)
{
	new m_iAmmo = FindDataMapOffs(client, "m_iAmmo");
	new iWEAPON = GetPlayerWeaponSlot(client, 0);

	if(iWEAPON > 0)
	{
		new String:iWeaponName[32];
		GetEdictClassname(iWEAPON, iWeaponName, 32);

		if(iUpgrade[client][7] > 0)
		{
			if(StrContains(iWeaponName, "smg", false) != -1 || StrContains(iWeaponName, "rifle", false) != -1 || StrContains(iWeaponName, "shotgun", false) != -1 || StrContains(iWeaponName, "sniper", false) != -1)
			{
				SetEntData(client, m_iAmmo+HUNTING_RIFLE_OFFSET_AMMO, RoundToNearest((GetConVarInt(FindConVar("ammo_huntingrifle_max")) * 1.5)) + (CheckWeaponUpgradeLimit(iWEAPON, client) - GetEntProp(iWEAPON, Prop_Send, "m_iClip1")));
				SetEntData(client, m_iAmmo+RIFLE_OFFSET_AMMO, RoundToNearest((GetConVarInt(FindConVar("ammo_assaultrifle_max")) * 1.5)) + (CheckWeaponUpgradeLimit(iWEAPON, client) - GetEntProp(iWEAPON, Prop_Send, "m_iClip1")));
				SetEntData(client, m_iAmmo+SMG_OFFSET_AMMO, RoundToNearest((GetConVarInt(FindConVar("ammo_smg_max")) * 1.5)) + (CheckWeaponUpgradeLimit(iWEAPON, client) - GetEntProp(iWEAPON, Prop_Send, "m_iClip1")));
				SetEntData(client, m_iAmmo+SHOTGUN_OFFSET_AMMO, RoundToNearest((GetConVarInt(FindConVar("ammo_buckshot_max")) * 1.5)) + (CheckWeaponUpgradeLimit(iWEAPON, client) - GetEntProp(iWEAPON, Prop_Send, "m_iClip1")));
			}
		}
		else
		{
			SetEntData(client, m_iAmmo+HUNTING_RIFLE_OFFSET_AMMO, GetConVarInt(FindConVar("ammo_huntingrifle_max")) + (CheckWeaponUpgradeLimit(iWEAPON, client) - GetEntProp(iWEAPON, Prop_Send, "m_iClip1")));
			SetEntData(client, m_iAmmo+RIFLE_OFFSET_AMMO, GetConVarInt(FindConVar("ammo_assaultrifle_max")) + (CheckWeaponUpgradeLimit(iWEAPON, client) - GetEntProp(iWEAPON, Prop_Send, "m_iClip1")));
			SetEntData(client, m_iAmmo+SMG_OFFSET_AMMO, GetConVarInt(FindConVar("ammo_smg_max")) + (CheckWeaponUpgradeLimit(iWEAPON, client) - GetEntProp(iWEAPON, Prop_Send, "m_iClip1")));
			SetEntData(client, m_iAmmo+SHOTGUN_OFFSET_AMMO, GetConVarInt(FindConVar("ammo_buckshot_max")) + (CheckWeaponUpgradeLimit(iWEAPON, client) - GetEntProp(iWEAPON, Prop_Send, "m_iClip1")));
		}
	}
}

ClearPlayerAmmo(client)
{
	new m_iAmmo = FindDataMapOffs(client, "m_iAmmo");
	SetEntData(client, m_iAmmo+HUNTING_RIFLE_OFFSET_AMMO, 0);
	SetEntData(client, m_iAmmo+RIFLE_OFFSET_AMMO, 0);
	SetEntData(client, m_iAmmo+SMG_OFFSET_AMMO, 0);
	SetEntData(client, m_iAmmo+SHOTGUN_OFFSET_AMMO, 0);
}

CheckWeaponUpgradeLimit(weapon, client)
{
	new UpgradeLimit = 0;
	decl String:WEAPON_NAME[64];
	GetEdictClassname(weapon, WEAPON_NAME, 32);

	if(StrEqual(WEAPON_NAME, "weapon_rifle") || StrEqual(WEAPON_NAME, "weapon_smg"))
	{
		UpgradeLimit = 50;
	}
	else if(StrEqual(WEAPON_NAME, "weapon_pumpshotgun"))
	{
		UpgradeLimit = 8;
	}
	else if(StrEqual(WEAPON_NAME, "weapon_autoshotgun"))
	{
		UpgradeLimit = 10;
	}
	else if(StrEqual(WEAPON_NAME, "weapon_hunting_rifle"))
	{
		UpgradeLimit = 15;
	}
	if(iUpgrade[client][20] > 0)
	{
		UpgradeLimit = RoundFloat(UpgradeLimit * 1.5);
	}
	return UpgradeLimit;
}

public GiveSurvivorUpgrade(client, amount, awardid)
{
	if (GetClientTeam(client) != 2)
		return;
	
	for(new num = 0; num < amount; num++)
	{
		decl String:ClientUserName[MAX_NAME_LENGTH];
		GetClientName(client, ClientUserName, sizeof(ClientUserName));

		new numOwned = GetSurvivorUpgrades(client);
		if(numOwned == GetEnabledUpgrades() || numOwned == GetAvailableUpgrades(client))
		{
			for(new i = 1; i <= MaxClients; i++)
			{
				if(IsClientInGame(i) && iAnnounceText[i] == 1)
					PrintToChat(i, "\x04%s \x01has earned the %s.", ClientUserName, AwardTitle[awardid]);
			}
			return;
		}
		new offset = GetRandomInt(0,MAX_UPGRADES-(GetAbSurvivorUpgrades(client)+1));
		new val = 0;
		while(offset > 0 || iUpgrade[client][val] || GetConVarInt(UpgradeEnabled[val]) != 1 || iUpgradeDisabled[client][val] != 0)
		{
			if((!iUpgrade[client][val]) && GetConVarInt(UpgradeEnabled[val]) == 1 || iUpgradeDisabled[client][val] == 1)
			{
				offset--;
			}
			val++;
			//PrintToChatAll("Offset: %d, UpgradeID: %d", offset, val);
		}

		if(client > 0 && IsPlayerAlive(client))
		{
			GiveUpgrade(client, val);
			for(new i = 1; i <= MaxClients; i++)
			{
				if(IsClientInGame(i) && iAnnounceText[i] == 1)
					PrintToChat(i, "\x04%s \x01earned %s from %s.", ClientUserName, UpgradeShort[val], AwardTitle[awardid]);
			}
		}
	}
}

public RemoveSurvivorUpgrade(client, amount, awardid)
{
	for(new num = 0; num < amount; num++)
	{
		decl String:ClientUserName[MAX_NAME_LENGTH];
		GetClientName(client, ClientUserName, sizeof(ClientUserName));

		new numMiss = MissingSurvivorUpgrades(client);
		if(numMiss == MAX_UPGRADES)
		{
			for(new i = 1; i <= MaxClients; i++)
			{
				if(IsClientInGame(i) && iAnnounceText[i] == 1)
					PrintToChat(i, "\x04%s \x01lost all upgrades.", ClientUserName);
			}
			return;
		}
		new offset = GetRandomInt(0,MAX_UPGRADES-(numMiss+1));
		new val = 0;
		while(offset > 0 || !iUpgrade[client][val])
		{
			if((iUpgrade[client][val]))
			{
				offset--;
			}
			val++;
		}
		RemoveUpgrade(client, val);
		for (new i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i) && iAnnounceText[i] == 1)
				PrintToChat(i, "\x04%s \x01lost %s from %s.", ClientUserName, UpgradeShort[val], AwardTitle[awardid]);
		}
	}
}

public GiveUpgrade(client, upgrade)
{
	for(new i = 0; i < MAX_UPGRADES; i++)
	{
		if(i == upgrade && iUpgrade[client][upgrade] != UpgradeIndex[upgrade])
		{
			iUpgrade[client][upgrade] = UpgradeIndex[upgrade];
			SetClientUpgradesCheck(client);
		}
	}
}

public RemoveUpgrade(client, upgrade)
{
	for(new i = 0; i < MAX_UPGRADES; i++)
	{
		if(i == upgrade)
		{
			iUpgrade[client][upgrade] = 0;
			//iBitsUpgrades[client] -= UpgradeIndex[upgrade];
			SetClientUpgradesCheck(client);
		}
	}
}

public GetEnabledUpgrades()
{
	new upgrades = 0;
	for(new i = 0; i < MAX_UPGRADES; i++)
	{
		if(GetConVarInt(UpgradeEnabled[i]) > 0)
		{
			upgrades++;
		}
	}
	return upgrades;
}

public GetAvailableUpgrades(client)
{
	new upgrades = 0;
	for(new i = 0; i < MAX_UPGRADES; i++)
	{
		if(iUpgradeDisabled[client][i] == 0 && GetConVarInt(UpgradeEnabled[i]) == 1)
		{
			upgrades++;
		}
	}
	return upgrades;
}

public GetSurvivorUpgrades(client)
{
	new upgrades = 0;
	for(new i = 0; i < MAX_UPGRADES; i++)
	{
		if(iUpgrade[client][i] > 0)
		{
			upgrades++;
		}
	}
	return upgrades;
}

public GetAbSurvivorUpgrades(client)
{
	new upgrades = 0;
	for(new i = 0; i < MAX_UPGRADES; i++)
	{
		if(iUpgrade[client][i] > 0 || iUpgradeDisabled[client][i] == 1)
		{
			upgrades++;
		}
	}
	return upgrades;
}

public SetUpgradeBitVec(client)
{
	new upgradeBitVec = 0;
	for(new i = 0; i < 31; i++)
	{
		if(iUpgrade[client][i] > 0 && iUpgradeDisabled[client][i] != 1)
		{
			upgradeBitVec += iUpgrade[client][i];
		}
	}
	return upgradeBitVec;
}

public ResetClientUpgrades(client)
{
	for(new i = 0; i < MAX_UPGRADES; i++)
	{
		iUpgrade[client][i] = 0;
	}
	iBitsUpgrades[client] = 0;
	SetClientUpgrades[client] = CreateTimer(UPGRADE_LOAD_TIME, SetSurvivorUpgrades, client);
}

public MissingSurvivorUpgrades(client)
{
	new upgrades = 0;
	for(new i = 0; i < MAX_UPGRADES; i++)
	{
		if(iUpgrade[client][i] <= 0)
		{
			upgrades++;
		}
	}
	return upgrades;
}

public Action:PrintToChatUpgrades(client, args)
{
	DisplayUpgradeMenu(client);
	return Plugin_Handled;
}

public Action:UpgradeLaserSightToggle(client, args)
{
	if(GetClientTeam(client) == 2)
	{
		if(iUpgrade[client][17] == 0 && GetConVarInt(UpgradeEnabled[17]) == 1 && iUpgradeDisabled[client][17] != 1)
		{
			PrintToChat(client, "\x01Laser Sight is \x04On\x01.");
			GiveUpgrade(client, 17);
		}
		else if(iUpgrade[client][17] > 0)
		{
			PrintToChat(client, "\x01Laser Sight is \x04Off\x01.");
			RemoveUpgrade(client, 17);
		}
		else if(iUpgradeDisabled[client][17] == 1)
		{
			PrintToChat(client, "\x01Laser Sight is \x04Disabled\x01. Please \x04Enable \x01Laser Sight before using the command.");
		}
	}
	else
	{
		PrintToChat(client, "\x01You must be on the \x04Survivor Team\x01.");
	}
}

public Action:OpenPerkMenu(client, args)
{
	if(GetConVarInt(g_PerkMode) == 1)
		PerkMenu(client);
	else
		PrintToChat(client, "Perk Mode is not enabled.");
		
}

public DisplayUpgradeMenu(client)
{
	if(GetClientTeam(client) == 2)
	{
		new Handle:UpgradePanel = CreatePanel();

		decl String:buffer[MAX_TARGET_LENGTH];
		if(GetConVarInt(g_PerkMode) == 1)
			Format(buffer, sizeof(buffer), "Survivor Upgrades (%d/%d)", GetSurvivorUpgrades(client), GetConVarInt(PerkSlots) + iPerkBonusSlots[client]);
		else
			Format(buffer, sizeof(buffer), "Survivor Upgrades (%d/%d)", GetSurvivorUpgrades(client), GetAvailableUpgrades(client));
		SetPanelTitle(UpgradePanel, buffer);
		
		new percentage = 0;
		for(new i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i) && GetClientTeam(i) == 2)
			{
				new String:text[MAX_TARGET_LENGTH];
				if(GetConVarInt(g_PerkMode) == 1)
				{
					percentage = GetSurvivorUpgrades(i);
				}
				else
				{
					percentage = RoundFloat((float(GetSurvivorUpgrades(i)) / GetAvailableUpgrades(i)) * 100);
				}
				decl String:ClientUserName[MAX_TARGET_LENGTH];
				GetClientName(i, ClientUserName, sizeof(ClientUserName));
				ReplaceString(ClientUserName, sizeof(ClientUserName), "[", "");

				if(GetConVarInt(g_PerkMode) == 1)
				{
					Format(text, sizeof(text), "%s (%d/%d)", ClientUserName, percentage, GetConVarInt(PerkSlots) + iPerkBonusSlots[i]);
				}
				else
				{
					Format(text, sizeof(text), "%s (%d%%)", ClientUserName, percentage);
				}
				DrawPanelText(UpgradePanel, text);
			}
		}
		
		DrawPanelItem(UpgradePanel, "Display Upgrades");
		if(GetConVarInt(g_PerkMode) == 1)
			DrawPanelItem(UpgradePanel, "Equip Perk");
		DrawPanelItem(UpgradePanel, "Options");
		DrawPanelItem(UpgradePanel, "Help");
		
		SendPanelToClient(UpgradePanel, client, UpgradeMenuHandler, 30);
		CloseHandle(UpgradePanel);
	}
	else
	{
		PrintToChat(client, "\x01[\x03ERROR\x01] An Error occurred, please contact developer.");
	}
}

public UpgradeMenuHandler(Handle:UpgradePanel, MenuAction:action, param1, param2)
{
	new client = param1;
	if (action == MenuAction_Select)
	{
		if(param2 == 1)
		{
			for(new upgrade = 0; upgrade < UPGRADEID + 1; upgrade++)
			{
				if(iUpgrade[client][upgrade] > 0)
				{
					PrintToChat(client, "%s", UpgradeTitle[upgrade]);
				}
			}
		}
		else if(param2 == 2)
		{
			if(GetConVarInt(g_PerkMode) == 1)
			{
				PerkMenu(client);
			}
			else
			{
				OptionsMenu(client);
			}
		}
		else if(param2 == 3)
		{
			if(GetConVarInt(g_PerkMode) == 1)
			{
				OptionsMenu(client);
			}
			else
			{
				HelpMenu(client);
			}
		}
		else if(param2 == 4)
		{
			if(GetConVarInt(g_PerkMode) == 1)
			{
				HelpMenu(client);
			}
			else
			{
				// Nothing
			}
		}
	}
	else if(action == MenuAction_Cancel)
	{
		// Nothing
	}
}

public OptionsMenu(client)
{
	new Handle:PanelMenu = CreatePanel();

	decl String:buffer[MAX_TARGET_LENGTH];
	Format(buffer, sizeof(buffer), "Options");
	SetPanelTitle(PanelMenu, buffer);
	
	DrawPanelText(PanelMenu, "You can change configurations in \nthis menu by selecting options for your \ngameplay experience.");
	decl String:notification[64];
	decl String:status[16];
	decl String:savefeature[32];
	decl String:savestatus[8];
	if(iSaveFeature[client] == 0)
	{
		Format(savestatus, sizeof(savestatus), "Off");
	}
	else
	{
		Format(savestatus, sizeof(savestatus), "On");
	}
	if(iAnnounceText[client] == 0)
	{
		Format(status, sizeof(status), "Disabled");
	}
	else
	{
		Format(status, sizeof(status), "Enabled");
	}
	Format(savefeature, sizeof(savefeature), "Save Feature (%s)", savestatus);
	Format(notification, sizeof(notification), "Notifications (%s)", status);
	DrawPanelItem(PanelMenu, savefeature);
	DrawPanelItem(PanelMenu, notification);
	DrawPanelItem(PanelMenu, "Toggle Upgrades");
	DrawPanelItem(PanelMenu, "View Awards");
	if(GetConVarInt(g_PerkMode) == 1)
		DrawPanelItem(PanelMenu, "Give Player Perks");
	DrawPanelItem(PanelMenu, "Reset Upgrades");
	DrawPanelItem(PanelMenu, "Reset Bots");
	
	SendPanelToClient(PanelMenu, client, OptionsMenuHandler, 30);
	CloseHandle(PanelMenu);
}

public OptionsMenuHandler(Handle:UpgradePanel, MenuAction:action, param1, param2)
{
	new client = param1;
	if (action == MenuAction_Select)
	{
		if(param2 == 1)
		{
			if(iSaveFeature[client] != 1)
			{
				iSaveFeature[client] = 1;
				PrintToChat(client, "\x01Save Feature is \x04On\x01.");
			}
			else
			{
				iSaveFeature[client] = 0;
				PrintToChat(client, "\x01Save Feature is \x04Off\x01.");
			}
		}
		if(param2 == 2)
		{
			if(iAnnounceText[client] != 1)
			{
				iAnnounceText[client] = 1;
				PrintToChat(client, "\x01Announcement Text \x04On\x01.");
			}
			else
			{
				iAnnounceText[client] = 0;
				PrintToChat(client, "\x01Announcement Text \x04Off\x01.");
			}
		}
		else if(param2 == 3)
		{
			UpgradesEnabledMenu(client);
		}
		else if(param2 == 4)
		{
			AwardStatusMenu(client);
			RefreshRewards[client] = 1;
		}
		else if(param2 == 5)
		{
			if(GetConVarInt(g_PerkMode) == 1)
			{
				SelectBotMenu(client);
			}
			else
			{
				ResetClientUpgrades(client);
				PrintToChat(client, "\x01Upgrades \x04Reset\x01.");
			}
		}
		else if(param2 == 6)
		{
			if(GetConVarInt(g_PerkMode) == 1)
			{
				ResetClientUpgrades(client);
				GiveSurvivorUpgrade(client, GetConVarInt(PerkSlots), 0);
			}
			else
			{
				for(new i = 1; i < MaxClients; i++)
				{
					if(IsClientInGame(i) && GetClientTeam(i) == 2 && IsFakeClient(i))
					{
						ResetClientUpgrades(i);
					}
				}
				PrintToChat(client, "\x01Bots have been \x04Reset\x01.");
			}
		}
		else if(param2 == 7)
		{
			if(GetConVarInt(g_PerkMode) == 1)
			{
				for(new i = 1; i < MaxClients; i++)
				{
					if(IsClientInGame(i) && GetClientTeam(i) == 2 && IsFakeClient(i))
					{
						ResetClientUpgrades(i);
					}
				}
				PrintToChat(client, "\x01Bots have been \x04Reset\x01.");
			}
			else
			{
				ResetClientUpgrades(client);
				PrintToChat(client, "\x01Upgrades \x04Reset\x01.");
			}
		}
	}
	else if(action == MenuAction_Cancel)
	{
		// Nothing
	}
}

public SelectBotMenu(client)
{	
	new Handle:menu = CreateMenu(SelectBotMenuHandler);
	decl String:name[MAX_NAME_LENGTH], String:number[10];
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (i > 0 && IsClientInGame(i) && GetClientTeam(i) == 2)
		{
			if(!CheckCommandAccess(client, "sm_admin", ADMFLAG_KICK) && !IsFakeClient(i))
				continue;
			Format(name, sizeof(name), "%N (%d/%d)", i, GetSurvivorUpgrades(i), GetConVarInt(PerkSlots) + iPerkBonusSlots[i]);
			Format(number, sizeof(number), "%i", i);
			AddMenuItem(menu, number, name);
		}
    }
	SetMenuTitle(menu, "Select Bot\nYou can select a bot to change their \nperks from this menu.");
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public SelectBotMenuHandler(Handle:menu, MenuAction:action, param1, param2)
{
	new client = param1;
	switch(action)
	{
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
		case MenuAction_Cancel:
		{
			if(param2 == MenuCancel_ExitBack)
			{
				UpgradesEnabledMenu(client);
			}
		}
		case MenuAction_Select:
		{
			new String:item1[8];
			GetMenuItem(menu, param2, item1, sizeof(item1));          
			g_iSelectedClient = StringToInt(item1);
			BotPerkMenu(client); 
		}
	}
}

public BotPerkMenu(client)
{	
	new Handle:menu = CreateMenu(BotPerkMenuHandler);
	
	new slot = 1;
	decl String:buffer[32];		
	for(new upgrade = 0; upgrade < UPGRADEID + 1; upgrade++)
	{
		if(iUpgrade[g_iSelectedClient][upgrade] > 0 && slot <= GetConVarInt(PerkSlots) + iPerkBonusSlots[g_iSelectedClient])
		{
			Format(buffer, sizeof(buffer), "%s", PerkTitle[upgrade]);
			AddMenuItem(menu, buffer, buffer);
			slot++;
		}
	}
	while(slot <= GetConVarInt(PerkSlots) + GetConVarInt(PerkBonusSlots))
	{
		if(slot <= GetConVarInt(PerkSlots) + iPerkBonusSlots[g_iSelectedClient])
		{
			AddMenuItem(menu, "<EMPTY>", "<EMPTY>");
			slot++;
		}
		else
		{
			AddMenuItem(menu, "<LOCKED>", "<LOCKED>", ITEMDRAW_DISABLED);
			slot++;
		}
	}
	AddMenuItem(menu, "SetAllBots", "Set All Bots");
	AddMenuItem(menu, "Randomize", "Randomize");
	AddMenuItem(menu, "Assault", "Assault Support");
	AddMenuItem(menu, "Medic", "Medic Support");
	AddMenuItem(menu, "Tank", "Tank Support");
	SetMenuTitle(menu, "Equip Perks (BOT)\nYou can select perks in this menu \nby choosing which slot to equip with.");
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public BotPerkMenuHandler(Handle:menu, MenuAction:action, param1, param2)
{
	new client = param1;
	switch(action)
	{
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
		case MenuAction_Cancel:
		{
			if(param2 == MenuCancel_ExitBack)
			{
				UpgradesEnabledMenu(param1);
			}
		}
		case MenuAction_Select:
		{
			new String:item1[56];
			GetMenuItem(menu, param2, item1, sizeof(item1));
			if(StrEqual(item1, "<EMPTY>", false))
			{
				BotPerkSelectionMenu(client);
			}
			for(new i = 0; i < MAX_UPGRADES; i++)
			{
				if(StrEqual(item1, PerkTitle[i], false))
				{
					if(iUpgrade[g_iSelectedClient][i] > 0)
					{
						iUpgrade[g_iSelectedClient][i] = 0;
						BotPerkSelectionMenu(client);
					}					
				}
			}
			if(StrEqual(item1, "SetAllBots", false))
			{
				for(new i = 0; i <= MaxClients; i++)
				{
					if (i > 0 && IsClientInGame(i) && IsFakeClient(i) && GetClientTeam(i) == 2)
					{
						for(new j = 0; j < MAX_UPGRADES; j++)
						{
							iUpgrade[i][j] = iUpgrade[g_iSelectedClient][j];						
						}
						if(iSaveFeature[i] == 0)
							iSaveFeature[i] = 1;						
					}
				}
			}
			if(StrEqual(item1, "Randomize", false))
			{
				ResetClientUpgrades(g_iSelectedClient);
				GiveSurvivorUpgrade(g_iSelectedClient, GetConVarInt(PerkSlots) + iPerkBonusSlots[g_iSelectedClient], 0);
				iSaveFeature[g_iSelectedClient] = 1;
			}
			if(StrEqual(item1, "Assault", false))
			{
				new assaultUpgrades[8] = { 1, 5, 12, 17, 20, 21, 29, 38 };
				ResetClientUpgrades(g_iSelectedClient);
				for(new j = 0; j < GetConVarInt(PerkSlots) + iPerkBonusSlots[g_iSelectedClient]; j++)
				{
					GiveUpgrade(g_iSelectedClient, assaultUpgrades[j]);
				}
				iSaveFeature[g_iSelectedClient] = 1;
			}
			if(StrEqual(item1, "Medic", false))
			{
				new medicUpgrades[8] = { 2, 5, 10, 14, 16, 27, 30, 43 };
				ResetClientUpgrades(g_iSelectedClient);
				for(new j = 0; j < GetConVarInt(PerkSlots) + iPerkBonusSlots[g_iSelectedClient]; j++)
				{
					GiveUpgrade(g_iSelectedClient, medicUpgrades[j]);
				}
				iSaveFeature[g_iSelectedClient] = 1;
			}
			if(StrEqual(item1, "Tank", false))
			{
				new tankUpgrades[8] = { 1, 2, 5, 14, 28, 36, 37, 42 };
				ResetClientUpgrades(g_iSelectedClient);
				for(new j = 0; j < GetConVarInt(PerkSlots) + iPerkBonusSlots[g_iSelectedClient]; j++)
				{
					GiveUpgrade(g_iSelectedClient, tankUpgrades[j]);
				}
				iSaveFeature[g_iSelectedClient] = 1;
			}
		}
	}
}

public BotPerkSelectionMenu(client)
{	
	new Handle:menu = CreateMenu(BotPerkSelectionHandler);
	
	SetMenuTitle(menu, "Select A Perk (BOT)\n\nYou can choose the perk that you \nwant to equip in the slots");
	for(new upgrade = 0; upgrade < MAX_UPGRADES; upgrade++)
	{
		if(iUpgrade[g_iSelectedClient][upgrade] == 0)
		{
			decl String:buffer[32];
			Format(buffer, sizeof(buffer), "%s", PerkTitle[upgrade]);

			AddMenuItem(menu, buffer, buffer);
		}
	}
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public BotPerkSelectionHandler(Handle:menu, MenuAction:action, param1, param2)
{
	new client = param1;
	switch(action)
	{
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
		case MenuAction_Cancel:
		{
			if(param2 == MenuCancel_ExitBack)
			{
				BotPerkMenu(client);
			}
		}
		case MenuAction_Select:
		{
			new String:item1[56];
			GetMenuItem(menu, param2, item1, sizeof(item1));
			for(new i = 0; i <= MAX_UPGRADES; i++)
			{
				if(StrEqual(item1, PerkTitle[i], false))
				{
					iUpgrade[g_iSelectedClient][i] = UpgradeIndex[i];
					PrintToChat(client, "%s", UpgradeTitle[i]);
					BotPerkMenu(client);
					if(iSaveFeature[g_iSelectedClient] == 0)
						iSaveFeature[g_iSelectedClient] = 1;
				}
			}
		}
	}
}

public HelpMenu(client)
{
	new Handle:PanelMenu = CreatePanel();

	SetPanelTitle(PanelMenu, "Help");
	if(GetConVarInt(g_PerkMode) == 1)
		DrawPanelText(PanelMenu, "Current Mode: Perk Mode\n\nIn perk mode, each player must select \n the amount of perks they can use \ninstead of earning them from rewards.");
	else
		DrawPanelText(PanelMenu, "Current Mode: Upgrades Mode\n\nSurvivor Upgrades is a feature in \nLeft 4 Dead where survivors obtain \nenhancements to their current gameplay. \nYou earn upgrades by positive actions, \nand lose by negative actions.");
	SendPanelToClient(PanelMenu, client, HelpMenuHandler, 30);
	CloseHandle(PanelMenu);
}

public HelpMenuHandler(Handle:UpgradePanel, MenuAction:action, param1, param2)
{
	//new client = param1;
	if (action == MenuAction_Select)
	{

	}
}

public PerkMenu(client)
{	
	new Handle:menu = CreateMenu(PerkMenuHandler);
	
	new slot = 1;
	decl String:buffer[32];

	for(new upgrade = 0; upgrade < UPGRADEID + 1; upgrade++)
	{
		if(iUpgrade[client][upgrade] > 0 && slot <= GetConVarInt(PerkSlots) + iPerkBonusSlots[client])
		{
			Format(buffer, sizeof(buffer), "%s", PerkTitle[upgrade]);
			AddMenuItem(menu, buffer, buffer);
			slot++;
		}
	}
	while(slot <= GetConVarInt(PerkSlots) + GetConVarInt(PerkBonusSlots))
	{
		if(slot <= GetConVarInt(PerkSlots) + iPerkBonusSlots[client])
		{
			AddMenuItem(menu, "<EMPTY>", "<EMPTY>");
			slot++;
		}
		else
		{
			AddMenuItem(menu, "<LOCKED>", "<LOCKED>", ITEMDRAW_DISABLED);
			slot++;
		}
	}
	SetMenuTitle(menu, "Equip Perks\nYou can select perks in this menu \nby choosing which slot to equip with.");
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public PerkMenuHandler(Handle:menu, MenuAction:action, param1, param2)
{
	new client = param1;
	switch(action)
	{
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
		case MenuAction_Cancel:
		{
			if(param2 == MenuCancel_ExitBack)
			{
				UpgradesEnabledMenu(param1);
			}
		}
		case MenuAction_Select:
		{
			new String:item1[56];
			GetMenuItem(menu, param2, item1, sizeof(item1));
			if(StrEqual(item1, "<EMPTY>", false))
			{
				PerkSelectionMenu(client);
			}
			for(new i = 0; i < MAX_UPGRADES; i++)
			{
				if(StrEqual(item1, PerkTitle[i], false))
				{
					if(iUpgrade[client][i] > 0)
					{
						iUpgrade[client][i] = 0;
						PerkSelectionMenu(client);
					}					
				}
			}
		}
	}
}

public PerkSelectionMenu(client)
{	
	new Handle:menu = CreateMenu(PerkSelectionMenuHandler);
	
	SetMenuTitle(menu, "Select A Perk\n\nYou can choose the perk that you \nwant to equip in the slots");
	for(new upgrade = 0; upgrade < MAX_UPGRADES; upgrade++)
	{
		if(iUpgrade[client][upgrade] == 0)
		{
			decl String:buffer[32];
			Format(buffer, sizeof(buffer), "%s", PerkTitle[upgrade]);

			AddMenuItem(menu, buffer, buffer);
		}
	}

	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public PerkSelectionMenuHandler(Handle:menu, MenuAction:action, param1, param2)
{
	new client = param1;
	switch(action)
	{
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
		case MenuAction_Cancel:
		{
			if(param2 == MenuCancel_ExitBack)
			{
				UpgradesEnabledMenu(param1);
			}
		}
		case MenuAction_Select:
		{
			new String:item1[56];
			GetMenuItem(menu, param2, item1, sizeof(item1));
			for(new i = 0; i < MAX_UPGRADES; i++)
			{
				if(StrEqual(item1, PerkTitle[i], false))
				{
					iUpgrade[client][i] = UpgradeIndex[i];
					PrintToChat(client, "%s", UpgradeTitle[i]);
					PerkMenu(client);
					if(iSaveFeature[client] == 0)
						iSaveFeature[client] = 1;
				}
			}
		}
	}
}

public UpgradesEnabledMenu(client)
{
	if(GetClientTeam(client) == 2 || GetClientTeam(client) == 1)
	{
		new Handle:menu = CreateMenu(UpgradesEnabledMenuHandler);

		for(new upgrade = 0; upgrade < MAX_UPGRADES; upgrade++)
		{
			decl String:buffer[255];
			decl String:buffer2[32];
			decl String:status[10];
			if(iUpgradeDisabled[client][upgrade] == 1)
			{
				Format(status, sizeof(status), "Disabled");
			}
			else
			{
				Format(status, sizeof(status), "Active");
			}
			Format(buffer, sizeof(buffer), "%s (%s)", PerkTitle[upgrade], status);
			Format(buffer2, sizeof(buffer2), "%s", PerkTitle[upgrade]);
			AddMenuItem(menu, buffer2, buffer);
		}

		AddMenuItem(menu, "Disable All", "Disable All");
		SetMenuTitle(menu, "Toggle Upgrades");
		SetMenuExitButton(menu, true);
		DisplayMenu(menu, client, MENU_TIME_FOREVER);
	}  
}

public UpgradesEnabledMenuHandler(Handle:menu, MenuAction:action, param1, param2)
{
	new client = param1;
	switch(action)
	{
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
		case MenuAction_Cancel:
		{
			if(param2 == MenuCancel_ExitBack)
			{
				UpgradesEnabledMenu(param1);
			}
		}
		case MenuAction_Select:
		{
			new String:item1[56];
			GetMenuItem(menu, param2, item1, sizeof(item1));
			for(new i = 0; i < MAX_UPGRADES; i++)
			{
				if(StrEqual(item1, PerkTitle[i], false))
				{
					if(iUpgradeDisabled[client][i] == 0)
					{
						iUpgradeDisabled[client][i] = 1;
						if(iUpgrade[client][i] > 0)
						{
							iUpgrade[client][i] = 0;
							SetClientUpgradesCheck(client);
						}
					}
					else
					{
						iUpgradeDisabled[client][i] = 0;					
					}
					UpgradesEnabledMenu(client);
				}
			}
		}
	}
}

public AwardStatusMenu(client)
{
	new Handle:AwardStatusPanel = CreatePanel();
	SetPanelTitle(AwardStatusPanel, "Award Completion List");

	for(new award = 0; award < AWARDID; award++)
	{
		decl String:buffer[32], String:buffer2[32];
		if(iCount[client][award] > 0)
		{
			Format(buffer2, sizeof(buffer2), "%d/%d", iCount[client][award], GetConVarInt(AwardIndex[award]));
			Format(buffer, sizeof(buffer), "%s (%s)", AwardTitle[award], buffer2);
			DrawPanelText(AwardStatusPanel, buffer);
		}
	}
	DrawPanelItem(AwardStatusPanel, "Refresh");
	DrawPanelItem(AwardStatusPanel, "Back");
	
	SendPanelToClient(AwardStatusPanel, client, AwardStatusPanelHandler, 30);
	CloseHandle(AwardStatusPanel);
}


public AwardStatusPanelHandler(Handle:AwardStatusPanel, MenuAction:action, param1, param2)
{
	new client = param1;
	if (action == MenuAction_Select)
	{
		if(param2 == 1)
		{
			AwardStatusMenu(client);
		}
		else if(param2 == 2)
		{
			DisplayUpgradeMenu(client);
			RefreshRewards[client] = 0;
		}
	}
	else if(action == MenuAction_Cancel)
	{
		// Nothing
	}
}

public event_AwardEarnedExtended(client, achievementid)
{
	if(GetConVarInt(g_PerkMode) == 1)
		return;
		
 	if(achievementid == 70 && GetConVarInt(AwardIndex[achievementid]) > 0)
	{
		iCount[client][achievementid] += 1;
		if(iCount[client][achievementid] >= GetConVarInt(AwardIndex[achievementid]))
		{
			GiveSurvivorUpgrade(client, 1, achievementid);
			iCount[client][achievementid] = 0;
		}
	}
 	if(achievementid == 71 && GetConVarInt(AwardIndex[achievementid]) > 0)
	{
		iCount[client][achievementid] += 1;
		if(iCount[client][achievementid] >= GetConVarInt(AwardIndex[achievementid]))
		{
			GiveSurvivorUpgrade(client, 1, achievementid);
			iCount[client][achievementid] = 0;
		}
	}
 	if(achievementid == 72 && GetConVarInt(AwardIndex[achievementid]) > 0)
	{
		iCount[client][achievementid] += 1;
		if(iCount[client][achievementid] >= GetConVarInt(AwardIndex[achievementid]))
		{
			GiveSurvivorUpgrade(client, 1, achievementid);
			iCount[client][achievementid] = 0;
		}
	}
 	if(achievementid == 73 && GetConVarInt(AwardIndex[achievementid]) > 0)
	{
		iCount[client][achievementid] += 1;
		if(iCount[client][achievementid] >= GetConVarInt(AwardIndex[achievementid]))
		{
			GiveSurvivorUpgrade(client, 1, achievementid);
			iCount[client][achievementid] = 0;
		}
	}
 	if(achievementid == 100 && GetConVarInt(AwardIndex[achievementid]) > 0)
	{
		iCount[client][achievementid] += 1;
		if(iCount[client][achievementid] >= GetConVarInt(AwardIndex[achievementid]))
		{
			GiveSurvivorUpgrade(client, 1, achievementid);
			iCount[client][achievementid] = 0;
		}
	}	
	if(achievementid == 101 && GetConVarInt(AwardIndex[achievementid]) > 0)
	{
		iCount[client][achievementid] += 1;
		if(iCount[client][achievementid] >= GetConVarInt(AwardIndex[achievementid]))
		{
			RemoveSurvivorUpgrade(client, 1, achievementid);
			iCount[client][achievementid] = 0;
		}
	}
	if(achievementid == 102 && GetConVarInt(AwardIndex[achievementid]) > 0)
	{
		iCount[client][achievementid] += 1;
		if(iCount[client][achievementid] >= GetConVarInt(AwardIndex[achievementid]))
		{
			RemoveSurvivorUpgrade(client, 1, achievementid);
			iCount[client][achievementid] = 0;
		}
	}
	if(achievementid == 103 && GetConVarInt(AwardIndex[achievementid]) > 0)
	{
		iCount[client][achievementid] += 1;
		if(iCount[client][achievementid] >= GetConVarInt(AwardIndex[achievementid]))
		{
			RemoveSurvivorUpgrade(client, 1, achievementid);
			iCount[client][achievementid] = 0;
		}
	}

	if(AwardsCooldownTimer[client] == INVALID_HANDLE)
	{
		AwardsCooldownTimer[client] = CreateTimer(3.0, event_AwardsCooldownTimer, client);
	}
	if(RefreshRewards[client] == 1)
	{
		AwardStatusMenu(client);
	}	
	AwardsCooldownID[client] = achievementid;
}

public event_AwardEarned(Handle:event, const String:name[], bool:Broadcast) 
{
	if(b_round_end == true || GetConVarInt(g_PerkMode) == 1)
		return;

	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new achievementid = GetEventInt(event, "award");

	if(AwardsCooldownTimer[client] != INVALID_HANDLE && achievementid == AwardsCooldownID[client])
	{
		return;
	}

	new multiplier = 1;

	decl String:GameName[16];
	GetConVarString(FindConVar("mp_gamemode"), GameName, sizeof(GameName));

	if(StrEqual(GameName, "survival", false))
	{
		multiplier = 2;
	}

	// 14 - Blind Luck
	if(achievementid == 14 && GetConVarInt(AwardIndex[achievementid]) > 0)
	{
		iCount[client][achievementid] += 1;
		if(iCount[client][achievementid] >= GetConVarInt(AwardIndex[achievementid]) * multiplier)
		{
			GiveSurvivorUpgrade(client, 1, achievementid);
			iCount[client][achievementid] = 0;
		}
	}
	// 15 - Pyrotechnician
	if(achievementid == 15 && GetConVarInt(AwardIndex[achievementid]) > 0)
	{
		iCount[client][achievementid] += 1;
		if(iCount[client][achievementid] >= GetConVarInt(AwardIndex[achievementid]) * multiplier)
		{
			GiveSurvivorUpgrade(client, 1, achievementid);
			iCount[client][achievementid] = 0;
		}
	}
	// 18 - Witch Hunter
	if(achievementid == 18 && GetConVarInt(AwardIndex[achievementid]) > 0)
	{
		iCount[client][achievementid] += 1;
		if(iCount[client][achievementid] >= GetConVarInt(AwardIndex[achievementid]) * multiplier)
		{
			GiveSurvivorUpgrade(client, 1, achievementid);
			iCount[client][achievementid] = 0;
		}
	}
	// 19 - Crowned Witch
	if(achievementid == 19 && GetConVarInt(AwardIndex[achievementid]) > 0)
	{
		iCount[client][achievementid] += 1;
		if(iCount[client][achievementid] >= GetConVarInt(AwardIndex[achievementid]) * multiplier)
		{
			GiveSurvivorUpgrade(client, 2, achievementid);
			iCount[client][achievementid] = 0;
		}
	}
	// 21 - Dead Stop
	if(achievementid == 21 && GetConVarInt(AwardIndex[achievementid]) > 0)
	{
		iCount[client][achievementid] += 1;
		if(iCount[client][achievementid] >= GetConVarInt(AwardIndex[achievementid]) * multiplier)
		{
			GiveSurvivorUpgrade(client, 1, achievementid);
			iCount[client][achievementid] = 0;
		}
	}
	// 26 - Boom-Cork
	if(achievementid == 26 && GetConVarInt(AwardIndex[achievementid]) > 0)
	{
		iCount[client][achievementid] += 1;
		if(iCount[client][achievementid] >= GetConVarInt(AwardIndex[achievementid]) * multiplier)
		{
			GiveSurvivorUpgrade(client, 1, achievementid);
			iCount[client][achievementid] = 0;
		}
	}
	// 27 - Tongue Twister
	if(achievementid == 27 && GetConVarInt(AwardIndex[achievementid]) > 0)
	{
		iCount[client][achievementid] += 1;
		if(iCount[client][achievementid] >= GetConVarInt(AwardIndex[achievementid]) * multiplier)
		{
			GiveSurvivorUpgrade(client, 1, achievementid);
			iCount[client][achievementid] = 0;
		}
	}
	// 66 - Helping Hand
	if(achievementid == 66 && GetConVarInt(AwardIndex[achievementid]) > 0)
	{
		iCount[client][achievementid] += 1;
		if(iCount[client][achievementid] >= GetConVarInt(AwardIndex[achievementid]) * multiplier)
		{
			GiveSurvivorUpgrade(client, 1, achievementid);
			iCount[client][achievementid] = 0;
		}
	}
	// 67 - My Bodyguard
	if(achievementid == 67 && GetConVarInt(AwardIndex[achievementid]) > 0)
	{
		iCount[client][achievementid] += 1;
		if(iCount[client][achievementid] >= GetConVarInt(AwardIndex[achievementid]) * multiplier)
		{
			GiveSurvivorUpgrade(client, 1, achievementid);
			iCount[client][achievementid] = 0;
		}
	}
	// 68 - Pharm-Assist
	if(achievementid == 68 && GetConVarInt(AwardIndex[achievementid]) > 0)
	{
		iCount[client][achievementid] += 1;
		if(iCount[client][achievementid] >= GetConVarInt(AwardIndex[achievementid]) * multiplier)
		{
			GiveSurvivorUpgrade(client, 1, achievementid);
			iCount[client][achievementid] = 0;
		}
	}
	// 69 - Medic
	if(achievementid == 69 && GetConVarInt(AwardIndex[achievementid]) > 0)
	{
		iCount[client][achievementid] += 1;
		if(iCount[client][achievementid] >= GetConVarInt(AwardIndex[achievementid]) * multiplier)
		{
			GiveSurvivorUpgrade(client, 1, achievementid);
			iCount[client][achievementid] = 0;
		}
	}
	// 75 - Special Savior
	if(achievementid == 75 && GetConVarInt(AwardIndex[achievementid]) > 0)
	{
		iCount[client][achievementid] += 1;
		if(iCount[client][achievementid] >= GetConVarInt(AwardIndex[achievementid]) * multiplier)
		{
			GiveSurvivorUpgrade(client, 1, achievementid);
			iCount[client][achievementid] = 0;
		}
	}
	// 79 - Hero Closet
	if(achievementid == 79 && GetConVarInt(AwardIndex[achievementid]) > 0)
	{
		iCount[client][achievementid] += 1;
		if(iCount[client][achievementid] >= GetConVarInt(AwardIndex[achievementid]) * multiplier)
		{
			GiveSurvivorUpgrade(client, 1, achievementid);
			iCount[client][achievementid] = 0;
		}
	}
	// 80 Tankbusters
	if(achievementid == 80 && GetConVarInt(AwardIndex[achievementid]) > 0)
	{
		iCount[client][achievementid] += 1;
		if(iCount[client][achievementid] * multiplier >= GetConVarInt(AwardIndex[achievementid]) * multiplier)
		{
			GiveSurvivorUpgrade(client, 1, achievementid);
			iCount[client][achievementid] = 0;
		}
	}
	// 83 - Team-Kill
	if(achievementid == 83 && GetConVarInt(AwardIndex[achievementid]) > 0)
	{
		iCount[client][achievementid] += 1;
		if(iCount[client][achievementid] >= GetConVarInt(AwardIndex[achievementid]))
		{
			RemoveSurvivorUpgrade(client, 1, achievementid);
			iCount[client][achievementid] = 0;
		}
	}
	// 84 - Team-Incapacitate
	if(achievementid == 84 && GetConVarInt(AwardIndex[achievementid]) > 0)
	{
		iCount[client][achievementid] += 1;
		if(iCount[client][achievementid] >= GetConVarInt(AwardIndex[achievementid]))
		{
			RemoveSurvivorUpgrade(client, 1, achievementid);
			iCount[client][achievementid] = 0;
		}
	}
	// 85 - Left 4 Dead
	if(achievementid == 85 && GetConVarInt(AwardIndex[achievementid]) > 0)
	{
		iCount[client][achievementid] += 1;
		if(iCount[client][achievementid] >= GetConVarInt(AwardIndex[achievementid]))
		{
			RemoveSurvivorUpgrade(client, 1, achievementid);
			iCount[client][achievementid] = 0;
		}
	}
	// 86 - Friendly-Fire
	if(achievementid == 86 && GetConVarInt(AwardIndex[achievementid]) > 0)
	{
		iCount[client][achievementid] += 1;
		if(iCount[client][achievementid] >= GetConVarInt(AwardIndex[achievementid]))
		{
			RemoveSurvivorUpgrade(client, 1, achievementid);
			iCount[client][achievementid] = 0;
		}
	}
	// 94 - Zombie Room
	if(achievementid == 94 && GetConVarInt(AwardIndex[achievementid]) > 0)
	{
		iCount[client][achievementid] += 1;
		if(iCount[client][achievementid] >= GetConVarInt(AwardIndex[achievementid]))
		{
			RemoveSurvivorUpgrade(client, 1, achievementid);
			iCount[client][achievementid] = 0;
		}
	}
	// 99 - Abandoned
	if(achievementid == 99 && GetConVarInt(AwardIndex[achievementid]) > 0)
	{
		iCount[client][achievementid] += 1;
		if(iCount[client][achievementid] >= GetConVarInt(AwardIndex[achievementid]))
		{
			RemoveSurvivorUpgrade(client, 1, achievementid);
			iCount[client][achievementid] = 0;
		}
	}
	if(AwardsCooldownTimer[client] == INVALID_HANDLE)
	{
		AwardsCooldownTimer[client] = CreateTimer(3.0, event_AwardsCooldownTimer, client);
	}
	if(RefreshRewards[client] == 1)
	{
		AwardStatusMenu(client);
	}	
	AwardsCooldownID[client] = achievementid;
}

public Action:event_AwardsCooldownTimer(Handle:timer, any:client)
{
	AwardsCooldownTimer[client] = INVALID_HANDLE;
}

public Action:round_start(Handle:event, const String:name[], bool:dontBroadcast)
{
	b_round_end = false;
	for(new i=1; i<=MaxClients; i++)
	{
		if(IsClientInGame(i) && GetClientTeam(i) == 2 && GetSurvivorUpgrades(i) == 0)
		{
				CreateTimer(30.0, event_AnnounceMod, i);			
		}
	}
}

public Action:round_end(Handle:event, const String:name[], bool:dontBroadcast)
{
	b_round_end = true;
	new MaxCount = MaxClients;
	for(new i=1; i<=MaxCount; i++)
	{
		if(IsValidEntity(i) == true && IsClientInGame(i))
		{
			SetEntProp(i, Prop_Send, "m_upgradeBitVec", 0, 4);
			UpgradeHotMeal(i, 0);
			if(iLargePainPills[i] == 1)
			{
				iLargePainPills[i] = 2;
			}
			if(iLargeFirstAidKit[i] == 1)
			{
				iLargeFirstAidKit[i] = 2;
			}
			if(iGrenadePouch[i] == 1)
			{
				iGrenadePouch[i] = 2;
			}
		}
	}
	OnGameEnd();
}

public Action:event_AnnounceMod(Handle:timer, any:client)
{
	if(IsClientInGame(client))
		PrintToChat(client, "\x04[\x05NOTICE\x04] \x03Survivor Upgrades Reloaded \x01is enabled. Press \x03F3 \x01or \x03!upgrades \x01in chat\x01.");
}

public event_WeaponFire(Handle:event, const String:name[], bool:Broadcast)
{
	// 10
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new WeaponID = GetEventInt(event, "weaponid");
	if(WeaponID == 9)
	{
		iGrenadePouch[client] -= 1;
		UpgradeKerosene(client);
	}	
	if(WeaponID == 10)
	{
		UpgradeSafetyFuse(client);
		iGrenadePouch[client] -= 1;
		CreateTimer(1.0, timer_SafetyFuseStop, client);
	}

}

public event_PillsUsed(Handle:event, const String:name[], bool:Broadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	UpgradeSteroids(client);
	UpgradePillBox(client);
	iLargePainPills[client] = 0;
}

public event_ReviveSuccess(Handle:event, const String:name[], bool:Broadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new subject = GetClientOfUserId(GetEventInt(event, "subject"));
	UpgradeBandages(client, subject);
	UpgradeMorphogenicCells(subject);
	UpgradeAutoinjectors(subject);
}

public event_PlayerIncapacitated(Handle:event, const String:name[], bool:Broadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if(GetClientTeam(client) == 3)
		return;

	if(MorphogenicTimer[client] != INVALID_HANDLE)
	{
		CloseHandle(MorphogenicTimer[client]);
		MorphogenicTimer[client] = INVALID_HANDLE;
	}
	if(RegenerationTimer[client] != INVALID_HANDLE)
	{
		CloseHandle(RegenerationTimer[client]);
		RegenerationTimer[client] = INVALID_HANDLE;
	}
	UpgradeBetaBlockers(client);
	event_AwardEarnedExtended(client, 101);
}

public event_PlayerNowIt(Handle:event, const String:name[], bool:Broadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new bool:exploded = GetEventBool(event, "exploded");

	if(exploded == true)
		event_AwardEarnedExtended(client, 103);
	else
		event_AwardEarnedExtended(client, 102);
}

public event_PlayerHurt(Handle:event, const String:name[], bool:Broadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if(MorphogenicTimer[client] != INVALID_HANDLE)
	{
		CloseHandle(MorphogenicTimer[client]);
		MorphogenicTimer[client] = INVALID_HANDLE;
	}
	if(RegenerationTimer[client] != INVALID_HANDLE)
	{
		CloseHandle(RegenerationTimer[client]);
		RegenerationTimer[client] = INVALID_HANDLE;
	}
	UpgradeMorphogenicCells(client);
	UpgradeHotMeal(client, 1);
}

public event_PlayerJump(Handle:event, const String:name[], bool:Broadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	UpgradeAirBoots(client);
}

public event_HealBegin(Handle:event, const String:name[], bool:Broadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	UpgradeStimpacks(client);
}

public event_HealSuccess(Handle:event, const String:name[], bool:Broadcast) 
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new subject = GetClientOfUserId(GetEventInt(event, "subject"));
	new health_restored = GetEventInt(event, "health_restored");

	new m_iMaxHealth = GetEntData(subject, FindDataMapOffs(subject, "m_iMaxHealth"), 4);
	
	new m_iCHealth = RoundFloat(float(m_iMaxHealth)-(250.0-(float(health_restored)/0.8)));
	new m_iHealth = RoundFloat((m_iMaxHealth-m_iCHealth)+m_iCHealth*0.8);
	
	SetEntData(subject, FindDataMapOffs(subject, "m_iHealth"), m_iHealth, 4, true);
	if(iUpgrade[client][28] > 0)
	{
		SetEntData(subject, FindDataMapOffs(subject, "m_iHealth"), m_iMaxHealth, 4, true);
	}
	iLastStand[client] = 0;
	iLargeFirstAidKit[client] = 0;
	UpgradeMedicalChart(client, subject, m_iCHealth);
}

public event_InfectedDeath(Handle:event, const String:name[], bool:Broadcast) 
{
	new client = GetClientOfUserId(GetEventInt(event, "attacker"));
	new bool:headshot = GetEventBool(event, "headshot");

	if(headshot == true)
		event_AwardEarnedExtended(client, 70);

	if(GetConVarInt(g_PerkMode))
	{
		if(GetRandomInt(0, 1000) == 1 && GetConVarInt(PerkBonusSlots) > iPerkBonusSlots[client])
		{
			iPerkBonusSlots[client]++;
			PrintToChat(client, "You have unlocked a new \x04Perk Slot\x01.");
		}
	}
}

public event_InfectedHurt(Handle:event, const String:name[], bool:Broadcast) 
{
	new client = GetClientOfUserId(GetEventInt(event, "attacker"));
	new type = GetEventInt(event, "type");

	if(type & 1 << 3 && client > 0)
	{
		event_AwardEarnedExtended(client, 100);
	}
}

public event_MeleeKill(Handle:event, const String:name[], bool:Broadcast) 
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new entityid = GetEventInt(event, "entityid");
	new bool:ambush = GetEventBool(event, "ambush");
	if(ambush == true)
	{
		UpgradePickpocketHook(client, entityid);
		event_AwardEarnedExtended(client, 71);
	}
}

public event_TankKilled(Handle:event, const String:name[], bool:Broadcast) 
{
	new client = GetClientOfUserId(GetEventInt(event, "attacker"));
	new bool:solo = GetEventBool(event, "solo");

	if(solo == true)
	{
		event_AwardEarnedExtended(client, 72);
	}
	event_AwardEarnedExtended(client, 73);
}

public event_BreakProp(Handle:event, const String:name[], bool:Broadcast) 
{
	new entindex = GetEventInt(event, "entindex");
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	UpgradeKeroseneSpray(client, entindex);
}

public event_BotPlayerReplace(Handle:event, const String:name[], bool:Broadcast) 
{
	new client = GetClientOfUserId(GetEventInt(event, "player"));
	
	if(client > 0)
	{
		if(GetConVarInt(g_PerkMode) == 1 && IsClientInGame(client))
			PrintToChat(client, "\x04[\x05NOTICE\x04] \x03Survivor Upgrades Reloaded \x01is currently enabled (PERK MODE). Press \x03F3 \x01or type \x03!upgrades, !perks \x01in chat box\x01.");
		else
			PrintToChat(client, "\x04[\x05NOTICE\x04] \x03Survivor Upgrades Reloaded \x01is currently enabled. Press \x03F3 \x01or \x03!upgrades \x01in chat\x01.");
	}
}

public event_EntityShoved(Handle:event, const String:name[], bool:Broadcast) 
{
	new entityid = GetEventInt(event, "entityid");
	new client = GetClientOfUserId(GetEventInt(event, "attacker"));

	UpgradeTransfusionBox(client, entityid);
}

public UpgradeTransfusionBox(client, entityid)
{
	if(iUpgrade[client][35] > 0)
	{
		new chance = GetRandomInt(0, 100);
		decl String:entityname[64];
		GetEdictClassname(entityid, entityname, 32);

		if(chance < 50 && StrEqual(entityname, "infected"))
		{
			new amount = GetRandomInt(1 , 3);
			new m_iHealth = GetEntProp(client, Prop_Send, "m_iHealth");
			new m_iMaxHealth = GetEntProp(client, Prop_Send, "m_iMaxHealth");
			if(m_iHealth + amount >= m_iMaxHealth)
			{
				SetEntProp(client, Prop_Send, "m_iHealth", m_iHealth);
			}
			else
			{
				SetEntProp(client, Prop_Send, "m_iHealth", m_iHealth + amount);
			}
		}
	}
}

public UpgradeSafetyFuse(client)
{
	if(iUpgrade[client][23] > 0)
	{
		SetConVarFloat(FindConVar("pipe_bomb_timer_duration"), PipeBombDuration*1.5, false, false);
		SetConVarFloat(FindConVar("pipe_bomb_beep_interval_delta"), 0.025, false, false);
		SetConVarFloat(FindConVar("pipe_bomb_beep_min_interval"), 0.1, false, false);
		SetConVarFloat(FindConVar("pipe_bomb_initial_beep_interval"), 0.6, false, false);
	}
}

public UpgradeSteroids(client)
{
	new Float:m_iHealth = float(GetEntData(client, FindDataMapOffs(client, "m_iHealth"), 4));
	new Float:m_iMaxHealth = float(GetEntData(client, FindDataMapOffs(client, "m_iMaxHealth"), 4));
	new Float:m_iHealthBufferBits = GetConVarInt(FindConVar("pain_pills_health_value"))*0.5;
	new Float:m_iHealthBuffer = GetEntDataFloat(client, FindSendPropOffs("CTerrorPlayer","m_healthBuffer"));

	if(iUpgrade[client][2] > 0)
	{
		if(m_iHealth + m_iHealthBuffer + m_iHealthBufferBits > m_iMaxHealth)
		{
			m_iHealthBufferBits = m_iMaxHealth - m_iHealth;
			SetEntPropFloat(client, Prop_Send, "m_healthBuffer", m_iHealthBufferBits);
		}
		else
		{
			SetEntPropFloat(client, Prop_Send, "m_healthBuffer", m_iHealthBuffer + m_iHealthBufferBits);
		}
	}
}

public UpgradeBandages(client, subject)
{
	if(iUpgrade[client][3] > 0 && GetClientTeam(client) == 2 || iUpgrade[subject][2] > 0 && GetClientTeam(client) == 2)
	{
		new Float:m_iHealthBuffer = float(GetConVarInt(FindConVar("survivor_revive_health")))*1.5;
		SetEntPropFloat(subject, Prop_Send, "m_healthBuffer", m_iHealthBuffer);
	}
}

public UpgradeBetaBlockers(client)
{
	if(iUpgrade[client][4] > 0 && GetClientTeam(client) == 2)
	{
		new m_iHealthBuffer = RoundFloat(GetConVarInt(FindConVar("survivor_incap_health"))*1.5);
		SetEntProp(client, Prop_Send, "m_iHealth", m_iHealthBuffer);
	}
}

public UpgradeMorphogenicCells(client)
{
	if(iUpgrade[client][5] > 0 && GetClientTeam(client) == 2)
	{
		new m_iHealth = GetEntData(client, FindDataMapOffs(client, "m_iHealth"), 4);
		new m_iMaxHealth = GetEntData(client, FindDataMapOffs(client, "m_iMaxHealth"), 4);
		if(MorphogenicTimer[client] == INVALID_HANDLE && GetClientTeam(client) == 2 && GetEntProp(client, Prop_Send, "m_isIncapacitated") == 0 && m_iHealth <= RoundFloat(m_iMaxHealth * 0.5))
		{
			MorphogenicTimer[client] = CreateTimer(10.0, timer_MorphogenicTimer, client);
		}
	}
}

public UpgradeMedicalChart(client, subject, restored_health)
{
	if(iUpgrade[client][43] > 0 && (client == subject || IsFakeClient(client)))
	{
		restored_health = RoundFloat((float(restored_health)*0.8) / 2.0);
		
		for(new i = 1; i <= MaxClients; i++)
		{
			if(IsClientClose(i, subject) && i != subject)
			{
				new m_iHealth = GetEntData(i, FindDataMapOffs(i, "m_iHealth"), 4);
				new m_iMaxHealth = GetEntData(i, FindDataMapOffs(i, "m_iMaxHealth"), 4);
				
				new iEHealth = m_iHealth + restored_health;
				if((m_iHealth + restored_health) > m_iMaxHealth)
					 iEHealth = m_iMaxHealth;

				SetEntData(i, FindDataMapOffs(i, "m_iHealth"), iEHealth, 4, true);
			}
		}
	}
}

public UpgradePillBox(client)
{
	if(iUpgrade[client][44] > 0)
	{
		new Float:m_iHealthBufferBits = float(GetConVarInt(FindConVar("pain_pills_health_value")));
		new Float:im_iHealthBufferBits = 0.0;
		
		if(iUpgrade[client][2] > 0)
			m_iHealthBufferBits = m_iHealthBufferBits*1.5;
			
		m_iHealthBufferBits = m_iHealthBufferBits*0.5;
			
		for(new i = 1; i <= MaxClients; i++)
		{
			if(IsClientClose(i, client) && i != client)
			{
				new Float:im_iHealth = float(GetEntData(i, FindDataMapOffs(i, "m_iHealth"), 4));
				new Float:im_iMaxHealth = float(GetEntData(i, FindDataMapOffs(i, "m_iMaxHealth"), 4));
				new Float:im_iHealthBuffer = GetEntDataFloat(i, FindSendPropOffs("CTerrorPlayer","m_healthBuffer"));
				im_iHealthBufferBits = m_iHealthBufferBits;
				if(im_iHealth + im_iHealthBuffer + m_iHealthBufferBits > im_iMaxHealth)
				{
					im_iHealthBufferBits = im_iMaxHealth - im_iHealth;
					SetEntPropFloat(i, Prop_Send, "m_healthBuffer", im_iHealthBufferBits);
				}
				else
				{
					SetEntPropFloat(i, Prop_Send, "m_healthBuffer", im_iHealthBuffer + im_iHealthBufferBits);
				}
				SetEntPropFloat(i, Prop_Send, "m_healthBufferTime", GetGameTime());
			}
		}
	}
}

public bool:IsClientClose(client, subject)
{ 
	new Float:clientPosition[3];
	new Float:otherPosition[3];
	new Float:m_flDistance;
	
	GetClientEyePosition(subject, clientPosition);	

	if(IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) == 2)
	{
		GetClientEyePosition(client, otherPosition);
		m_flDistance = GetVectorDistance(clientPosition, otherPosition);
		
		if(m_flDistance < 100)
		{			
			return true;
		}
	}
	return false;
}

public Action:timer_MorphogenicTimer(Handle:timer, any:client)
{
	MorphogenicTimer[client] = INVALID_HANDLE;
	RegenerationTimer[client] = CreateTimer(0.1, timer_RegenerationTimer, client, TIMER_REPEAT);
}

public Action:timer_RegenerationTimer(Handle:timer, any:client)
{
	if(IsClientInGame(client) && GetClientTeam(client) == 2)
	{
		if(GetEntProp(client, Prop_Send, "m_isGoingToDie") == 1)
			SetEntProp(client, Prop_Send, "m_isGoingToDie", 0);

		new m_iHealth = GetEntData(client, FindDataMapOffs(client, "m_iHealth"), 4);
		new m_iMaxHealth = GetEntData(client, FindDataMapOffs(client, "m_iMaxHealth"), 4);
		if(m_iHealth >= RoundFloat(m_iMaxHealth * 0.5))
		{
			RegenerationTimer[client] = INVALID_HANDLE;
			return Plugin_Stop;

		}
		SetEntData(client, FindDataMapOffs(client, "m_iHealth"), m_iHealth+1, 4, true);
		return Plugin_Continue;
	}
	return Plugin_Handled;
}

public Action:timer_SafetyFuseStop(Handle:timer, any:client)
{
	SetConVarFloat(FindConVar("pipe_bomb_timer_duration"), PipeBombDuration, false, false);
	SetConVarFloat(FindConVar("pipe_bomb_beep_interval_delta"), 0.025, false, false);
	SetConVarFloat(FindConVar("pipe_bomb_beep_min_interval"), 0.1, false, false);
	SetConVarFloat(FindConVar("pipe_bomb_initial_beep_interval"), 0.5, false, false);
	return Plugin_Handled;
}

public UpgradeAirBoots(client)
{
	if(iUpgrade[client][6] > 0 && GetClientTeam(client) == 2)
	{
		SetEntDataFloat(client, FindDataMapOffs(client, "m_flGravity"), 0.75);
	}
	else
	{
		SetEntDataFloat(client, FindDataMapOffs(client, "m_flGravity"), 1.0);
	}
}

public UpgradeHotMeal(client, type)
{
	if(iUpgrade[client][16] > 0)
	{
		decl String:GameName[16];
		GetConVarString(FindConVar("mp_gamemode"), GameName, sizeof(GameName));
		new m_iHealth = GetEntProp(client, Prop_Send, "m_iHealth");
		new m_isIncapacitated = GetEntProp(client, Prop_Send, "m_isIncapacitated"); 

		if(StrEqual(GameName, "survival", false) && type == 1 && m_iHealth < 10 && m_isIncapacitated == 0)
		{
			SetEntProp(client, Prop_Send, "m_iHealth", 150, 4);
			SetEntProp(client, Prop_Send, "m_isGoingToDie", 0, 4);
			iUpgrade[client][16] = 0;
		}
		else if(type == 0)
		{
			SetEntProp(client, Prop_Send, "m_iHealth", 150, 4);
			SetEntProp(client, Prop_Send, "m_isGoingToDie", 0, 4);
			iUpgrade[client][16] = 0;
		}
	}
}

public UpgradeStimpacks(client)
{
	if(iUpgrade[client][30] > 0)
	{
		SetConVarFloat(FindConVar("first_aid_kit_use_duration"), FirstAidDuration/2, false, false);
	}
	else
	{
		SetConVarFloat(FindConVar("first_aid_kit_use_duration"), FirstAidDuration, false, false);
	}
}

public UpgradeLargePainPills(client)
{
	if(iUpgrade[client][0] > 0)
	{
		new item = GivePlayerItem(client, "weapon_pain_pills");
		EquipPlayerWeapon(client, item);
	}
}

public UpgradeLargeFirstAidKit(client)
{
	if(iUpgrade[client][10] > 0)
	{
		new item = GivePlayerItem(client, "weapon_first_aid_kit");
		EquipPlayerWeapon(client, item);
	}
}

public UpgradeGrenadePouch(client, String:iWeaponName[32])
{
	if(iUpgrade[client][31] > 0 && iGrenadePouch[client] > 0)
	{
		if(StrEqual(iWeaponName, "pipe_bomb"))
		{
			new item = GivePlayerItem(client, "weapon_molotov");
			EquipPlayerWeapon(client, item);
		}
		else if(StrEqual(iWeaponName, "molotov"))
		{
			new item = GivePlayerItem(client, "weapon_pipe_bomb");
			EquipPlayerWeapon(client, item);
		}
		else if(StrEqual(iWeaponName, "random"))
		{
			new iRandomNumber = GetRandomInt(1, 2);
			if(iRandomNumber == 1)
			{
				new item = GivePlayerItem(client, "weapon_molotov");
				EquipPlayerWeapon(client, item);
			}
			if(iRandomNumber == 2)
			{
				new item = GivePlayerItem(client, "weapon_pipe_bomb");
				EquipPlayerWeapon(client, item);
			}
		}
	}
}

public Action:timer_GrenadePouch(Handle:timer, any:client)
{
	new iRandomNumber = GetRandomInt(1, 2);
	if(iRandomNumber == 1)
	{
		new item = GivePlayerItem(client, "weapon_molotov");
		EquipPlayerWeapon(client, item);
	}
	if(iRandomNumber == 2)
	{
		new item = GivePlayerItem(client, "weapon_pipe_bomb");
		EquipPlayerWeapon(client, item);
	}
}

public UpgradePickpocketHook(client, entityid)
{
	if(iUpgrade[client][32] > 0)
	{
		new iChance[9];
		iChance[1] = 7;
		iChance[2] = 5;
		iChance[3] = 6;
		iChance[4] = 7;
		iChance[5] = 4;
		iChance[6] = 7;
		iChance[7] = 7;
		iChance[8] = 7;

		for(new iRandom = 1; iRandom < 8; iRandom++)
		{
			decl Float:fOrigin[3];
			GetEntPropVector(entityid, Prop_Data, "m_vecOrigin", fOrigin);
			new iDrop;

			//if(GetRandomInt(0, 100) < 25)

			fOrigin[2] += 40.0;
			new Float:vel[3];
			vel[0] = GetRandomFloat(-200.0, 200.0);
			vel[1] = GetRandomFloat(-200.0, 200.0);
			vel[2] = GetRandomFloat(40.0, 80.0);

			if(GetRandomInt(0, 200) < iChance[iRandom])
			{
				if(iRandom <= 1)	iDrop = CreateEntityByName("weapon_pistol");
				else if(iRandom == 2)	iDrop = CreateEntityByName("weapon_pipe_bomb");
				else if(iRandom == 3)	iDrop = CreateEntityByName("weapon_molotov");
				else if(iRandom == 4)	iDrop = CreateEntityByName("weapon_pain_pills");
				else if(iRandom == 5)	iDrop = CreateEntityByName("weapon_first_aid_kit");
				else if(iRandom == 6)	iDrop = CreateEntityByName("weapon_rifle");
				else if(iRandom == 7)	iDrop = CreateEntityByName("weapon_autoshotgun");
				else if(iRandom >= 8)	iDrop = CreateEntityByName("weapon_hunting_rifle");

				DispatchSpawn(iDrop);
				ActivateEntity(iDrop);
				TeleportEntity(iDrop, fOrigin, NULL_VECTOR, vel);
			}
		}
	}
}

public UpgradeOcularImplants(client, entityid)
{
	if(iUpgrade[client][33] > 0)
	{
		new iChance[9];
		iChance[1] = 7;
		iChance[2] = 5;
		iChance[3] = 6;
		iChance[4] = 7;
		iChance[5] = 4;
		iChance[6] = 7;
		iChance[7] = 7;
		iChance[8] = 7;

		for(new iRandom = 1; iRandom < 8; iRandom++)
		{
			decl Float:fOrigin[3];
			GetEntPropVector(entityid, Prop_Data, "m_vecOrigin", fOrigin);
			new iDrop;

			fOrigin[2] += 40.0;
			new Float:vel[3];
			vel[0] = GetRandomFloat(-200.0, 200.0);
			vel[1] = GetRandomFloat(-200.0, 200.0);
			vel[2] = GetRandomFloat(40.0, 80.0);

			if(GetRandomInt(0, 200) < iChance[iRandom])
			{
				if(iRandom <= 1)	iDrop = CreateEntityByName("weapon_pistol");
				else if(iRandom == 2)	iDrop = CreateEntityByName("weapon_pipe_bomb");
				else if(iRandom == 3)	iDrop = CreateEntityByName("weapon_molotov");
				else if(iRandom == 4)	iDrop = CreateEntityByName("weapon_pain_pills");
				else if(iRandom == 5)	iDrop = CreateEntityByName("weapon_first_aid_kit");
				else if(iRandom == 6)	iDrop = CreateEntityByName("weapon_rifle");
				else if(iRandom == 7)	iDrop = CreateEntityByName("weapon_autoshotgun");
				else if(iRandom >= 8)	iDrop = CreateEntityByName("weapon_hunting_rifle");

				if(iRandom > 5 && iRandom < 9)
					SetEntProp(iDrop, Prop_Send, "m_iExtraPrimaryAmmo", GetRandomInt(50, 128));

				DispatchSpawn(iDrop);
				ActivateEntity(iDrop);
				TeleportEntity(iDrop, fOrigin, NULL_VECTOR, vel);
			}
		}
	}
}

public UpgradeKeroseneSpray(client, entindex)
{
	if(iUpgrade[client][34] > 0)
	{
		decl String:sModelFile[256];
		GetEntPropString(entindex, Prop_Data, "m_ModelName", sModelFile, sizeof(sModelFile));

		if(StrEqual(sModelFile, ENTITY_GASCAN, false))
		{
			decl Float:fOrigin[3];
			GetEntPropVector(entindex, Prop_Data, "m_vecOrigin", fOrigin);

			new Handle:pack = CreateDataPack();
			WritePackFloat(pack, fOrigin[0]);
			WritePackFloat(pack, fOrigin[1]);
			WritePackFloat(pack, fOrigin[2]);
			WritePackCell(pack, client);
			CreateTimer(10.0, timer_PyroPouchGasCan, pack);
		}
		if(StrEqual(sModelFile, ENTITY_PROPANE, false))
		{
			decl Float:fOrigin[3];
			GetEntPropVector(entindex, Prop_Data, "m_vecOrigin", fOrigin);

			new Handle:pack = CreateDataPack();
			WritePackFloat(pack, fOrigin[0]);
			WritePackFloat(pack, fOrigin[1]);
			WritePackFloat(pack, fOrigin[2]);
			WritePackCell(pack, client);
			CreateTimer(0.8, timer_PyroPouchPropane, pack, TIMER_REPEAT);
		}
	}
}

public UpgradeAutoinjectors(client)
{
	if(iUpgrade[client][38] > 0)
	{
		if(GetEntProp(client, Prop_Send, "m_currentReviveCount") == 1 && iLastStand[client] == 0)
		{
			iLastStand[client] = 1;
			SetEntProp(client, Prop_Send, "m_currentReviveCount", 0, 4);
			SetEntProp(client, Prop_Send, "m_isGoingToDie", 0);
		}
	}
}

public UpgradeKerosene(client)
{
	if(iUpgrade[client][39] > 0)
		CreateTimer(0.3, CreateMolotovTimer);
}

public Action:CreateMolotovTimer(Handle:hTimer, any:type)
{
	new iEntity = INVALID_ENT_REFERENCE;
	while ((iEntity = FindEntityByClassname(iEntity, "molotov_projectile")) != INVALID_ENT_REFERENCE)
	{
		HookSingleEntityOutput(iEntity, "OnKilled", MolotovBreak);
	}
}

public MolotovBreak(const String:output[], caller, activator, Float:delay)
{
	decl Float:fOrigin[3];
	GetEntPropVector(caller, Prop_Data, "m_vecOrigin", fOrigin);

	new Handle:pack = CreateDataPack();
	WritePackFloat(pack, fOrigin[0]);
	WritePackFloat(pack, fOrigin[1]);
	WritePackFloat(pack, fOrigin[2]);
	WritePackCell(pack, activator);
	CreateTimer(10.0, timer_PyroPouchGasCan, pack);
}

public Action:timer_PyroPouchGasCan(Handle:timer, any:pack)
{

	decl Float:fOrigin[3];

	ResetPack(pack);
	fOrigin[0] = ReadPackFloat(pack);
	fOrigin[1] = ReadPackFloat(pack);
	fOrigin[2] = ReadPackFloat(pack);

	new entity = CreateEntityByName("prop_physics");
	if(IsValidEntity(entity))
	{
		fOrigin[2] += 30.0;
		DispatchKeyValue(entity, "model", ENTITY_GASCAN);
		DispatchSpawn(entity);
		SetEntData(entity, GetEntSendPropOffs(entity, "m_CollisionGroup"), 1, 1, true);
		TeleportEntity(entity, fOrigin, NULL_VECTOR, NULL_VECTOR);
		ActivateEntity(entity);
	}
}

public Action:timer_PyroPouchPropane(Handle:timer, any:pack)
{
	decl Float:fOrigin[3];

	ResetPack(pack);
	fOrigin[0] = ReadPackFloat(pack);
	fOrigin[1] = ReadPackFloat(pack);
	fOrigin[2] = ReadPackFloat(pack);
	new client = ReadPackCell(pack);

	new entity = CreateEntityByName("prop_physics");
	if(IsValidEntity(entity))
	{
		fOrigin[2] += 30.0;
		DispatchKeyValue(entity, "model", ENTITY_PROPANE);
		DispatchSpawn(entity);
		SetEntData(entity, GetEntSendPropOffs(entity, "m_CollisionGroup"), 1, 1, true);
		TeleportEntity(entity, fOrigin, NULL_VECTOR, NULL_VECTOR);
		AcceptEntityInput(entity, "break");
	}

	iCountTimer[client] += 1;

	if(iCountTimer[client] > 2)
	{
		iCountTimer[client] = 0;
		return Plugin_Stop;
	}

	return Plugin_Continue;
}

public UpgradeCasingDispenser(client)
{
	if(CasingDispenserTimer[client] == INVALID_HANDLE)
	{
		CasingDispenserTimer[client] = CreateTimer(5.0, timer_CasingDispenser, client, TIMER_REPEAT);
	}
}

public Action:timer_CasingDispenser(Handle:timer, any:client)
{
	if(IsClientInGame(client) && IsPlayerAlive(client))
	{
		new iWEAPON = GetPlayerWeaponSlot(client, 0);
		if(iWEAPON > 0)
		{
			new m_iAmmo = FindDataMapOffs(client, "m_iAmmo");			
			new String:iWeaponName[32];
			new iAmmoCheck;
			decl Float:iMultiplier;
			GetEdictClassname(iWEAPON, iWeaponName, 32);
			
			if(iUpgrade[client][7] > 0)
			{
				iMultiplier = 1.5;
			}
					
			if(StrContains(iWeaponName, "smg", false) != -1)
			{
				iAmmoCheck = GetEntData(client, m_iAmmo+SMG_OFFSET_AMMO, 4);
				if(iAmmoCheck <= RoundToNearest(GetConVarInt(FindConVar("ammo_smg_max"))*iMultiplier)-5)
					SetEntData(client, m_iAmmo+SMG_OFFSET_AMMO, iAmmoCheck+5);
			}
			if(StrContains(iWeaponName, "rifle", false) != -1)
			{
				iAmmoCheck = GetEntData(client, m_iAmmo+RIFLE_OFFSET_AMMO, 4);
				if(iAmmoCheck <= RoundToNearest(GetConVarInt(FindConVar("ammo_assaultrifle_max"))*iMultiplier)-5)
					SetEntData(client, m_iAmmo+RIFLE_OFFSET_AMMO, iAmmoCheck+5);
			}
			if(StrContains(iWeaponName, "shotgun", false) != -1)
			{
				iAmmoCheck = GetEntData(client, m_iAmmo+SHOTGUN_OFFSET_AMMO, 4);
				if(iAmmoCheck <= RoundToNearest(GetConVarInt(FindConVar("ammo_buckshot_max"))*iMultiplier)-1)
					SetEntData(client, m_iAmmo+SHOTGUN_OFFSET_AMMO, iAmmoCheck+1);
			}
			if(StrContains(iWeaponName, "sniper", false) != -1)
			{
				iAmmoCheck = GetEntData(client, m_iAmmo+HUNTING_RIFLE_OFFSET_AMMO, 4);
				if(iAmmoCheck <= RoundToNearest(GetConVarInt(FindConVar("ammo_huntingrifle_max"))*iMultiplier)-2)
					SetEntData(client, m_iAmmo+HUNTING_RIFLE_OFFSET_AMMO, iAmmoCheck+2);
			}	
			return Plugin_Continue;
		}
		else
		{
			return Plugin_Continue;
		}
	}
	else
	{
		return Plugin_Continue;		
	}
}

stock bool:HasIdlePlayer(bot)
{
    new userid = GetEntData(bot, FindSendPropInfo("SurvivorBot", "m_humanSpectatorUserID"));
    new client = GetClientOfUserId(userid);
    
    if(client > 0)
    {
        if(IsClientConnected(client) && !IsFakeClient(client))
            return true;
    }    
    return false;
}

stock bool:IsClientIdle(client)
{
	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			new spectator_userid = GetEntData(i, FindSendPropInfo("SurvivorBot", "m_humanSpectatorUserID"));
			new spectator_client = GetClientOfUserId(spectator_userid);
        
			if(spectator_client == client)
			return true;
		}
	}
	return false;
}

stock GetAnyValidClient()
{
	for (new target = 1; target <= MaxClients; target++)
	{
		if(IsClientInGame(target))
			return target;
	}
	return -1;
}

stock GetClientUsedUpgrade(upgrade)
{
	for(new i = 1; i <= MaxClients; i++) 
	{
		if(IsClientInGame(i) && GetClientTeam(i) == 2)
		{
			new used = GetEntProp(i, Prop_Send, "m_upgradeBitVec");
			if(iUpgrade[i][upgrade] > 0 && (used & 1 << upgrade != 1 << upgrade))
			{
				if(GetConVarInt(g_PerkMode) == 0)
					RemoveUpgrade(i, upgrade);
				return i;
			}
		}
	}
	return 0;
}

public OnClientDisconnect(client)
{
	if(IsClientInGame(client) && GetClientTeam(client) != 3)
		SaveData(client);

	if(MorphogenicTimer[client] != INVALID_HANDLE)
	{
		CloseHandle(MorphogenicTimer[client]);
		MorphogenicTimer[client] = INVALID_HANDLE;
	}
	if(RegenerationTimer[client] != INVALID_HANDLE)
	{
		CloseHandle(RegenerationTimer[client]);
		RegenerationTimer[client] = INVALID_HANDLE;
	}
	if(AwardsCooldownTimer[client] != INVALID_HANDLE)
	{
		CloseHandle(AwardsCooldownTimer[client]);
		AwardsCooldownTimer[client] = INVALID_HANDLE;
	}
	if(SetClientUpgrades[client] != INVALID_HANDLE)
	{
		CloseHandle(SetClientUpgrades[client]);
		SetClientUpgrades[client] = INVALID_HANDLE;
	}
}

stock CheatCommand(client, String:command[], String:argument1[], String:argument2[])
{
	new userFlags = GetUserFlagBits(client);
	SetUserFlagBits(client, ADMFLAG_ROOT);
	new flags = GetCommandFlags(command);
	SetCommandFlags(command, flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "%s %s %s", command, argument1, argument2);
	SetCommandFlags(command, flags);
	SetUserFlagBits(client, userFlags);
}