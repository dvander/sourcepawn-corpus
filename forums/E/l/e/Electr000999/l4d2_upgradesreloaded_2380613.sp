#pragma semicolon 1
/**
 * \x01 - Default
 * \x02 - Team Color
 * \x03 - Light Green
 * \x04 - Orange
 * \x05 - Olive
 */

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define PLUGIN_VERSION		"1.6.2"
#define UPGRADEID		32
#define MAX_UPGRADES		32
#define AWARDID			128
#define CVAR_FLAGS		FCVAR_PLUGIN|FCVAR_NOTIFY
#define UPGRADE_LOAD_TIME	1.0
#define LEN64 64

#define	RIFLE_OFFSET_AMMO		12
#define	SMG_OFFSET_AMMO			20
#define	SHOTGUN_OFFSET_AMMO		28
#define	AUTOSHOTGUN_OFFSET_AMMO		32
#define	HUNTING_RIFLE_OFFSET_AMMO	36
#define	SNIPER_OFFSET_AMMO		40
#define	GRENADE_LAUNCHER_OFFSET_AMMO	68

#define	RIFLE_AMMO		360
#define	SMG_AMMO		650
#define	SHOTGUN_AMMO		56
#define	AUTOSHOTGUN_AMMO	90
#define	HUNTING_RIFLE_AMMO	150
#define	SNIPER_AMMO		180
#define	GRENADE_LAUNCHER_AMMO	30

#define ENTITY_GASCAN	"models/props_junk/gascan001a.mdl"
#define ENTITY_PROPANE	"models/props_junk/propanecanister001a.mdl"

public Plugin:myinfo =
{
    name = "[L4D2] Survivor Upgrades Reloaded",
    author = "Marcus101RR, Whosat & Jerrith",
    description = "Survivor Upgrades Returns, Reloaded!",
    version = PLUGIN_VERSION,
    url = "http://forums.alliedmods.net"
}

new Handle:UpgradeEnabled[MAX_UPGRADES + 1] = INVALID_HANDLE;
new Handle:AwardIndex[AWARDID + 1] = INVALID_HANDLE;
new Handle:MorphogenicTimer[MAXPLAYERS + 1] = INVALID_HANDLE;
new Handle:RegenerationTimer[MAXPLAYERS + 1] = INVALID_HANDLE;
new Handle:AwardsCooldownTimer[MAXPLAYERS + 1] = INVALID_HANDLE;
new Handle:KnifeCooldownTimer[MAXPLAYERS + 1] = INVALID_HANDLE;
new Handle:penalty_upgrades;
new Handle:SetClientUpgrades[MAXPLAYERS + 1] = INVALID_HANDLE;
new Handle:ReloadCooldown[MAXPLAYERS + 1] = INVALID_HANDLE;
new Handle:g_PerkMode = INVALID_HANDLE;
new Handle:PerkSlots = INVALID_HANDLE;
new Handle:PerkBonusSlots = INVALID_HANDLE;
new Handle:hDatabase;

new bool:b_round_end;
new bool:IsDatabaseLoaded = false;
new bool:iKnifeReady = false;
new RefreshRewards[MAXPLAYERS + 1] = 0;

new String:iGrenadeItems[MAXPLAYERS+1][2][LEN64];
new UpgradeIndex[MAX_UPGRADES + 1] = 0;
new String:UpgradeTitle[MAX_UPGRADES + 1][128];
new String:UpgradeShort[MAX_UPGRADES + 1][64];
new String:PerkTitle[MAX_UPGRADES + 1][64];
new String:AwardTitle[AWARDID + 1][128];
new iBitsUpgrades[MAXPLAYERS + 1] = 0;
new iUpgrade[MAXPLAYERS + 1][UPGRADEID + 1];
new iUpgradeDisabled[MAXPLAYERS + 1][UPGRADEID + 1];
new iCount[MAXPLAYERS + 1][AWARDID + 1];
new iAnnounceText[MAXPLAYERS + 1] = 0;
new iSaveFeature[MAXPLAYERS + 1] = 0;
new AwardsCooldownID[MAXPLAYERS + 1];
new iActiveWeapon[MAXPLAYERS + 1];
new iPerkBonusSlots[MAXPLAYERS + 1] = 0;

new String:iPrimaryItems[MAXPLAYERS + 1][2][LEN64];
new String:iSecondaryItems[MAXPLAYERS + 1][2][LEN64];
new iAutoinjectors[MAXPLAYERS + 1];

new iCountTimer[MAXPLAYERS + 1];

new Float:FirstAidDuration;
new Float:ReviveDuration;
new Float:PipeBombDuration;

new String:SavePath[256];

public OnPluginStart()
{
	decl String:game_name[64];
	GetGameFolderName(game_name, sizeof(game_name));
	if (!StrEqual(game_name, "left4dead2", false))
	{
		SetFailState("Plugin Supports Left 4 Dead 2 Only.");
	}

	/* Build Save Path */
	BuildPath(Path_SM, SavePath, 255, "data/l4d2_upgradesreloaded.txt");

	CreateConVar("sm_upgradesreloaded_version", PLUGIN_VERSION, "Survivor Upgrades Reloaded Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	penalty_upgrades = CreateConVar("survivor_upgrade_awards_death_amount", "2", "Number of Upgrades Lost per Death", CVAR_FLAGS, true, 1.0, true, 8.0);
	g_PerkMode = CreateConVar("survivor_upgrade_perk_mode", "0", "Option for Perk style gameplay", CVAR_FLAGS, true, 0.0, true, 1.0);
	PerkSlots = CreateConVar("survivor_upgrade_perk_slots", "4", "The number of perks allowed in the game.", CVAR_FLAGS, true, 0.0, true, 6.0);
	PerkBonusSlots = CreateConVar("survivor_upgrade_perk_bonus_slots", "2", "The number of bonus perks obtainable in the game.", CVAR_FLAGS, true, 0.0, true, 6.0);

	AwardIndex[0] = CreateConVar("survivor_upgrade_awards_death", "3", "Lose All Upgrades (0 - Disable, 1 - Bots Only, 2 - Humans Only, 3 - All Players", CVAR_FLAGS, true, 0.0, true, 3.0);
	AwardTitle[0] = "\x05Death Penalty\x01";
	AwardIndex[14] = CreateConVar("survivor_upgrade_awards_blind_luck", "1", "Number of Blind Luck Awards To Earn Upgrade", CVAR_FLAGS, true, 0.0, true, 64.0);
	AwardTitle[14] = "\x05Blind Luck Award\x01";
	AwardIndex[15] = CreateConVar("survivor_upgrade_awards_pyrotechnician", "2", "Number of Pyrotechnician Awards To Earn Upgrade", CVAR_FLAGS, true, 0.0, true, 64.0);
	AwardTitle[15] = "\x05Pyrotechnician Award\x01";
	AwardIndex[18] = CreateConVar("survivor_upgrade_awards_witch_hunter", "1", "Number of Witch Hunter Awards To Earn Upgrade", CVAR_FLAGS, true, 0.0, true, 64.0);
	AwardTitle[18] = "\x05Witch Hunter Award\x01";
	AwardIndex[19] = CreateConVar("survivor_upgrade_awards_crowned", "1", "Number of Crowned Awards To Earn Upgrade", CVAR_FLAGS, true, 0.0, true, 64.0);
	AwardTitle[19] = "\x05Crowned Award\x01";
	AwardIndex[21] = CreateConVar("survivor_upgrade_awards_dead_stop", "1", "Number of Dead Stop Awards To Earn Upgrade", CVAR_FLAGS, true, 0.0, true, 64.0);
	AwardTitle[21] = "\x05Dead Stop Award\x01";
	AwardIndex[22] = CreateConVar("survivor_upgrade_awards_brawler", "10", "Number of Brawler Awards To Earn Upgrade", CVAR_FLAGS, true, 0.0, true, 64.0);
	AwardTitle[22] = "\x05Brawler Award\x01";
	AwardIndex[26] = CreateConVar("survivor_upgrade_awards_boom_cork", "1", "Number of Boom-Cork Awards To Earn Upgrade", CVAR_FLAGS, true, 0.0, true, 64.0);
	AwardTitle[26] = "\x05Boom-Cork Award\x01";
	AwardIndex[27] = CreateConVar("survivor_upgrade_awards_tongue_twister", "1", "Number of Tongue Twister Awards To Earn Upgrade", CVAR_FLAGS, true, 0.0, true, 10.0);
	AwardTitle[27] = "\x05Tongue Twister Award\x01";
	AwardIndex[66] = CreateConVar("survivor_upgrade_awards_helping_hand", "4", "Number of Helping Hand Awards To Earn Upgrade", CVAR_FLAGS, true, 0.0, true, 64.0);
	AwardTitle[66] = "\x05Helping Hand Award\x01";
	AwardIndex[67] = CreateConVar("survivor_upgrade_awards_my_bodyguard", "4", "Number of My Bodyguard Awards To Earn Upgrade", CVAR_FLAGS, true, 0.0, true, 64.0);
	AwardTitle[67] = "\x05My Bodyguard Award\x01";
	AwardIndex[68] = CreateConVar("survivor_upgrade_awards_pharm_assist", "4", "Number of Pharm-Assist Awards To Earn Upgrade", CVAR_FLAGS, true, 0.0, true, 64.0);
	AwardTitle[68] = "\x05Pharm-Assist Award\x01";
	AwardIndex[69] = CreateConVar("survivor_upgrade_awards_adrenaline", "4", "Number of Adrenaline Awards To Earn Upgrade", CVAR_FLAGS, true, 0.0, true, 64.0);
	AwardTitle[69] = "\x05Adrenaline Award\x01";
	AwardIndex[70] = CreateConVar("survivor_upgrade_awards_medic", "4", "Number of Medic Awards To Earn Upgrade", CVAR_FLAGS, true, 0.0, true, 64.0);
	AwardTitle[70] = "\x05Medic Award\x01";
	AwardIndex[76] = CreateConVar("survivor_upgrade_awards_special_savior", "4", "Number of Special Savior Awards To Earn Upgrade", CVAR_FLAGS, true, 0.0, true, 64.0);
	AwardTitle[76] = "\x05Special Savior Award\x01";
	AwardIndex[80] = CreateConVar("survivor_upgrade_awards_hero_closet", "1", "Number of Hero Closet Awards To Earn Upgrade", CVAR_FLAGS, true, 0.0, true, 10.0);
	AwardTitle[80] = "\x05Hero Closet Award\x01";
	AwardIndex[81] = CreateConVar("survivor_upgrade_awards_tankbusters", "1", "Number of Tankbusters Award To Earn Upgrade", CVAR_FLAGS, true, 0.0, true, 64.0);
	AwardTitle[81] = "\x05Tankbusters Award\x01";
	AwardIndex[84] = CreateConVar("survivor_upgrade_awards_teamkill", "1", "Number of Team Kill Penalties To Lose Upgrade", CVAR_FLAGS, true, 0.0, true, 64.0);
	AwardTitle[84] = "\x05Team-Kill Penalty\x01";
	AwardIndex[85] = CreateConVar("survivor_upgrade_awards_teamincapacitate", "1", "Number of Team-Incapacitate Penalty To Lose Upgrade", CVAR_FLAGS, true, 0.0, true, 64.0);
	AwardTitle[85] = "\x05Team-Incapacitate Penalty\x01";
	AwardIndex[87] = CreateConVar("survivor_upgrade_awards_friendly_fire", "4", "Number of Friendly-Fire Penalty To Lose Upgrade", CVAR_FLAGS, true, 0.0, true, 64.0);
	AwardTitle[87] = "\x05Friendly-Fire Penalty\x01";
	AwardIndex[100] = CreateConVar("survivor_upgrade_awards_101_cremations", "101", "Number of 101 Cremations To Earn Upgrade", CVAR_FLAGS, true, 0.0, true, 101.0);
	AwardTitle[100] = "\x05101 Cremations Award\x01";
	AwardIndex[102] = CreateConVar("survivor_upgrade_awards_brain_salad", "30", "Number of Brain Salad Awards To Earn Upgrade", CVAR_FLAGS, true, 0.0, true, 100.0);
	AwardTitle[102] = "\x05Brain Salad Award\x01";
	AwardIndex[103] = CreateConVar("survivor_upgrade_awards_barf_bagged", "1", "Number of Barf Bagged Penalty To Lose Upgrade", CVAR_FLAGS, true, 0.0, true, 10.0);
	AwardTitle[103] = "\x05Barf Bagged Penalty\x01";
	AwardIndex[104] = CreateConVar("survivor_upgrade_awards_vomit_bomb", "1", "Number of Vomit Bomb Penalty To Lose Upgrade", CVAR_FLAGS, true, 0.0, true, 10.0);
	AwardTitle[104] = "\x05Vomit Bomb Penalty\x01";
	AwardIndex[105] = CreateConVar("survivor_upgrade_awards_acid_burn", "1", "Number of Acid Burn Penalty To Lose Upgrade", CVAR_FLAGS, true, 0.0, true, 10.0);
	AwardTitle[105] = "\x05Acid Burn Penalty\x01";
	AwardIndex[106] = CreateConVar("survivor_upgrade_awards_incapicated", "1", "Number of Incapacitated Penalty To Lose Upgrade", CVAR_FLAGS, true, 0.0, true, 10.0);
	AwardTitle[106] = "\x05Incapacitated Penalty\x01";
	
	RegConsoleCmd("sm_upgrades", PrintToChatUpgrades, "List Upgrades.");
	RegConsoleCmd("sm_perks", OpenPerkMenu, "Opens up the Perk Menu.");
	RegConsoleCmd("sm_laser", UpgradeLaserSightToggle, "Toggle the Laser Sight upgrade.");
	RegAdminCmd("sm_giveupgrade", CommandGiveUpgrade, ADMFLAG_CHEATS,  "Give player specfied upgrade.");
	RegAdminCmd("sm_giverandomupgrade", CommandGiveRandomUpgrade, ADMFLAG_CHEATS,  "Give player random upgrade.");

	UpgradeIndex[0] = 1;
	UpgradeTitle[0] = "\x03Autoinjectors \x01(\x04Increased Incapacitation Limit\x01)";
	UpgradeShort[0] = "\x03Autoinjectors\x01";
	UpgradeEnabled[0] = CreateConVar("survivor_upgrade_autoinjectors_enable", "1", "Enable/Disable Autoinjectors", CVAR_FLAGS, true, 0.0, true, 1.0);
	PerkTitle[0] = "Autoinjectors";

	UpgradeIndex[1] = 2;
	UpgradeTitle[1] = "\x03Kerosene \x01(\x04Increased Molotov Burn Duration\x01)";
	UpgradeShort[1] = "\x03Kerosene\x01";
	UpgradeEnabled[1] = CreateConVar("survivor_upgrade_Kerosene_enable", "1", "Enable/Disable Kerosene", CVAR_FLAGS, true, 0.0, true, 1.0);
	PerkTitle[1] = "Kerosene";

	UpgradeIndex[2] = 4;
	UpgradeTitle[2] = "\x03Laser Sight \x01(\x04Increased Accuracy\x01)";
	UpgradeShort[2] = "\x03Laser Sight\x01";
	UpgradeEnabled[2] = CreateConVar("survivor_upgrade_laser_sight_enable", "1", "Enable/Disable Laser Sight", CVAR_FLAGS, true, 0.0, true, 1.0);
	PerkTitle[2] = "Laser Sight";

	UpgradeIndex[3] = 8;
	UpgradeTitle[3] = "\x03Kevlar Body Armor \x01(\x04Reduced Damage\x01)";
	UpgradeShort[3] = "\x03Kevlar Body Armor\x01";
	UpgradeEnabled[3] = CreateConVar("survivor_upgrade_kevlar_armor_enable", "1", "Enable/Disable Kevlar Body Armor", CVAR_FLAGS, true, 0.0, true, 1.0);
	PerkTitle[3] = "Kevlar Body Armor";

	UpgradeIndex[4] = 16;
	UpgradeTitle[4] = "\x03Hot Meal \x01(\x04Increased Maximum Health\x01)";
	UpgradeShort[4] = "\x03Hot Meal\x01";
	UpgradeEnabled[4] = CreateConVar("survivor_upgrade_hot_meal_enable", "1", "Enable/Disable Hot Meal", CVAR_FLAGS, true, 0.0, true, 1.0);
	PerkTitle[4] = "Hot Meal";

	UpgradeIndex[5] = 32;
	UpgradeTitle[5] = "\x03Ointment \x01(\x04Increased Healing Effect\x01)";
	UpgradeShort[5] = "\x03Ointment\x01";
	UpgradeEnabled[5] = CreateConVar("survivor_upgrade_ointment_enable", "1", "Enable/Disable Ointment", CVAR_FLAGS, true, 0.0, true, 1.0);
	PerkTitle[5] = "Ointment";

	UpgradeIndex[6] = 64;
	UpgradeTitle[6] = "\x03Ammo Backpack \x01(\x04Increased Ammunition Reserve\x01)";
	UpgradeShort[6] = "\x03Ammo Backpack\x01";
	UpgradeEnabled[6] = CreateConVar("survivor_upgrade_backpack_enable", "1", "Enable/Disable Ammo Backpack", CVAR_FLAGS, true, 0.0, true, 1.0);
	PerkTitle[6] = "Ammo Backpack";

	UpgradeIndex[7] = 128;
	UpgradeTitle[7] = "\x03Steroids \x01(\x04Increased Temporary Health Effect\x01)";
	UpgradeShort[7] = "\x03Steroids\x01";
	UpgradeEnabled[7] = CreateConVar("survivor_upgrade_steroids_enable", "1", "Enable/Disable Steroids", CVAR_FLAGS, true, 0.0, true, 1.0);
	PerkTitle[7] = "Steroids";

	UpgradeIndex[8] = 256;
	UpgradeTitle[8] = "\x03Barrel Chamber \x01(\x04Increased Upgrade Pack Ammo\x01)";
	UpgradeShort[8] = "\x03Barrel Chamber\x01";
	UpgradeEnabled[8] = CreateConVar("survivor_upgrade_barrel_chamber_enable", "1", "Enable/Disable Barrel Chamber", CVAR_FLAGS, true, 0.0, true, 1.0);
	PerkTitle[8] = "Barrel Chamber";

	UpgradeIndex[9] = 512;
	UpgradeTitle[9] = "\x03Heavy Duty Batteries \x01(\x04Increased Defibrillator Effect\x01)";
	UpgradeShort[9] = "\x03Heavy Duty Batteries\x01";
	UpgradeEnabled[9] = CreateConVar("survivor_upgrade_heavy_duty_enable", "1", "Enable/Disable Heavy Duty Batteries", CVAR_FLAGS, true, 0.0, true, 1.0);
	PerkTitle[9] = "Heavy Duty Batteries";

	UpgradeIndex[10] = 1024;
	UpgradeTitle[10] = "\x03Bandages \x01(\x04Increased Revive Health\x01)";
	UpgradeShort[10] = "\x03Bandages\x01";
	UpgradeEnabled[10] = CreateConVar("survivor_upgrade_bandages_enable", "1", "Enable/Disable Bandages", CVAR_FLAGS, true, 0.0, true, 1.0);
	PerkTitle[10] = "Bandages";

	UpgradeIndex[11] = 2048;
	UpgradeTitle[11] = "\x03Beta-Blockers \x01(\x04Increased Incapacitation Health\x01)";
	UpgradeShort[11] = "\x03Beta-Blockers\x01";
	UpgradeEnabled[11] = CreateConVar("survivor_upgrade_beta_blockers_enable", "1", "Enable/Disable Beta-Blockers", CVAR_FLAGS, true, 0.0, true, 1.0);
	PerkTitle[11] = "Beta-Blockers";

	UpgradeIndex[12] = 4092;
	UpgradeTitle[12] = "\x03Morphogenic Cells \x01(\x04Limited Health Regeneration\x01)";
	UpgradeShort[12] = "\x03Morphogenic Cells\x01";
	UpgradeEnabled[12] = CreateConVar("survivor_upgrade_morphogenic_cells_enable", "1", "Enable/Disable Morphogenic Cells", CVAR_FLAGS, true, 0.0, true, 1.0);
	PerkTitle[12] = "Morphogenic Cells";

	UpgradeIndex[13] = 8192;
	UpgradeTitle[13] = "\x03Air Boots \x01(\x04Increased Jump Height\x01)";
	UpgradeShort[13] = "\x03Air Boots\x01";
	UpgradeEnabled[13] = CreateConVar("survivor_upgrade_air_boots_enable", "1", "Enable/Disable Air Boots", CVAR_FLAGS, true, 0.0, true, 1.0);
	PerkTitle[13] = "Air Boots";

	UpgradeIndex[14] = 16384;
	UpgradeTitle[14] = "\x03Bandoliers \x01(\x04Allows M60 Ammo Supply Pile\x01)";
	UpgradeShort[14] = "\x03Bandoliers\x01";
	UpgradeEnabled[14] = CreateConVar("survivor_upgrade_bandoliers_enable", "1", "Enable/Disable Bandoliers", CVAR_FLAGS, true, 0.0, true, 1.0);
	PerkTitle[14] = "Bandoliers";

	UpgradeIndex[15] = 32768;
	UpgradeTitle[15] = "\x03Hollow Point Ammunition \x01(\x04Increased Bullet Damage\x01)";
	UpgradeShort[15] = "\x03Hollow Point Ammunition\x01";
	UpgradeEnabled[15] = CreateConVar("survivor_upgrade_hollow_point_enable", "1", "Enable/Disable Hollow Point Ammunition", CVAR_FLAGS, true, 0.0, true, 1.0);
	PerkTitle[15] = "Hollow Point Ammunition";

	UpgradeIndex[16] = 65536;
	UpgradeTitle[16] = "\x03Knife \x01(\x04Self-Save Pinned\x01)";
	UpgradeShort[16] = "\x03Knife\x01";
	UpgradeEnabled[16] = CreateConVar("survivor_upgrade_knife_enable", "1", "Enable/Disable Knife", CVAR_FLAGS, true, 0.0, true, 1.0);
	PerkTitle[16] = "Knife";

	UpgradeIndex[17] = 131072;
	UpgradeTitle[17] = "\x03Stimpacks \x01(\x04Reduced Healing Duration\x01)";
	UpgradeShort[17] = "\x03Stimpacks\x01";
	UpgradeEnabled[17] = CreateConVar("survivor_upgrade_stimpacks_enable", "1", "Enable/Disable Stimpacks", CVAR_FLAGS, true, 0.0, true, 1.0);
	PerkTitle[17] = "Stimpacks";

	UpgradeIndex[18] = 262144;
	UpgradeTitle[18] = "\x03Smelling Salts \x01(\x04Reduced Revive Duration\x01)";
	UpgradeShort[18] = "\x03Smelling Salts\x01";
	UpgradeEnabled[18] = CreateConVar("survivor_upgrade_smelling_salts_enable", "1", "Enable/Disable Smelling Salts", CVAR_FLAGS, true, 0.0, true, 1.0);
	PerkTitle[18] = "Smelling Salts";

	UpgradeIndex[19] = 524288;
	UpgradeTitle[19] = "\x03Medical Satchel \x01(\x04Increased Primary Item Capacity\x01)";
	UpgradeShort[19] = "\x03Medical Satchel\x01";
	UpgradeEnabled[19] = CreateConVar("survivor_upgrade_large_first_aid_kit_enable", "1", "Enable/Disable Large First Aid Kit", CVAR_FLAGS, true, 0.0, true, 1.0);
	PerkTitle[19] = "Medical Satchel";

	UpgradeIndex[20] = 1048576;
	UpgradeTitle[20] = "\x03Hydration Belt \x01(\x04Increased Secondary Item Usage\x01)";
	UpgradeShort[20] = "\x03Hydration Belt\x01";
	UpgradeEnabled[20] = CreateConVar("survivor_upgrade_large_pain_pills_enable", "1", "Enable/Disable Hydration Belt", CVAR_FLAGS, true, 0.0, true, 1.0);
	PerkTitle[20] = "Hydration Belt";

	UpgradeIndex[21] = 2097152;
	UpgradeTitle[21] = "\x03High Capacity Magazine \x01(\x04Increased Magazine Clip\x01)";
	UpgradeShort[21] = "\x03High Capacity Magazine\x01";
	UpgradeEnabled[21] = CreateConVar("survivor_upgrade_large_high_capacity_magazine_enable", "1", "Enable/Disable High Capacity Magazine", CVAR_FLAGS, true, 0.0, true, 1.0);
	PerkTitle[21] = "High Capacity Magazine";

	UpgradeIndex[22] = 4194304;
	UpgradeTitle[22] = "\x03Arm Guards \x01(\x04Increased Maximum Health\x01)";
	UpgradeShort[22] = "\x03Arm Guards\x01";
	UpgradeEnabled[22] = CreateConVar("survivor_upgrade_arm_guards_enable", "1", "Enable/Disable Arm Guards", CVAR_FLAGS, true, 0.0, true, 1.0);
	PerkTitle[22] = "Arm Guards";

	UpgradeIndex[23] = 8388608;
	UpgradeTitle[23] = "\x03Shin Guards \x01(\x04Increased Maximum Health\x01)";
	UpgradeShort[23] = "\x03Shin Guards\x01";
	UpgradeEnabled[23] = CreateConVar("survivor_upgrade_shin_guards_enable", "1", "Enable/Disable Shin Guards", CVAR_FLAGS, true, 0.0, true, 1.0);
	PerkTitle[23] = "Shin Guards";

	UpgradeIndex[24] = 16777216;
	UpgradeTitle[24] = "\x03Safety Fuse \x01(\x04Increased Pipebomb Duration\x01)";
	UpgradeShort[24] = "\x03Safety Fuse\x01";
	UpgradeEnabled[24] = CreateConVar("survivor_upgrade_safety_fuse_enable", "1", "Enable/Disable Safety Fuse", CVAR_FLAGS, true, 0.0, true, 1.0);
	PerkTitle[24] = "Safety Fuse";

	UpgradeIndex[25] = 33554432;
	UpgradeTitle[25] = "\x03Syringe Pouch \x01(\x04Increased Secondary Item Usage\x01)";
	UpgradeShort[25] = "\x03Syringe Pouch\x01";
	UpgradeEnabled[25] = CreateConVar("survivor_upgrade_syringe_pouch_enable", "1", "Enable/Disable Syringe Pouch", CVAR_FLAGS, true, 0.0, true, 1.0);
	PerkTitle[25] = "Syringe Pouch";
	
	UpgradeIndex[26] = 67108864;
	UpgradeTitle[26] = "\x03Grenade Pouch \x01(\x04Increased Grenade Capacity\x01)";
	UpgradeShort[26] = "\x03Grenade Pouch\x01";
	UpgradeEnabled[26] = CreateConVar("survivor_upgrade_grenade_pouch_enable", "1", "Enable/Disable Grenade Pouch", CVAR_FLAGS, true, 0.0, true, 1.0);
	PerkTitle[26] = "Grenade Pouch";
	
	UpgradeIndex[27] = 134217728;
	UpgradeTitle[27] = "\x03Ammunition Satchel \x01(\x04Increased Primary Item Capacity\x01)";
	UpgradeShort[27] = "\x03Ammunition Satchel\x01";
	UpgradeEnabled[27] = CreateConVar("survivor_upgrade_ammunition_satchel_enable", "1", "Enable/Disable Ammunition Satchel", CVAR_FLAGS, true, 0.0, true, 1.0);
	PerkTitle[27] = "Ammunition Satchel";

	UpgradeIndex[28] = 1;
	UpgradeTitle[28] = "\x03Ocular Implants \x01(\x04Infected Drop Items\x01)";
	UpgradeShort[28] = "\x03Ocular Implants\x01";
	UpgradeEnabled[28] = CreateConVar("survivor_upgrade_ocular_implants_enable", "1", "Enable/Disable Ocular Implants", CVAR_FLAGS, true, 0.0, true, 1.0);
	PerkTitle[28] = "Ocular Implants";
	
	UpgradeIndex[29] = 1;
	UpgradeTitle[29] = "\x03Helmet \x01(\x04Increased Maximum Health\x01)";
	UpgradeShort[29] = "\x03Helmet\x01";
	UpgradeEnabled[29] = CreateConVar("survivor_upgrade_helmet_enable", "1", "Enable/Disable Helmet", CVAR_FLAGS, true, 0.0, true, 1.0);
	PerkTitle[29] = "Helmet";
	
	UpgradeIndex[30] = 1;
	UpgradeTitle[30] = "\x03Medical Chart \x01(\x04Heal Other Players Nearby\x01)";
	UpgradeShort[30] = "\x03Medical Chart\x01";
	UpgradeEnabled[30] = CreateConVar("survivor_upgrade_medical_chart_enable", "1", "Enable/Disable Medical Chart", CVAR_FLAGS, true, 0.0, true, 1.0);
	PerkTitle[30] = "Medical Chart";
	
	UpgradeIndex[31] = 1;
	UpgradeTitle[31] = "\x03Combat Gloves \x01(\x04Decreased Melee Fatigue\x01)";
	UpgradeShort[31] = "\x03Combat Gloves\x01";
	UpgradeEnabled[31] = CreateConVar("survivor_upgrade_combat_gloves_enable", "1", "Enable/Disable Combat Gloves", CVAR_FLAGS, true, 0.0, true, 1.0);
	PerkTitle[31] = "Combat Gloves";
	
	HookEvent("adrenaline_used", event_AdrenalineUsed, EventHookMode_Post);
	HookEvent("pills_used", event_PillsUsed, EventHookMode_Post);
	HookEvent("defibrillator_used", event_DefibrillatorUsed, EventHookMode_Post);
	HookEvent("upgrade_pack_used", event_UpgradePackUsed, EventHookMode_Post);
	HookEvent("player_spawn", event_PlayerSpawn, EventHookMode);
	HookEvent("item_pickup", event_ItemPickup);
	HookEvent("player_use", event_PlayerUse, EventHookMode_Pre);
	HookEvent("ammo_pickup", event_AmmoPickup, EventHookMode_Post);
	HookEvent("player_death", event_PlayerDeath);
	HookEvent("award_earned", event_AwardEarned);
	HookEvent("round_start", round_start);
	HookEvent("round_end", round_end, EventHookMode_Pre);
	HookEvent("heal_success", event_HealSuccess);
	HookEvent("map_transition", round_end, EventHookMode_Pre);
	HookEvent("receive_upgrade", event_ReceiveUpgrade, EventHookMode_Post);
	HookEvent("revive_success", event_ReviveSuccess);
	HookEvent("player_incapacitated", event_PlayerIncapacitated);
	HookEvent("heal_begin", event_HealBegin, EventHookMode_Pre);
	HookEvent("revive_begin", event_ReviveBegin, EventHookMode_Pre);
	HookEvent("weapon_reload", event_WeaponReload, EventHookMode_Pre);
	HookEvent("weapon_fire", event_WeaponFire, EventHookMode_Pre);
	HookEvent("break_prop", event_BreakProp, EventHookMode_Post);

	HookEvent("player_hurt", event_PlayerHurt, EventHookMode_Post);
	HookEvent("weapon_given", event_WeaponGiven, EventHookMode_Post);
	HookEvent("player_jump", event_PlayerJump);
	HookEvent("bot_player_replace", event_BotPlayerReplace, EventHookMode_Post);
	
	// Custom Awards
	HookEvent("infected_death", event_InfectedDeath);
	HookEvent("infected_hurt", event_InfectedHurt, EventHookMode_Post);
	HookEvent("player_now_it", event_PlayerNowIt, EventHookMode_Post);
	HookEvent("entered_spit", event_EnteredSpit);
	
	// Knife Tracking
	HookEvent("choke_start", event_KnifeCooldownCheck);
	HookEvent("lunge_pounce", event_KnifeCooldownCheck);
	HookEvent("charger_pummel_start", event_KnifeCooldownCheck);
	HookEvent("jockey_ride", event_KnifeCooldownCheck);
	
	HookEvent("choke_end", event_KnifeUnReady);
	HookEvent("pounce_end", event_KnifeUnReady);
	HookEvent("charger_pummel_end", event_KnifeUnReady);
	HookEvent("jockey_ride_end", event_KnifeUnReady);
			
	SetConVarInt(FindConVar("first_aid_kit_max_heal"), 250, false, false);
	SetConVarInt(FindConVar("pain_pills_health_threshold"), 250, false, false);
	SetConVarInt(FindConVar("first_aid_kit_use_duration"), 5, false, false);
	SetConVarInt(FindConVar("survivor_revive_duration"), 5, false, false);
	SetConVarInt(FindConVar("pipe_bomb_timer_duration"), 6, false, false);
	SetConVarInt(FindConVar("adrenaline_health_buffer"), 50, false, false);
	SetConVarFloat(FindConVar("adrenaline_duration"), 30.0, false, false);
	SetConVarInt(FindConVar("pain_pills_health_value"), 50, false, false);
	
	FirstAidDuration = GetConVarFloat(FindConVar("first_aid_kit_use_duration"));
	ReviveDuration = GetConVarFloat(FindConVar("survivor_revive_duration"));
	PipeBombDuration = GetConVarFloat(FindConVar("pipe_bomb_timer_duration"));

	AutoExecConfig(true, "l4d2_upgradesreloaded");
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

	SQL_FastQuery(hDatabase, "CREATE TABLE IF NOT EXISTS accounts (steamid TEXT PRIMARY KEY, saveenabled SMALLINT, notifications SMALLINT, perkbonus SMALLINT, upgrades_binary VARCHAR(32), disabled_binary VARCHAR(32));");
}

stock SaveData(client)
{
	if(iSaveFeature[client] == 1 && GetClientTeam(client) != 3)
	{
		decl String:TQuery[3000], String:SteamID[64], String:cUsername[64], String:UpgradeBinary[64] = "", String:DisabledBinary[64] = "";
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
		GetClientAuthId(client, AuthId_Steam2, SteamID, sizeof(SteamID), true);	
		
		GetClientName(client, cUsername, sizeof(cUsername)); 
		if(IsFakeClient(client) && StrContains(cUsername, "SurvivorBot", false) == -1)
		{
			Format(SteamID, sizeof(SteamID), "%s_%s", SteamID, cUsername);
		}
		Format(TQuery, sizeof(TQuery), "INSERT OR REPLACE INTO accounts VALUES ('%s', %d, %d, %d, '%s', '%s');", SteamID, iSaveFeature[client], iAnnounceText[client], iPerkBonusSlots[client],UpgradeBinary, DisabledBinary);
		SQL_FastQuery(hDatabase, TQuery);
	}
}

public Action:timer_LoadData(Handle:hTimer, any:client)
{
	LoadData(client);
}

stock LoadData(client)
{
	if(IsClientConnected(client))
	{
		decl String:TQuery[192], String:SteamID[64], String:cUsername[64];

		GetClientAuthId(client, AuthId_Steam2, SteamID, sizeof(SteamID), true);	
		
		GetClientName(client, cUsername, sizeof(cUsername));
		if(IsFakeClient(client) && StrContains(cUsername, "SurvivorBot", false) == -1)
		{
			Format(SteamID, sizeof(SteamID), "%s_%s", SteamID, cUsername);
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

	iSaveFeature[client] = 0;
	iAnnounceText[client] = 0;
	iPerkBonusSlots[client] = 0;
	for(new i = 0; i < MAX_UPGRADES; i++)
	{
		iUpgrade[client][i] = 0;
		iUpgradeDisabled[client][i] = 0;
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
		if(KnifeCooldownTimer[i] != INVALID_HANDLE)
		{
			CloseHandle(KnifeCooldownTimer[i]);
			KnifeCooldownTimer[i] = INVALID_HANDLE;
		}
	}
}

public OnClientPostAdminCheck(client)
{
	iSaveFeature[client] = 0;
	iAnnounceText[client] = 0;
	iPerkBonusSlots[client] = 0;
	if(IsClientInGame(client))
		CreateTimer(0.2, timer_LoadData, client);
	SDKHook(client, SDKHook_WeaponCanUse, OnWeaponCanUse);
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

public Action event_WeaponFire(Event event, const char[] name, bool dontBroadcast)
{
	//14 - PipeBomb, 13 - Molotov, 25 - VomitJar
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new WeaponID = GetEventInt(event, "weaponid");
	if(WeaponID == 13)
	{
		UpgradeKerosene(client);
	}	
	if(WeaponID == 14)
	{
		UpgradeSafetyFuse(client);
		CreateTimer(1.0, timer_SafetyFuseStop, client);
	}
	if(iUpgrade[client][26] > 0 && (WeaponID == 13 || WeaponID == 14 || WeaponID == 25))
	{
		UpgradeGrenadePouch(client);
	}
}

public Action event_WeaponReload(Event event, const char[] name, bool dontBroadcast) 
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	iActiveWeapon[client] = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
	UpgradeHighCapacityMag(client);
}

public Action event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast) 
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(client > 0 && GetClientTeam(client) == 2)
	{
		CreateTimer(2.0, event_TimerPlayerSpawn, client);
	}
}

public Action event_PlayerDeath(Event event, const char[] name, bool dontBroadcast) 
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new entityid = GetEventInt(event, "entityid");
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new bool:headshot = GetEventBool(event, "headshot");
	
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
	
	if(client > 0 && IsClientInGame(client) && GetClientTeam(client) == 2)
	{
		for(new i = 0; i < 2; i++)
		{
			if(!StrEqual(iPrimaryItems[client][i], ""))
			{
				GivePlayerItem(client, iPrimaryItems[client][i]);
				iPrimaryItems[client][i] = "";
			}
			if(!StrEqual(iSecondaryItems[client][i], ""))
			{
				GivePlayerItem(client, iSecondaryItems[client][i]);
				iSecondaryItems[client][i] = "";
			}
			if(!StrEqual(iGrenadeItems[client][i], ""))
			{
				GivePlayerItem(client, iGrenadeItems[client][i]);
				iGrenadeItems[client][i] = "";
			}
		}
	}
	if(headshot == true && entityid > 0)
	{
		UpgradeOcularImplants(attacker, entityid);
	}
}

public Action:event_TimerPlayerSpawn(Handle:timer, any:client)
{
	if(b_round_end == true || !IsClientInGame(client) || !IsPlayerAlive(client) || HasIdlePlayer(client))
	{
		return;
	}
	if(!IsFakeClient(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client))
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
		if(iUpgrade[client][3] > 0)
		{
			//SetEntProp(client, Prop_Send, "m_ArmorValue", 4000);
			SetEntData(client, FindDataMapOffs(client, "m_ArmorValue"), 4000, 4, true);
		}
		else
		{
			//SetEntProp(client, Prop_Send, "m_ArmorValue", 0);
			SetEntData(client, FindDataMapOffs(client, "m_ArmorValue"), 0, 4, true);
		}
		if(iUpgrade[client][22] > 0 || iUpgrade[client][23] > 0 || iUpgrade[client][29] > 0)
		{
			new iMaxHealth = 0;
			if(iUpgrade[client][22] > 0)
				iMaxHealth += 50;
			if(iUpgrade[client][23] > 0)
				iMaxHealth += 50;
			if(iUpgrade[client][29] > 0)
				iMaxHealth += 50;

			SetEntProp(client, Prop_Send, "m_iMaxHealth", 100 + iMaxHealth);
		}
		else
		{
			SetEntProp(client, Prop_Send, "m_iMaxHealth", 100);
		}
		if(iUpgrade[client][2] > 0)
		{
			UpgradeLaserSight(client);
		}
	}
	if(IsClientInGame(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client) && iBitsUpgrades[client] > 0)
	{
		EmitSoundToClient(client, "player/orch_hit_Csharp_short.wav");
	}
}

public Action event_ItemPickup(Event event, const char[] name, bool dontBroadcast) 
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new String:iWeaponName[32];
	GetEventString(event, "item", iWeaponName, 32);

	if(client > 0)
	{
		if(iUpgrade[client][2] > 0)
		{
			UpgradeLaserSight(client);
		}
		if(iUpgrade[client][6] > 0)
		{
			if(StrContains(iWeaponName, "smg", false) != -1 || StrContains(iWeaponName, "rifle", false) != -1 || StrContains(iWeaponName, "shotgun", false) != -1 || StrContains(iWeaponName, "sniper", false) != -1)
			{
				CustomGivePlayerAmmo(client);
			}
			if(StrEqual(iWeaponName, "weapon_rifle_m60"))
			{
				UpgradeBandoliers(client);
			}
		}
	}
}

public Action:event_PlayerUse(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	decl String:item[64];
	new targetid = GetEventInt(event, "targetid");
	if(targetid > 0)
	{
		GetEdictClassname(targetid, item, sizeof(item));
		if(StrContains(item, "ammo", false) != -1)
		{
			ClearPlayerAmmo(client);
			CheatCommand(client, "give", "ammo", "");
			CustomGivePlayerAmmo(client);
			if(iUpgrade[client][14] > 0)
			{
				UpgradeBandoliers(client);
			}
		}
	}

	if(iUpgrade[client][26] > 0 && GetPlayerWeaponSlot(client, 2) > 0)
	{
		decl String:iWeaponName[LEN64];
		if(targetid != -1)
		{
			GetEdictClassname(targetid, iWeaponName, sizeof(iWeaponName));
			if(StrContains(iWeaponName, "molotov", false) != -1 || StrContains(iWeaponName, "pipe_bomb", false) != -1 || StrContains(iWeaponName, "vomitjar", false) != -1)
			{
				if((StrContains(iWeaponName, "_spawn", false) != -1 && GetEntProp(targetid, Prop_Data, "m_itemCount") > 0) || (StrContains(iWeaponName, "_spawn", false) == -1 && GetEntPropEnt(targetid, Prop_Data, "m_hOwner") != client))
				{
					new slot = GetAvailableExtraSlot(client, 0);
					if(slot != -1)
					{
						if(StrContains(iWeaponName, "_spawn", false) != -1 && GetEntProp(targetid, Prop_Data, "m_itemCount") > 0)
							SetEntProp(targetid, Prop_Data, "m_itemCount", 0);
						AcceptEntityInput(targetid, "kill");
						ReplaceStringEx(iWeaponName, sizeof(iWeaponName), "_spawn", "");
						iGrenadeItems[client][slot] = iWeaponName;
						if(StrContains(iWeaponName, "molotov", false) != -1)
							PrintToChat(client, "You picked up an Extra Molotov.");
						if(StrContains(iWeaponName, "pipe_bomb", false) != -1)
							PrintToChat(client, "You picked up an Extra Pipe Bomb.");
						if(StrContains(iWeaponName, "vomitjar", false) != -1)
							PrintToChat(client, "You picked up an Extra Vomit Jar.");
						EmitSoundToClient(client, "sound/items/itempickup.wav");
						return Plugin_Handled;
					}
				}
			}
		}
	}
	if(iUpgrade[client][19] > 0 || iUpgrade[client][27] > 0 && GetPlayerWeaponSlot(client, 3) > 0)
	{
		decl String:iWeaponName[LEN64];
		if(targetid != -1)
		{
			GetEdictClassname(targetid, iWeaponName, sizeof(iWeaponName));
			if(StrContains(iWeaponName, "first_aid_kit", false) != -1 || StrContains(iWeaponName, "defibrillator", false) != -1 || StrContains(iWeaponName, "upgradepack_explosive", false) != -1 || StrContains(iWeaponName, "upgradepack_incendiary", false) != -1)
			{
				if((StrContains(iWeaponName, "_spawn", false) != -1 && GetEntProp(targetid, Prop_Data, "m_itemCount") > 0) || (StrContains(iWeaponName, "_spawn", false) == -1 && GetEntPropEnt(targetid, Prop_Data, "m_hOwner") != client))
				{
					new slot = GetAvailableExtraSlot(client, 1);
					if(slot != -1)
					{
						if(StrContains(iWeaponName, "_spawn", false) != -1 && GetEntProp(targetid, Prop_Data, "m_itemCount") > 0)
							SetEntProp(targetid, Prop_Data, "m_itemCount", 0);
						AcceptEntityInput(targetid, "kill");
						ReplaceStringEx(iWeaponName, sizeof(iWeaponName), "_spawn", "");
						iPrimaryItems[client][slot] = iWeaponName;
						if(StrContains(iWeaponName, "first_aid_kit", false) != -1)
							PrintToChat(client, "You picked up an Extra First Aid Kit.");
						if(StrContains(iWeaponName, "defibrillator", false) != -1)
							PrintToChat(client, "You picked up an Extra Defibrillator.");
						if(StrContains(iWeaponName, "upgradepack_explosive", false) != -1)
							PrintToChat(client, "You picked up an Extra Explosive Pack.");
						if(StrContains(iWeaponName, "upgradepack_incendiary", false) != -1)
							PrintToChat(client, "You picked up an Extra Incendiary Pack.");
						return Plugin_Handled;
					}
				}
			}
		}
	}
	if(iUpgrade[client][20] > 0 || iUpgrade[client][25] > 0 && GetPlayerWeaponSlot(client, 4) > 0)
	{
		decl String:iWeaponName[LEN64];
		if(targetid != -1)
		{
			GetEdictClassname(targetid, iWeaponName, sizeof(iWeaponName));
			if(StrContains(iWeaponName, "pain_pills", false) != -1 || StrContains(iWeaponName, "adrenaline", false) != -1)
			{
				if((StrContains(iWeaponName, "_spawn", false) != -1 && GetEntProp(targetid, Prop_Data, "m_itemCount") > 0) || (StrContains(iWeaponName, "_spawn", false) == -1 && GetEntPropEnt(targetid, Prop_Data, "m_hOwner") != client))
				{
					new slot = GetAvailableExtraSlot(client, 2);
					if(slot != -1)
					{
						if(StrContains(iWeaponName, "_spawn", false) != -1 && GetEntProp(targetid, Prop_Data, "m_itemCount") > 0)
							SetEntProp(targetid, Prop_Data, "m_itemCount", 0);
						AcceptEntityInput(targetid, "kill");
						ReplaceStringEx(iWeaponName, sizeof(iWeaponName), "_spawn", "");
						iSecondaryItems[client][slot] = iWeaponName;
						if(StrContains(iWeaponName, "pain_pills", false) != -1)
							PrintToChat(client, "You picked up an Extra Pain Pills.");
						if(StrContains(iWeaponName, "adrenaline", false) != -1)
							PrintToChat(client, "You picked up an Extra Adrenaline.");
						return Plugin_Handled;
					}
				}
			}
		}
	}
	/*if((iUpgrade[client][20] > 0 || iUpgrade[client][25] > 0) && GetPlayerWeaponSlot(client, 4) > 0)
	{
		new maxslots = 0;
		if(iUpgrade[client][20] > 0)
			maxslots++;
		if(iUpgrade[client][25] > 0)
			maxslots++;
			
		for(new i = 0; i < maxslots; i++)
		{
			if(StrEqual(iSecondaryItems[client][i], ""))
			{
				//PrintToChat(client, "You picked up an Extra %s.", item);
				if(StrContains(item, "pain_pills", false) != -1)
				{
					if(StrContains(item, "_spawn", false) != -1 && GetEntProp(targetid, Prop_Data, "m_itemCount") > 0)
					{
						PrintToChat(client, "You picked up an Extra Pain Pills.");
						AcceptEntityInput(targetid, "kill");
						SetEntProp(targetid, Prop_Data, "m_itemCount", 0);
						iSecondaryItems[client][i] = item;
						return Plugin_Handled;
					}
					else if(StrContains(item, "_spawn", false) == -1 && GetEntPropEnt(targetid, Prop_Data, "m_hOwner") != client)
					{
						PrintToChat(client, "You picked up an Extra Pain Pills.");
						AcceptEntityInput(targetid, "kill");
						iSecondaryItems[client][i] = item;
						return Plugin_Handled;
					}
				}
				if(StrContains(item, "adrenaline", false) != -1)
				{
					if(StrContains(item, "_spawn", false) != -1 && GetEntProp(targetid, Prop_Data, "m_itemCount") > 0)
					{
						PrintToChat(client, "You picked up an Extra Adrenaline.");
						AcceptEntityInput(targetid, "kill");
						SetEntProp(targetid, Prop_Data, "m_itemCount", 0);
						iSecondaryItems[client][i] = item;
						return Plugin_Handled;
					}
					else if(StrContains(item, "_spawn", false) == -1 && GetEntPropEnt(targetid, Prop_Data, "m_hOwner") != client)
					{
						PrintToChat(client, "You picked up an Extra Adrenaline.");
						AcceptEntityInput(targetid, "kill");
						iSecondaryItems[client][i] = item;
						return Plugin_Handled;
					}
				}
			}
		}
	}
	if((iUpgrade[client][19] > 0 || iUpgrade[client][27] > 0) && GetPlayerWeaponSlot(client, 3) > 0)
	{
		new maxslots = 0;
		if(iUpgrade[client][19] > 0)
			maxslots++;
		if(iUpgrade[client][27] > 0)
			maxslots++;
			
		for(new i = 0; i < maxslots; i++)
		{
			if(StrEqual(iPrimaryItems[client][i], ""))
			{
				if(StrContains(item, "first_aid_kit", false) != -1)
				{
					if(StrContains(item, "_spawn", false) != -1 && GetEntProp(targetid, Prop_Data, "m_itemCount") > 0)
					{
						PrintToChat(client, "You picked up an Extra First Aid Kit.");
						AcceptEntityInput(targetid, "kill");
						SetEntProp(targetid, Prop_Data, "m_itemCount", 0);
						iPrimaryItems[client][i] = item;
						return Plugin_Handled;
					}
					else if(StrContains(item, "_spawn", false) == -1 && GetEntPropEnt(targetid, Prop_Data, "m_hOwner") != client)
					{
						PrintToChat(client, "You picked up an Extra First Aid Kit.");
						AcceptEntityInput(targetid, "kill");
						iPrimaryItems[client][i] = item;
						return Plugin_Handled;
					}
				}
				if(StrContains(item, "defibrillator", false) != -1)
				{
					if(StrContains(item, "_spawn", false) != -1 && GetEntProp(targetid, Prop_Data, "m_itemCount") > 0)
					{
						PrintToChat(client, "You picked up an Extra Defibrillator.");
						AcceptEntityInput(targetid, "kill");
						SetEntProp(targetid, Prop_Data, "m_itemCount", 0);
						iPrimaryItems[client][i] = item;
						return Plugin_Handled;
					}
					else if(StrContains(item, "_spawn", false) == -1 && GetEntPropEnt(targetid, Prop_Data, "m_hOwner") != client)
					{
						PrintToChat(client, "You picked up an Extra Defibrillator.");
						AcceptEntityInput(targetid, "kill");
						iPrimaryItems[client][i] = item;
						return Plugin_Handled;
					}
				}
				if(StrContains(item, "upgradepack_explosive", false) != -1)
				{
					if(StrContains(item, "_spawn", false) != -1 && GetEntProp(targetid, Prop_Data, "m_itemCount") > 0)
					{
						PrintToChat(client, "You picked up an Extra Explosive Pack.");
						AcceptEntityInput(targetid, "kill");
						SetEntProp(targetid, Prop_Data, "m_itemCount", 0);
						iPrimaryItems[client][i] = item;
						return Plugin_Handled;
					}
					else if(StrContains(item, "_spawn", false) == -1 && GetEntPropEnt(targetid, Prop_Data, "m_hOwner") != client)
					{
						PrintToChat(client, "You picked up an Extra Explosive Pack.");
						AcceptEntityInput(targetid, "kill");
						iPrimaryItems[client][i] = item;
						return Plugin_Handled;
					}
				}
				if(StrContains(item, "upgradepack_incendiary", false) != -1)
				{
					if(StrContains(item, "_spawn", false) != -1 && GetEntProp(targetid, Prop_Data, "m_itemCount") > 0)
					{
						PrintToChat(client, "You picked up an Extra Incendiary Pack.");
						AcceptEntityInput(targetid, "kill");
						SetEntProp(targetid, Prop_Data, "m_itemCount", 0);
						iPrimaryItems[client][i] = item;
						return Plugin_Handled;
					}
					else if(StrContains(item, "_spawn", false) == -1 && GetEntPropEnt(targetid, Prop_Data, "m_hOwner") != client)
					{
						PrintToChat(client, "You picked up an Extra Incendiary Pack.");
						AcceptEntityInput(targetid, "kill");
						iPrimaryItems[client][i] = item;
						return Plugin_Handled;
					}
				}
			}
		}
	}*/
	return Plugin_Handled;
}

public event_AmmoPickup(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event,"userid"));
	if (client == 0)
		return;

	if(client > 0 && iUpgrade[client][6] > 0)
	{
		CustomGivePlayerAmmo(client);
	}
}
public event_KnifeCooldownCheck(Handle:event, const String:name[], bool:dontBroadcast) 
{
	new victim = GetClientOfUserId(GetEventInt(event,"victim"));
	iKnifeReady = true;
	if(KnifeCooldownTimer[victim] == INVALID_HANDLE)
	{
		KnifeCooldownTimer[victim] = CreateTimer(1.0, timer_KnifeCooldownTimer, victim);
	}
}

public event_KnifeUnReady(Handle:event, const String:name[], bool:dontBroadcast) 
{
	iKnifeReady = false;
}

public event_WeaponGiven(Handle:event, const String:name[], bool:dontBroadcast) 
{
	// 15 - Pain Pills, 23 - Adrenaline Shot
	new client = GetClientOfUserId(GetEventInt(event,"giver"));
	new weapon = GetEventInt(event,"weapon");

	if(weapon == 15 || weapon == 23)
	{
		UpgradeSecondaryItems(client);
	}
}

public Action:OnPreThink(client)
{
	new ActiveWeapon = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
	decl String:WEAPON_NAME[64];
	
	if(ActiveWeapon == -1)
		return;
		
	GetEdictClassname(ActiveWeapon, WEAPON_NAME, sizeof(WEAPON_NAME));
	
	new m_bInReload = GetEntProp(ActiveWeapon, Prop_Send, "m_bInReload");
	
	if(StrContains(WEAPON_NAME, "shotgun", false) != -1 || ActiveWeapon != iActiveWeapon[client])
	{
		SDKUnhook(client, SDKHook_PreThink, OnPreThink);
		return;
	}	
	if(m_bInReload)
	{
		// Do Nothing
	}
	else
	{
		new m_iClip1 = GetEntProp(ActiveWeapon, Prop_Send, "m_iClip1");
		new m_iAmmo = GetEntData(client, (FindDataMapOffs(client, "m_iAmmo") + CheckWeaponAmmoType(ActiveWeapon))); 
		new button=GetClientButtons(client);
		
		if(CheckWeaponUpgradeLimit(ActiveWeapon, client, false) == m_iClip1 && (button & IN_RELOAD))
		{
			SetEntProp(ActiveWeapon, Prop_Send, "m_iClip1", 0, 4);
		}
		else if(m_iClip1 > 0)
		{
			if(StrEqual(WEAPON_NAME, "weapon_pistol") || StrEqual(WEAPON_NAME, "weapon_pistol_magnum"))
			{
				SetEntProp(ActiveWeapon, Prop_Send, "m_iClip1", CheckWeaponUpgradeLimit(ActiveWeapon, client, true), 4);
			}

			else
			{
				if(m_iAmmo < RoundToFloor(float(CheckWeaponUpgradeLimit(ActiveWeapon, client, false)))*0.5)
				{
					SetEntProp(ActiveWeapon, Prop_Send, "m_iClip1", m_iClip1 + m_iAmmo, 4);
					SetEntData(client, (FindDataMapOffs(client, "m_iAmmo") + CheckWeaponAmmoType(ActiveWeapon)), 0, 4, true);
				}
				else
				{
					SetEntProp(ActiveWeapon, Prop_Send, "m_iClip1", CheckWeaponUpgradeLimit(ActiveWeapon, client, true), 4);
					SetEntData(client, (FindDataMapOffs(client, "m_iAmmo") + CheckWeaponAmmoType(ActiveWeapon)), m_iAmmo - RoundToFloor(float(CheckWeaponUpgradeLimit(ActiveWeapon, client, false))*0.5), 4, true);
				}
			}
			SDKUnhook(client, SDKHook_PreThink, OnPreThink);
		}
	}
}

public Action:OnWeaponCanUse(client, weapon)
{
	if(iUpgrade[client][26] > 0)
	{
		decl String:iWeaponName[LEN64];
		if(weapon != -1)
		{
			GetEdictClassname(weapon, iWeaponName, sizeof(iWeaponName));
			if(StrContains(iWeaponName, "molotov", false) != -1 || StrContains(iWeaponName, "pipe_bomb", false) != -1 || StrContains(iWeaponName, "vomitjar", false) != -1)
			{
				if(GetPlayerWeaponSlot(client, 2) > 0 && GetAvailableExtraSlot(client, 0) != -1)
				{
					return Plugin_Handled;
				}
			}
		}
	}
	if(iUpgrade[client][19] > 0 || iUpgrade[client][27] > 0)
	{
		decl String:iWeaponName[LEN64];
		if(weapon != -1)
		{
			GetEdictClassname(weapon, iWeaponName, sizeof(iWeaponName));
			if(StrContains(iWeaponName, "first_aid_kit", false) != -1 || StrContains(iWeaponName, "defibrillator", false) != -1 || StrContains(iWeaponName, "upgradepack_explosive", false) != -1 || StrContains(iWeaponName, "upgradepack_incendiary", false) != -1)
			{
				if(GetPlayerWeaponSlot(client, 3) > 0 && GetAvailableExtraSlot(client, 1) != -1)
				{
					return Plugin_Handled;
				}
			}
		}
	}
	if(iUpgrade[client][20] > 0 || iUpgrade[client][25] > 0)
	{
		decl String:iWeaponName[LEN64];
		if(weapon != -1)
		{
			GetEdictClassname(weapon, iWeaponName, sizeof(iWeaponName));
			if(StrContains(iWeaponName, "pain_pills", false) != -1 || StrContains(iWeaponName, "adrenaline", false) != -1)
			{
				if(GetPlayerWeaponSlot(client, 4) > 0 && GetAvailableExtraSlot(client, 2) != -1)
				{
					return Plugin_Handled;
				}
			}
		}
	}
	return Plugin_Continue;
}

GetAvailableExtraSlot(client, type)
{
	if(type == 0)
	{
		new maxslots = 0;
		if(iUpgrade[client][26] > 0)
			maxslots = 2;
		for(new slot = 0; slot < maxslots; slot++)
		{
			if(StrEqual(iGrenadeItems[client][slot], ""))
			{
				return slot;
			}
		}
		return -1;
	}
	if(type == 1)
	{
		new maxslots = 0;
		if(iUpgrade[client][19] > 0)
			maxslots++;
		if(iUpgrade[client][27] > 0)
			maxslots++;
		for(new slot = 0; slot < maxslots; slot++)
		{
			if(StrEqual(iPrimaryItems[client][slot], ""))
			{
				return slot;
			}
		}
		return -1;
	}
	if(type == 2)
	{
		new maxslots = 0;
		if(iUpgrade[client][20] > 0)
			maxslots++;
		if(iUpgrade[client][25] > 0)
			maxslots++;
		for(new slot = 0; slot < maxslots; slot++)
		{
			if(StrEqual(iSecondaryItems[client][slot], ""))
			{
				return slot;
			}
		}
		return -1;
	}
	return -1;
}

CustomGivePlayerAmmo(client)
{
	new iWEAPON = GetPlayerWeaponSlot(client, 0);
	if(iWEAPON > 0)
	{
		//GetEntProp(iWEAPON, Prop_Send, "m_iClip1");
		new m_iAmmo = FindDataMapOffs(client, "m_iAmmo");

		if(iUpgrade[client][6] > 0)
		{
			SetEntData(client, m_iAmmo+RIFLE_OFFSET_AMMO, RoundToNearest((RIFLE_AMMO * (1.5))) + (CheckWeaponUpgradeLimit(iWEAPON, client, true) - GetEntProp(iWEAPON, Prop_Send, "m_iClip1")));
			SetEntData(client, m_iAmmo+SMG_OFFSET_AMMO, RoundToNearest((SMG_AMMO * (1.5))) + (CheckWeaponUpgradeLimit(iWEAPON, client, true) - GetEntProp(iWEAPON, Prop_Send, "m_iClip1")));
			SetEntData(client, m_iAmmo+SHOTGUN_OFFSET_AMMO, RoundToNearest((SHOTGUN_AMMO * (1.5))) + (CheckWeaponUpgradeLimit(iWEAPON, client, true) - GetEntProp(iWEAPON, Prop_Send, "m_iClip1")));
			SetEntData(client, m_iAmmo+AUTOSHOTGUN_OFFSET_AMMO, RoundToNearest((AUTOSHOTGUN_AMMO * (1.5))) + (CheckWeaponUpgradeLimit(iWEAPON, client, true) - GetEntProp(iWEAPON, Prop_Send, "m_iClip1")));
			SetEntData(client, m_iAmmo+HUNTING_RIFLE_OFFSET_AMMO, RoundToNearest((HUNTING_RIFLE_AMMO * (1.5))) + (CheckWeaponUpgradeLimit(iWEAPON, client, true) - GetEntProp(iWEAPON, Prop_Send, "m_iClip1")));
			SetEntData(client, m_iAmmo+SNIPER_OFFSET_AMMO, RoundToNearest((SNIPER_AMMO * (1.5))) + (CheckWeaponUpgradeLimit(iWEAPON, client, true) - GetEntProp(iWEAPON, Prop_Send, "m_iClip1")));
		}
		else
		{
			SetEntData(client, m_iAmmo+RIFLE_OFFSET_AMMO, GetConVarInt(FindConVar("ammo_assaultrifle_max")) + (CheckWeaponUpgradeLimit(iWEAPON, client, true) - GetEntProp(iWEAPON, Prop_Send, "m_iClip1")));
			SetEntData(client, m_iAmmo+SMG_OFFSET_AMMO, GetConVarInt(FindConVar("ammo_smg_max")) + (CheckWeaponUpgradeLimit(iWEAPON, client, true) - GetEntProp(iWEAPON, Prop_Send, "m_iClip1")));
			SetEntData(client, m_iAmmo+SHOTGUN_OFFSET_AMMO, GetConVarInt(FindConVar("ammo_shotgun_max")) + (CheckWeaponUpgradeLimit(iWEAPON, client, true) - GetEntProp(iWEAPON, Prop_Send, "m_iClip1")));
			SetEntData(client, m_iAmmo+AUTOSHOTGUN_OFFSET_AMMO, GetConVarInt(FindConVar("ammo_autoshotgun_max")) + (CheckWeaponUpgradeLimit(iWEAPON, client, true) - GetEntProp(iWEAPON, Prop_Send, "m_iClip1")));
			SetEntData(client, m_iAmmo+HUNTING_RIFLE_OFFSET_AMMO, GetConVarInt(FindConVar("ammo_huntingrifle_max")) + (CheckWeaponUpgradeLimit(iWEAPON, client, true) - GetEntProp(iWEAPON, Prop_Send, "m_iClip1")));
			SetEntData(client, m_iAmmo+SNIPER_OFFSET_AMMO, GetConVarInt(FindConVar("ammo_sniperrifle_max")) + (CheckWeaponUpgradeLimit(iWEAPON, client, true) - GetEntProp(iWEAPON, Prop_Send, "m_iClip1")));
		}
	}
}

ClearPlayerAmmo(client)
{
	new m_iAmmo = FindDataMapOffs(client, "m_iAmmo");
	SetEntData(client, m_iAmmo+RIFLE_OFFSET_AMMO, 0);
	SetEntData(client, m_iAmmo+SMG_OFFSET_AMMO, 0);
	SetEntData(client, m_iAmmo+SHOTGUN_OFFSET_AMMO, 0);
	SetEntData(client, m_iAmmo+AUTOSHOTGUN_OFFSET_AMMO, 0);
	SetEntData(client, m_iAmmo+HUNTING_RIFLE_OFFSET_AMMO, 0);
	SetEntData(client, m_iAmmo+SNIPER_OFFSET_AMMO, 0);
}


CheckWeaponUpgradeLimit(weapon, client, bool:status)
{
	new UpgradeLimit = 0;
	decl String:WEAPON_NAME[64];
	GetEdictClassname(weapon, WEAPON_NAME, 32);

	if(StrEqual(WEAPON_NAME, "weapon_rifle") || StrEqual(WEAPON_NAME, "weapon_rifle_sg552") || StrEqual(WEAPON_NAME, "weapon_smg") || StrEqual(WEAPON_NAME, "weapon_smg_silenced") || StrEqual(WEAPON_NAME, "weapon_smg_mp5"))
	{
		UpgradeLimit = 50;
	}
	else if(StrEqual(WEAPON_NAME, "weapon_rifle_desert"))
	{		 
		UpgradeLimit = 60;
	}			
	else if(StrEqual(WEAPON_NAME, "weapon_rifle_ak47"))
	{
		UpgradeLimit = 40;
	}
	else if(StrEqual(WEAPON_NAME, "weapon_pumpshotgun") || StrEqual(WEAPON_NAME, "weapon_shotgun_chrome"))
	{
		UpgradeLimit = 8;
	}
	else if(StrEqual(WEAPON_NAME, "weapon_autoshotgun") || StrEqual(WEAPON_NAME, "weapon_shotgun_spas"))
	{
		UpgradeLimit = 10;
	}
	else if(StrEqual(WEAPON_NAME, "weapon_hunting_rifle") || StrEqual(WEAPON_NAME, "weapon_sniper_scout"))
	{
		UpgradeLimit = 15;
	}
	else if(StrEqual(WEAPON_NAME, "weapon_sniper_awp"))
	{
		UpgradeLimit = 20;
	}
	else if(StrEqual(WEAPON_NAME, "weapon_sniper_military"))
	{
		UpgradeLimit = 30;
	}
	else if(StrEqual(WEAPON_NAME, "weapon_grenade_launcher"))
	{
		UpgradeLimit = 1;
	}
	else if(StrEqual(WEAPON_NAME, "weapon_pistol"))
	{
		if(GetEntProp(weapon, Prop_Send, "m_isDualWielding") > 0)
		{
			UpgradeLimit = 30;
		}
		else
		{
			UpgradeLimit = 15;
		}
	}
	else if(StrEqual(WEAPON_NAME, "weapon_pistol_magnum"))
	{
		UpgradeLimit = 8;
	}
	if(iUpgrade[client][21] > 0 && status == true)
	{
		UpgradeLimit = RoundFloat(UpgradeLimit * 1.5);
	}
	return UpgradeLimit;
}

CheckWeaponAmmoType(weapon)
{
	new AmmoType = 0;
	decl String:WEAPON_NAME[64];
	GetEdictClassname(weapon, WEAPON_NAME, 32);

	if(StrEqual(WEAPON_NAME, "weapon_smg") || StrEqual(WEAPON_NAME, "weapon_smg_silenced") || StrEqual(WEAPON_NAME, "weapon_smg_mp5"))
	{
		AmmoType = SMG_OFFSET_AMMO;
	}
	if(StrEqual(WEAPON_NAME, "weapon_rifle") || StrEqual(WEAPON_NAME, "weapon_rifle_desert") || StrEqual(WEAPON_NAME, "weapon_rifle_ak47"))
	{
		AmmoType = RIFLE_OFFSET_AMMO;
	}
	else if(StrEqual(WEAPON_NAME, "weapon_pumpshotgun") || StrEqual(WEAPON_NAME, "weapon_shotgun_chrome"))
	{
		AmmoType = SHOTGUN_OFFSET_AMMO;
	}
	else if(StrEqual(WEAPON_NAME, "weapon_autoshotgun") || StrEqual(WEAPON_NAME, "weapon_shotgun_spas"))
	{
		AmmoType = AUTOSHOTGUN_OFFSET_AMMO;
	}
	else if(StrEqual(WEAPON_NAME, "weapon_hunting_rifle") || StrEqual(WEAPON_NAME, "weapon_sniper_scout"))
	{
		AmmoType = HUNTING_RIFLE_OFFSET_AMMO;
	}
	else if(StrEqual(WEAPON_NAME, "weapon_sniper_military"))
	{
		AmmoType = SNIPER_OFFSET_AMMO;
	}
	else if(StrEqual(WEAPON_NAME, "weapon_grenade_launcher"))
	{
		AmmoType = GRENADE_LAUNCHER_OFFSET_AMMO;
	}
	return AmmoType;
}

public OnClientDisconnect(client)
{
	if(IsClientInGame(client) && GetClientTeam(client) != 3)
		SaveData(client);
}

public GiveSurvivorUpgrade(client, amount, awardid)
{
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
					PrintToChat(i, "\x04%s \x01earned %s from %s.", ClientUserName, UpgradeTitle[val], AwardTitle[awardid]);
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
				if(IsClientInGame(i) && iAnnounceText[i] == 1 && GetClientTeam(i) == 2)
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
		if(client > 0 && i == upgrade)
		{
			iUpgrade[client][upgrade] = UpgradeIndex[upgrade];
			iBitsUpgrades[client] += iUpgrade[client][upgrade];
			SetClientUpgradesCheck(client);
		}
	}
}

public RemoveUpgrade(client, upgrade)
{
	for(new i = 0; i < MAX_UPGRADES; i++)
	{
		if(client > 0 && i == upgrade)
		{
			iUpgrade[client][upgrade] = 0;
			iBitsUpgrades[client] -= UpgradeIndex[upgrade];
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

public Action:UpgradeLaserSightToggle(client, args)
{
	if(GetClientTeam(client) == 2)
	{
		if(iUpgrade[client][2] == 0 && GetConVarInt(UpgradeEnabled[2]) == 1 && iUpgradeDisabled[client][2] != 1)
		{
			PrintToChat(client, "\x01Laser Sight is \x04On\x01.");
			GiveUpgrade(client, 2);
		}
		else if(iUpgrade[client][17] > 0)
		{
			PrintToChat(client, "\x01Laser Sight is \x04Off\x01.");
			RemoveUpgrade(client, 2);
		}
		else if(iUpgradeDisabled[client][2] == 1)
		{
			PrintToChat(client, "\x01Laser Sight is \x04Disabled\x01. Please \x04Enable \x01Laser Sight before using the command.");
		}
	}
	else
	{
		PrintToChat(client, "\x01You must be on the \x04Survivor Team\x01.");
	}
}

public Action:PrintToChatUpgrades(client, args)
{
	DisplayUpgradeMenu(client);
}

public Action:OpenPerkMenu(client, args)
{
	PerkMenu(client);
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
	new Handle:gMenu = CreatePanel();

	decl String:buffer[MAX_TARGET_LENGTH];
	Format(buffer, sizeof(buffer), "Options");
	SetPanelTitle(gMenu, buffer);
	
	DrawPanelText(gMenu, "You can change configurations in \nthis menu by selecting options for your \ngameplay experience.");
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
	DrawPanelItem(gMenu, savefeature);
	DrawPanelItem(gMenu, notification);
	DrawPanelItem(gMenu, "Toggle Upgrades");
	DrawPanelItem(gMenu, "View Awards");
	if(GetConVarInt(g_PerkMode) == 1)
		DrawPanelItem(gMenu, "Give Bots Perks");
	DrawPanelItem(gMenu, "Reset Upgrades");
	DrawPanelItem(gMenu, "Reset Bots");
	
	SendPanelToClient(gMenu, client, OptionsMenuHandler, 30);
	CloseHandle(gMenu);
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
				for(new i = 1; i < MaxClients; i++)
				{
					if(IsClientInGame(i) && GetClientTeam(i) == 2 && IsFakeClient(i))
					{
						ResetClientUpgrades(i);
						GiveSurvivorUpgrade(i, GetConVarInt(PerkSlots) + iPerkBonusSlots[i], 0);
						iSaveFeature[i] = 1;
					}
				}
				PrintToChat(client, "\x01Bots have been given random \x04Perks\x01.");
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

public HelpMenu(client)
{
	new Handle:gMenu = CreatePanel();

	SetPanelTitle(gMenu, "Help");
	if(GetConVarInt(g_PerkMode) == 1)
		DrawPanelText(gMenu, "Current Mode: Perk Mode\n\nIn perk mode, each player must select \n the amount of perks they can use \ninstead of earning them from rewards.");
	else
		DrawPanelText(gMenu, "Current Mode: Perk Mode\n\nSurvivor Upgrades is a feature in	\nLeft 4 Dead where survivors obtain \nenhancements to their current gameplay. \nYou earn upgrades by positive actions, \nand lose by negative actions.");
	SendPanelToClient(gMenu, client, HelpMenuHandler, 30);
	CloseHandle(gMenu);
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
			for(new i = 0; i <= MAX_UPGRADES; i++)
			{
				if(StrEqual(item1, PerkTitle[i], false))
				{
					iUpgrade[client][i] = UpgradeIndex[i];
					PrintToChat(client, "%s", UpgradeTitle[i]);
					PerkMenu(client);
				}
			}
		}
	}
}

public UpgradesEnabledMenu(client)
{
	if(GetClientTeam(client) == 2)
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
		SetMenuTitle(menu, "Toggle Upgrades\nIn this menu you can toggle \nthe upgrades you wish to earn. Choose which \nupgrade you wish to toggle [Active/Inactive].");
		SetMenuExitButton(menu, true);
		DisplayMenu(menu, client, MENU_TIME_FOREVER);
	}
	else
	{
		PrintToChat(client, "\x01[\x03ERROR\x01] An Error occurred, please contact developer.");
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
			for(new i = 0; i <= MAX_UPGRADES; i++)
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

public event_AwardEarnedExtended(client, achievementid, penalty)
{
	if(GetConVarInt(g_PerkMode) == 1)
		return;
	
 	if(penalty == 0 && GetConVarInt(AwardIndex[achievementid]) > 0)
	{
		iCount[client][achievementid] += 1;
		if(iCount[client][achievementid] >= GetConVarInt(AwardIndex[achievementid]))
		{
			GiveSurvivorUpgrade(client, 1, achievementid);
			iCount[client][achievementid] = 0;
		}
	}
	if(penalty == 1 && GetConVarInt(AwardIndex[achievementid]) > 0)
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

public Action event_AwardEarned(Event event, const char[] name, bool dontBroadcast) 
{
	if(b_round_end == true || GetConVarInt(g_PerkMode) == 1)
		return;

	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new achievementid = GetEventInt(event, "award");
	
	if(AwardsCooldownTimer[client] != INVALID_HANDLE && achievementid == AwardsCooldownID[client])
	{
		return;
	}
	
	// 14 - Blind Luck
	if(achievementid == 14 && GetConVarInt(AwardIndex[achievementid]) > 0)
	{
		iCount[client][achievementid] += 1;
		if(iCount[client][achievementid] >= GetConVarInt(AwardIndex[achievementid]))
		{
			GiveSurvivorUpgrade(client, 1, achievementid);
			iCount[client][achievementid] = 0;
		}
	}
	// 15 - Pyrotechnician
	if(achievementid == 15 && GetConVarInt(AwardIndex[achievementid]) > 0)
	{
		iCount[client][achievementid] += 1;
		if(iCount[client][achievementid] >= GetConVarInt(AwardIndex[achievementid]))
		{
			GiveSurvivorUpgrade(client, 1, achievementid);
			iCount[client][achievementid] = 0;
		}
	}
	// 18 - Witch Hunter
	if(achievementid == 18 && GetConVarInt(AwardIndex[achievementid]) > 0)
	{
		iCount[client][achievementid] += 1;
		if(iCount[client][achievementid] >= GetConVarInt(AwardIndex[achievementid]))
		{
			GiveSurvivorUpgrade(client, 1, achievementid);
			iCount[client][achievementid] = 0;
		}
	}
	// 19 - Crowned Witch
	if(achievementid == 19 && GetConVarInt(AwardIndex[achievementid]) > 0)
	{
		iCount[client][achievementid] += 1;
		if(iCount[client][achievementid] >= GetConVarInt(AwardIndex[achievementid]))
		{
			GiveSurvivorUpgrade(client, 1, achievementid);
			iCount[client][achievementid] = 0;
		}
	}
	// 21 - Dead Stop
	if(achievementid == 21 && GetConVarInt(AwardIndex[achievementid]) > 0)
	{
		iCount[client][achievementid] += 1;
		if(iCount[client][achievementid] >= GetConVarInt(AwardIndex[achievementid]))
		{
			GiveSurvivorUpgrade(client, 1, achievementid);
			iCount[client][achievementid] = 0;
		}
	}
	// 22 - Brawler
	if(achievementid == 22 && GetConVarInt(AwardIndex[achievementid]) > 0)
	{
		iCount[client][achievementid] += 1;
		if(iCount[client][achievementid] >= GetConVarInt(AwardIndex[achievementid]))
		{
			GiveSurvivorUpgrade(client, 1, achievementid);
			iCount[client][achievementid] = 0;
		}
	}
	// 26 - Boom-Cork
	if(achievementid == 26 && GetConVarInt(AwardIndex[achievementid]) > 0)
	{
		iCount[client][achievementid] += 1;
		if(iCount[client][achievementid] >= GetConVarInt(AwardIndex[achievementid]))
		{
			GiveSurvivorUpgrade(client, 1, achievementid);
			iCount[client][achievementid] = 0;
		}
	}
	// 27 - Tongue Twister
	if(achievementid == 27 && GetConVarInt(AwardIndex[achievementid]) > 0)
	{
		iCount[client][achievementid] += 1;
		if(iCount[client][achievementid] >= GetConVarInt(AwardIndex[achievementid]))
		{
			GiveSurvivorUpgrade(client, 1, achievementid);
			iCount[client][achievementid] = 0;
		}
	}
	// 66 - Helping Hand
	if(achievementid == 66 && GetConVarInt(AwardIndex[achievementid]) > 0)
	{
		iCount[client][achievementid] += 1;
		if(iCount[client][achievementid] >= GetConVarInt(AwardIndex[achievementid]))
		{
			GiveSurvivorUpgrade(client, 1, achievementid);
			iCount[client][achievementid] = 0;
		}
	}
	// 67 - My Bodyguard
	if(achievementid == 67 && GetConVarInt(AwardIndex[achievementid]) > 0)
	{
		iCount[client][achievementid] += 1;
		if(iCount[client][achievementid] >= GetConVarInt(AwardIndex[achievementid]))
		{
			GiveSurvivorUpgrade(client, 1, achievementid);
			iCount[client][achievementid] = 0;
		}
	}
	// 68 - Pharm-Assist
	if(achievementid == 68 && GetConVarInt(AwardIndex[achievementid]) > 0)
	{
		iCount[client][achievementid] += 1;
		if(iCount[client][achievementid] >= GetConVarInt(AwardIndex[achievementid]))
		{
			GiveSurvivorUpgrade(client, 1, achievementid);
			iCount[client][achievementid] = 0;
		}
	}
	// 69 - Adrenaline
	if(achievementid == 69 && GetConVarInt(AwardIndex[achievementid]) > 0)
	{
		iCount[client][achievementid] += 1;
		if(iCount[client][achievementid] >= GetConVarInt(AwardIndex[achievementid]))
		{
			GiveSurvivorUpgrade(client, 1, achievementid);
			iCount[client][achievementid] = 0;
		}
	}
	// 70 - Medic
	if(achievementid == 70 && GetConVarInt(AwardIndex[achievementid]) > 0)
	{
		iCount[client][achievementid] += 1;
		if(iCount[client][achievementid] >= GetConVarInt(AwardIndex[achievementid]))
		{
			GiveSurvivorUpgrade(client, 1, achievementid);
			iCount[client][achievementid] = 0;
		}
	}
	// 76 - Special Savior
	if(achievementid == 76 && GetConVarInt(AwardIndex[achievementid]) > 0)
	{
		iCount[client][achievementid] += 1;
		if(iCount[client][achievementid] >= GetConVarInt(AwardIndex[achievementid]))
		{
			GiveSurvivorUpgrade(client, 1, achievementid);
			iCount[client][achievementid] = 0;
		}
	}
	// 80 Hero Closet
	if(achievementid == 80 && GetConVarInt(AwardIndex[achievementid]) > 0)
	{
		iCount[client][achievementid] += 1;
		if(iCount[client][achievementid] >= GetConVarInt(AwardIndex[achievementid]))
		{
			GiveSurvivorUpgrade(client, 1, achievementid);
			iCount[client][achievementid] = 0;
		}
	}
	// 81 Tankbusters
	if(achievementid == 81 && GetConVarInt(AwardIndex[achievementid]) > 0)
	{
		iCount[client][achievementid] += 1;
		if(iCount[client][achievementid] >= GetConVarInt(AwardIndex[achievementid]))
		{
			GiveSurvivorUpgrade(client, 1, achievementid);
			iCount[client][achievementid] = 0;
		}
	}
	// 84 - Team-Kill
	if(achievementid == 84 && GetConVarInt(AwardIndex[achievementid]) > 0)
	{
		iCount[client][achievementid] += 1;
		if(iCount[client][achievementid] >= GetConVarInt(AwardIndex[achievementid]))
		{
			RemoveSurvivorUpgrade(client, 1, achievementid);
			iCount[client][achievementid] = 0;
		}
	}
	// 85 - Team-Incapacitate
	if(achievementid == 85 && GetConVarInt(AwardIndex[achievementid]) > 0)
	{
		iCount[client][achievementid] += 1;
		if(iCount[client][achievementid] >= GetConVarInt(AwardIndex[achievementid]))
		{
			RemoveSurvivorUpgrade(client, 1, achievementid);
			iCount[client][achievementid] = 0;
		}
	}
	// 87 - Friendly-Fire
	if(achievementid == 87 && GetConVarInt(AwardIndex[achievementid]) > 0)
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
	AwardsCooldownID[client] = achievementid;
}

public Action:event_AwardsCooldownTimer(Handle:timer, any:client)
{
	AwardsCooldownTimer[client] = INVALID_HANDLE;
}

public Action:round_start(Handle:event, const String:name[], bool:dontBroadcast)
{
	b_round_end = false;
}

public Action:round_end(Handle:event, const String:name[], bool:dontBroadcast)
{
	b_round_end = true;
	new MaxCount = MaxClients;
	for(new i=1; i<=MaxCount; i++)
	{
		if(IsClientInGame(i))
		{
			UpgradeHotMeal(i, 0);
		}
	}
}

public Action event_HealSuccess(Event event, const char[] name, bool dontBroadcast) 
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new subject = GetClientOfUserId(GetEventInt(event, "subject"));
	new health_restored = GetEventInt(event, "health_restored");

	new m_iMaxHealth = GetEntData(subject, FindDataMapOffs(subject, "m_iMaxHealth"), 4);

	if(iUpgrade[subject][3] > 0)
	{
		SetEntProp(subject, Prop_Send, "m_ArmorValue", 4000);
		SetEntProp(subject, Prop_Send, "m_bHasHelmet", 1);
	}
	new m_iCHealth = RoundFloat(float(m_iMaxHealth)-(250.0-(float(health_restored)/0.8)));
	new m_iHealth = RoundFloat((m_iMaxHealth-m_iCHealth)+m_iCHealth*0.8);

	SetEntData(subject, FindDataMapOffs(subject, "m_iHealth"), m_iHealth, 4, true);
	if(iUpgrade[client][5] > 0)
	{
		SetEntData(subject, FindDataMapOffs(subject, "m_iHealth"), m_iMaxHealth, 4, true);
	}
	UpgradePrimaryItem(client);
	UpgradeMedicalChart(client, subject, m_iCHealth);
}

public Action event_InfectedDeath(Event event, const char[] name, bool dontBroadcast) 
{
	new client = GetClientOfUserId(GetEventInt(event, "attacker"));
	new bool:headshot = GetEventBool(event, "headshot");

	if(headshot == true)
	{
		event_AwardEarnedExtended(client, 102, 0);
	}
	if(GetConVarInt(g_PerkMode))
	{
		if(GetRandomInt(0, 1000) == 1 && GetConVarInt(PerkBonusSlots) > iPerkBonusSlots[client])
		{
			iPerkBonusSlots[client]++;
			PrintToChat(client, "You have unlocked a new \x04Perk Slot\x01.");
		}
	}
}

public Action event_PillsUsed(Event event, const char[] name, bool dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	UpgradeSteroids(client, 1);
	UpgradeSecondaryItems(client);
}

public Action event_AdrenalineUsed(Event event, const char[] name, bool dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	UpgradeSteroids(client, 2);
	UpgradeSecondaryItems(client);
}

public Action event_DefibrillatorUsed(Event event, const char[] name, bool dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new subject = GetClientOfUserId(GetEventInt(event, "subject"));
	UpgradeHeavyDutyBatteries(client, subject);
	UpgradePrimaryItem(client);
}
public Action event_UpgradePackUsed(Event event, const char[] name, bool dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	UpgradePrimaryItem(client);
}

public Action event_ReceiveUpgrade(Event event, const char[] name, bool dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new String:upgrade[32];
	GetEventString(event, "upgrade", upgrade, sizeof(upgrade));

	if(StrEqual(upgrade, "EXPLOSIVE_AMMO") || StrEqual(upgrade, "INCENDIARY_AMMO"))
	{
		new iWEAPON = GetPlayerWeaponSlot(client, 0);
		SetEntProp(iWEAPON, Prop_Send, "m_nUpgradedPrimaryAmmoLoaded", CheckWeaponUpgradeLimit(iWEAPON, client, true), 4);
	}
	UpgradeBarrelChamber(client);
}

public Action event_ReviveSuccess(Event event, const char[] name, bool dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new subject = GetClientOfUserId(GetEventInt(event, "subject"));
	UpgradeBandages(client, subject);
	UpgradeMorphogenicCells(subject);
	UpgradeAutoinjectors(subject);
}

public Action event_PlayerIncapacitated(Event event, const char[] name, bool dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	UpgradeBetaBlockers(client);
	if(MorphogenicTimer[client] != INVALID_HANDLE)
	{
		KillTimer(MorphogenicTimer[client]);
		MorphogenicTimer[client] = INVALID_HANDLE;
	}
	if(RegenerationTimer[client] != INVALID_HANDLE)
	{
		KillTimer(RegenerationTimer[client]);
		RegenerationTimer[client] = INVALID_HANDLE;
	}
	event_AwardEarnedExtended(client, 106, 1);
}

public Action event_PlayerNowIt(Event event, const char[] name, bool dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new bool:exploded = GetEventBool(event, "exploded");

	if(exploded == true)
		event_AwardEarnedExtended(client, 104, 1);
	else
		event_AwardEarnedExtended(client, 103, 1);
}


public Action event_EnteredSpit(Event event, const char[] name, bool dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	event_AwardEarnedExtended(client, 105, 1);
}


public Action event_PlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new dmg_health = GetEventInt(event, "dmg_health");
	new health = GetEntData(client, FindDataMapOffs(client, "m_iHealth"), 4);	

	if(MorphogenicTimer[client] != INVALID_HANDLE)
	{
		KillTimer(MorphogenicTimer[client]);
		MorphogenicTimer[client] = INVALID_HANDLE;
	}
	if(RegenerationTimer[client] != INVALID_HANDLE)
	{
		KillTimer(RegenerationTimer[client]);
		RegenerationTimer[client] = INVALID_HANDLE;
	}
	UpgradeMorphogenicCells(client);
	UpgradeHollowPointAmmunition(client, attacker, dmg_health, health, 1);
	UpgradeHotMeal(client, 1);
}

public Action event_InfectedHurt(Event event, const char[] name, bool dontBroadcast)
{
	new entityid = (GetEventInt(event, "entityid"));
	new client = GetClientOfUserId(GetEventInt(event, "attacker"));
	new amount = GetEventInt(event, "amount");
	new health = GetEntProp(entityid, Prop_Data, "m_iHealth");	
	new type = GetEventInt(event, "type");

	if(type & 1 << 3 && client > 0)
	{
		event_AwardEarnedExtended(client, 100, 0);
	}
	UpgradeHollowPointAmmunition(entityid, client, amount, health, 2);
}

public Action:timer_MorphogenicTimer(Handle:timer, any:client)
{
	MorphogenicTimer[client] = INVALID_HANDLE;
	RegenerationTimer[client] = CreateTimer(0.1, timer_RegenerationTimer, client, TIMER_REPEAT);
}

public Action event_PlayerJump(Event event, const char[] name, bool dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(GetClientTeam(client) == 2)
	{
		UpgradeAirBoots(client);
	}
}

public Action event_HealBegin(Event event, const char[] name, bool dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	UpgradeQuickHeal(client);
}

public Action event_ReviveBegin(Event event, const char[] name, bool dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	UpgradeSmellingSalts(client);
}

public Action event_BreakProp(Event event, const char[] name, bool dontBroadcast) 
{
	new entindex = GetEventInt(event, "entindex");
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	UpgradeKeroseneShot(client, entindex);
}

public Action event_BotPlayerReplace(Event event, const char[] name, bool dontBroadcast) 
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

public UpgradeSteroids(client, type)
{
	if(type == 1)
	{
		new Float:m_iHealth = float(GetEntData(client, FindDataMapOffs(client, "m_iHealth"), 4));
		new Float:m_iMaxHealth = float(GetEntData(client, FindDataMapOffs(client, "m_iMaxHealth"), 4));
		new Float:m_iHealthBufferBits = GetConVarInt(FindConVar("pain_pills_health_value"))*0.5;
		new Float:m_iHealthBuffer = GetEntDataFloat(client, FindSendPropOffs("CTerrorPlayer","m_healthBuffer"));

		if(iUpgrade[client][7] > 0)
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
	if(type == 2)
	{
		new Float:m_iHealth = float(GetEntData(client, FindDataMapOffs(client, "m_iHealth"), 4));
		new Float:m_iMaxHealth = float(GetEntData(client, FindDataMapOffs(client, "m_iMaxHealth"), 4));
		new Float:m_iHealthBufferBits = GetConVarInt(FindConVar("adrenaline_health_buffer"))*0.5;
		new Float:m_iHealthBuffer = GetEntDataFloat(client, FindSendPropOffs("CTerrorPlayer","m_healthBuffer"));

		if(iUpgrade[client][7] > 0)
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
}

public UpgradeHeavyDutyBatteries(client, subject)
{
	if(iUpgrade[client][9] > 0)
	{
		new Float:m_iHealth = float(GetEntData(subject, FindDataMapOffs(subject, "m_iHealth"), 4));
		SetEntData(subject, FindDataMapOffs(subject, "m_iHealth"), RoundFloat(m_iHealth*1.5), 4, true);
	}
}

public UpgradeBarrelChamber(client)
{

	if(iUpgrade[client][8] > 0)
	{
		new iWEAPON = GetPlayerWeaponSlot(client, 0);
		SetEntProp(iWEAPON, Prop_Send, "m_nUpgradedPrimaryAmmoLoaded", RoundFloat(CheckWeaponUpgradeLimit(iWEAPON, client, true)*1.5), 4);
	}
}

public UpgradeBandages(client, subject)
{
	if(iUpgrade[subject][10] > 0)
	{
		new Float:m_iHealthBuffer = float(GetConVarInt(FindConVar("survivor_revive_health")))*1.5;
		SetEntPropFloat(subject, Prop_Send, "m_healthBuffer", m_iHealthBuffer);
	}
}

public UpgradeBetaBlockers(client)
{
	if(iUpgrade[client][11] > 0)
	{
		new m_iHealthBuffer = RoundFloat(GetConVarInt(FindConVar("survivor_incap_health"))*1.5);
		SetEntProp(client, Prop_Send, "m_iHealth", m_iHealthBuffer);
	}
}

public UpgradeMorphogenicCells(client)
{
	if(iUpgrade[client][12] > 0)
	{
		new m_iHealth = GetEntData(client, FindDataMapOffs(client, "m_iHealth"), 4);
		new m_iMaxHealth = GetEntData(client, FindDataMapOffs(client, "m_iMaxHealth"), 4);
		if(GetClientTeam(client) == 2 && GetEntProp(client, Prop_Send, "m_isIncapacitated") == 0 && m_iHealth <= RoundFloat(m_iMaxHealth * 0.5))
		{
			MorphogenicTimer[client] = CreateTimer(10.0, timer_MorphogenicTimer, client);
		}
	}
}

public Action:timer_RegenerationTimer(Handle:timer, any:client)
{
	if(IsClientInGame(client))
	{
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

public UpgradeBandoliers(client)
{
	if(iUpgrade[client][14] > 0)
	{
		new iWEAPON = GetPlayerWeaponSlot(client, 0);
		if(iWEAPON > 0)
		{
			decl String:WEAPON_NAME[64];
			GetEdictClassname(iWEAPON, WEAPON_NAME, 32);

			if(StrEqual(WEAPON_NAME, "weapon_rifle_m60"))
			{				
				if(iUpgrade[client][6] > 0)
				{
					SetEntProp(iWEAPON, Prop_Send, "m_iClip1", 225, 1);
				}
				else
				{
					SetEntProp(iWEAPON, Prop_Send, "m_iClip1", 150, 1);
				}
			}
			else if(StrEqual(WEAPON_NAME, "weapon_grenade_launcher"))
			{
				if(iUpgrade[client][6] > 0)
				{
					new m_iAmmo = FindDataMapOffs(client, "m_iAmmo");
					SetEntData(client, m_iAmmo+GRENADE_LAUNCHER_OFFSET_AMMO, RoundToNearest((GRENADE_LAUNCHER_AMMO * (1.5))) + (CheckWeaponUpgradeLimit(iWEAPON, client, true) - GetEntProp(iWEAPON, Prop_Send, "m_iClip1")));
				}
			}
		}
	}
}

public UpgradeAirBoots(client)
{
	if(iUpgrade[client][13] > 0 && GetClientTeam(client) == 2)
	{
		SetEntDataFloat(client, FindDataMapOffs(client, "m_flGravity"), 0.75);
	}
	else
	{
		SetEntDataFloat(client, FindDataMapOffs(client, "m_flGravity"), 1.0);
	}
}

public UpgradeHollowPointAmmunition(client, attacker, dmg_health, health, type)
{
	if(iUpgrade[attacker][15] > 0)
	{
		new m_iHealth = health - RoundFloat(dmg_health * 0.5);
		if(m_iHealth < 1)
			return;

		if(GetClientTeam(attacker) == 2 && type == 1)
		{
			SetEntityHealth(client, m_iHealth);
		}

		if(GetClientTeam(attacker) == 2 && type == 2)
		{
			SetEntProp(client, Prop_Data, "m_iHealth", m_iHealth);
		}
	}
}

public UpgradeKnife(client)
{
	if(iUpgrade[client][16] > 0)
	{
		decl String:ClientUserName[MAX_TARGET_LENGTH];
		GetClientName(client, ClientUserName, sizeof(ClientUserName));

		if(IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) == 2 && iKnifeReady == true && KnifeCooldownTimer[client] == INVALID_HANDLE)
		{
			if(GetEntPropEnt(client, Prop_Send, "m_pounceAttacker") > 0)
			{
				ForcePlayerSuicide(GetEntPropEnt(client, Prop_Send, "m_pounceAttacker"));
				EmitSoundToClient(client, "weapons/knife/knife_hitwall1.wav");
				PrintToChatAll("%s used a Knife!", ClientUserName);
				RemoveUpgrade(client, 16);
			}
			else if(GetEntPropEnt(client, Prop_Send, "m_jockeyAttacker") > 0)
			{
				ForcePlayerSuicide(GetEntPropEnt(client, Prop_Send, "m_jockeyAttacker"));
				EmitSoundToClient(client, "weapons/knife/knife_hitwall1.wav");
				PrintToChatAll("%s used a Knife!", ClientUserName);
				RemoveUpgrade(client, 16);
			}
			else if(GetEntPropEnt(client, Prop_Send, "m_pummelAttacker") > 0)
			{
				ForcePlayerSuicide(GetEntPropEnt(client, Prop_Send, "m_pummelAttacker"));
				EmitSoundToClient(client, "weapons/knife/knife_hitwall1.wav");
				PrintToChatAll("%s used a Knife!", ClientUserName);
				RemoveUpgrade(client, 16);
			}
			else if(GetEntPropEnt(client, Prop_Send, "m_tongueOwner") > 0)
			{
				ForcePlayerSuicide(GetEntPropEnt(client, Prop_Send, "m_tongueOwner"));
				EmitSoundToClient(client, "weapons/knife/knife_hitwall1.wav");
				PrintToChatAll("%s used a Knife!", ClientUserName);
				RemoveUpgrade(client, 16);
			}
			iKnifeReady = false;
		}
	}
}

public UpgradeQuickHeal(client)
{
	if(iUpgrade[client][17] > 0)
		SetConVarFloat(FindConVar("first_aid_kit_use_duration"), FirstAidDuration/2, false, false);
	else
		SetConVarFloat(FindConVar("first_aid_kit_use_duration"), FirstAidDuration, false, false);
}

public UpgradeSmellingSalts(client)
{
	if(iUpgrade[client][18] > 0)
		SetConVarFloat(FindConVar("survivor_revive_duration"), ReviveDuration/2, false, false);
	else
		SetConVarFloat(FindConVar("survivor_revive_duration"), ReviveDuration, false, false);
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

public UpgradePrimaryItem(client)
{
	CreateTimer(0.3, timer_UpgradePrimaryItems, client);
}

public UpgradeSecondaryItems(client)
{
	CreateTimer(0.3, timer_UpgradeSecondaryItems, client);
}

public UpgradeGrenadePouch(client)
{
	CreateTimer(1.5, timer_UpgradeGrenadeItems, client);
}

public UpgradeAutoinjectors(client)
{
	if(iUpgrade[client][0] > 0)
	{
		if(GetEntProp(client, Prop_Send, "m_currentReviveCount") == 1 && iAutoinjectors[client] == 0)
		{
			iAutoinjectors[client] = 1;
			SetEntProp(client, Prop_Send, "m_currentReviveCount", 0, 4);
			SetEntProp(client, Prop_Send, "m_isGoingToDie", 0);
		}
	}
}

public UpgradeOcularImplants(client, entityid)
{
	if(iUpgrade[client][28] > 0)
	{
		new String:iChosenItem[21][32] =
		{
			"weapon_pistol",
			"weapon_pistol_magnum",
			"weapon_rifle",
			"weapon_autoshotgun",
			"weapon_hunting_rifle",
			"weapon_rifle_ak47",
			"weapon_rifle_desert",
			"weapon_rifle_m60",
			"weapon_shotgun_chrome",
			"weapon_shotgun_spas",
			"weapon_sniper_awp",
			"weapon_sniper_military",
			"weapon_first_aid_kit",
			"weapon_defibrillator",
			"weapon_upgradepack_explosive",
			"weapon_upgradepack_incendiary",
			"weapon_pain_pills",
			"weapon_adrenaline",
			"weapon_molotov",
			"weapon_pipe_bomb",
			"weapon_vomitjar"
		};

		for(new iDrops = 1; iDrops < 4; iDrops++)
		{
			decl Float:fOrigin[3];
			GetEntPropVector(entityid, Prop_Data, "m_vecOrigin", fOrigin);
			new iDrop;

			fOrigin[2] += 40.0;
			new Float:vel[3];
			vel[0] = GetRandomFloat(-200.0, 200.0);
			vel[1] = GetRandomFloat(-200.0, 200.0);
			vel[2] = GetRandomFloat(40.0, 80.0);

			if(GetRandomInt(0, 100) < 5)
			{
				new item = GetRandomInt(0, 20);
				iDrop = CreateEntityByName(iChosenItem[item]);
				if(item > 1 && item < 13)
					SetEntProp(iDrop, Prop_Send, "m_iExtraPrimaryAmmo", GetRandomInt(50, 128));

				DispatchSpawn(iDrop);
				ActivateEntity(iDrop);
				TeleportEntity(iDrop, fOrigin, NULL_VECTOR, vel);
			}
		}
	}
}

UpgradeHighCapacityMag(client)
{
	if(iUpgrade[client][21] > 0)
	{
		new ActiveWeapon = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
		decl String:WEAPON_NAME[64];
		GetEdictClassname(ActiveWeapon, WEAPON_NAME, sizeof(WEAPON_NAME));
		
		if(StrContains(WEAPON_NAME, "shotgun", false) != -1)
		{
			CreateTimer(0.1, timer_SetNumShells, client);
		}
		SDKHook(client, SDKHook_PreThink, OnPreThink);
	}
}

public UpgradeKerosene(client)
{
	if(iUpgrade[client][1] > 0)
	{
		CreateTimer(0.4, CreateMolotovTimer);
	}
}

public UpgradeSafetyFuse(client)
{
	if(iUpgrade[client][24] > 0)
	{
		SetConVarFloat(FindConVar("pipe_bomb_timer_duration"), PipeBombDuration*1.5, false, false);
		SetConVarFloat(FindConVar("pipe_bomb_beep_interval_delta"), 0.025, false, false);
		SetConVarFloat(FindConVar("pipe_bomb_beep_min_interval"), 0.1, false, false);
		SetConVarFloat(FindConVar("pipe_bomb_initial_beep_interval"), 0.6, false, false);
	}
}

public UpgradeMedicalChart(client, subject, restored_health)
{
	if(iUpgrade[client][30] > 0 && client == subject)
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
				SetEntProp(i, Prop_Send, "m_currentReviveCount", 0, 4);
				SetEntProp(i, Prop_Send, "m_isGoingToDie", 0);
			}
		}
	}
}

public UpgradeLaserSight(client)
{
	CheatCommand(client, "upgrade_add", "laser_sight", "");
	new iWEAPON2 = GetPlayerWeaponSlot(client, 1);
	if(iWEAPON2 > 0)
	{
		decl String:WEAPON_NAME2[64];
		GetEdictClassname(iWEAPON2, WEAPON_NAME2, 32);
		if(!StrEqual(WEAPON_NAME2, "weapon_melee") && !StrEqual(WEAPON_NAME2, "weapon_chainsaw"))
		{
			new userbits = GetEntProp(iWEAPON2, Prop_Send, "m_upgradeBitVec");
			if(userbits & 1 << 2 != 1 << 2)
			{
				SetEntProp(iWEAPON2, Prop_Send, "m_upgradeBitVec", userbits |= (1 << 2), 4);
			}
		}
	}
}

public UpgradeCombatGloves(client)
{
	if(iUpgrade[client][31] > 0)
	{
		new iShovePenalty = GetEntProp(client, Prop_Send, "m_iShovePenalty");
		
		SetEntProp(client, Prop_Send, "m_iShovePenalty", RoundFloat(float(iShovePenalty)/2.0), 1);
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

public Action:timer_SafetyFuseStop(Handle:timer, any:client)
{
	SetConVarFloat(FindConVar("pipe_bomb_timer_duration"), PipeBombDuration, false, false);
	SetConVarFloat(FindConVar("pipe_bomb_beep_interval_delta"), 0.025, false, false);
	SetConVarFloat(FindConVar("pipe_bomb_beep_min_interval"), 0.1, false, false);
	SetConVarFloat(FindConVar("pipe_bomb_initial_beep_interval"), 0.5, false, false);
	return Plugin_Handled;
}

public Action:timer_KnifeCooldownTimer(Handle:timer, any:client)
{
	KnifeCooldownTimer[client] = INVALID_HANDLE;
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

public UpgradeKeroseneShot(client, entindex)
{
	if(iUpgrade[client][1] > 0)
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

public Action:timer_PyroPouchGasCan(Handle:timer, any:pack)
{
	decl Float:fOrigin[3];

	ResetPack(pack);
	fOrigin[0] = ReadPackFloat(pack);
	fOrigin[1] = ReadPackFloat(pack);
	fOrigin[2] = ReadPackFloat(pack);
	//new client = ReadPackCell(pack);

	new entity = CreateEntityByName("prop_physics");
	if(IsValidEntity(entity))
	{
		fOrigin[2] += 30.0;
		DispatchKeyValue(entity, "model", ENTITY_GASCAN);
		DispatchSpawn(entity);
		SetEntData(entity, GetEntSendPropOffs(entity, "m_CollisionGroup"), 1, 1, true);
		TeleportEntity(entity, fOrigin, NULL_VECTOR, NULL_VECTOR);
		ActivateEntity(entity);
		//AcceptEntityInput(entity, "break");
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
		//SetEntPropEnt(entity, Prop_Data, "m_hPhysicsAttacker", client);
		//SetEntPropEnt(entity, Prop_Data, "m_hLastAttacker", client);
		//SetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity", client);
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

public Action:timer_UpgradeGrenadeItems(Handle:timer, any:client)
{
    for(new slot = 0; slot < 2; slot++)
    {
		if(!StrEqual(iGrenadeItems[client][slot], ""))
		{				
				new item = GivePlayerItem(client, iGrenadeItems[client][slot]);
				EquipPlayerWeapon(client, item);
				iGrenadeItems[client][slot] = "";
				return;
		}
	}
}

public Action:timer_UpgradePrimaryItems(Handle:timer, any:client)
{
	new maxslots = 0;
	if(iUpgrade[client][19] > 0)
		maxslots++;
	if(iUpgrade[client][27] > 0)
		maxslots++;
	
	if(iUpgrade[client][19] > 0 || iUpgrade[client][27] > 0)
	{
		for(new slot = 0; slot < maxslots; slot++)
		{
			if(!StrEqual(iPrimaryItems[client][slot], ""))
			{				
					new item = GivePlayerItem(client, iPrimaryItems[client][slot]);
					EquipPlayerWeapon(client, item);
					iPrimaryItems[client][slot] = "";
					return;
			}
		}
	}
}

public Action:timer_UpgradeSecondaryItems(Handle:timer, any:client)
{
	new maxslots = 0;
	if(iUpgrade[client][20] > 0)
		maxslots++;
	if(iUpgrade[client][25] > 0)
		maxslots++;
	
	if(iUpgrade[client][20] > 0 || iUpgrade[client][25] > 0)
	{		
		for(new slot = 0; slot < maxslots; slot++)
		{
			if(!StrEqual(iSecondaryItems[client][slot], ""))
			{				
					new item = GivePlayerItem(client, iSecondaryItems[client][slot]);
					EquipPlayerWeapon(client, item);
					iSecondaryItems[client][slot] = "";
					return;
			}
		}
	}
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if(client == 0)
		return Plugin_Handled;
	
	if(buttons & IN_ATTACK2)
	{
		UpgradeKnife(client);
		UpgradeCombatGloves(client);
	}

	if(IsFakeClient(client) || GetClientTeam(client) != 2)
		return Plugin_Stop;

	if(iUpgrade[client][21] > 0 && (buttons & IN_RELOAD) && ReloadCooldown[client] == INVALID_HANDLE)
	{
		new ActiveWeapon = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
		decl String:WEAPON_NAME[64];
		GetEdictClassname(ActiveWeapon, WEAPON_NAME, sizeof(WEAPON_NAME));
	
		if(StrContains(WEAPON_NAME, "shotgun", false) != -1 && GetEntProp(ActiveWeapon, Prop_Send, "m_bInReload") == 0)
		{
			new m_iClip1 = GetEntProp(ActiveWeapon, Prop_Send, "m_iClip1");
			if(CheckWeaponUpgradeLimit(ActiveWeapon, client, true) > m_iClip1 >= CheckWeaponUpgradeLimit(ActiveWeapon, client, false))
			{
				SetEntProp(ActiveWeapon, Prop_Send, "m_iClip1", CheckWeaponUpgradeLimit(ActiveWeapon, client, false)-1, 4);				

				new Handle:pack;
				CreateDataTimer(0.1, timer_RestoreShotgun, pack);
				WritePackCell(pack, ActiveWeapon);
				WritePackCell(pack, m_iClip1);
				WritePackCell(pack, client);
			}
		}
		if(StrEqual(WEAPON_NAME, "weapon_pistol_magnum") || StrEqual(WEAPON_NAME, "weapon_pistol") || StrEqual(WEAPON_NAME, "weapon_grenade_launcher") || StrEqual(WEAPON_NAME, "weapon_sniper_military") || StrEqual(WEAPON_NAME, "weapon_hunting_rifle") || StrEqual(WEAPON_NAME, "weapon_rifle_ak47") || StrEqual(WEAPON_NAME, "weapon_rifle_desert") || StrEqual(WEAPON_NAME, "weapon_rifle") || StrEqual(WEAPON_NAME, "weapon_smg") || StrEqual(WEAPON_NAME, "weapon_smg_silenced") || StrEqual(WEAPON_NAME, "weapon_smg_mp5"))
		{
			new m_iClip1 = GetEntProp(ActiveWeapon, Prop_Send, "m_iClip1");
			if(CheckWeaponUpgradeLimit(ActiveWeapon, client, false) == m_iClip1)
			{
				new m_iAmmo = GetEntData(client, (FindDataMapOffs(client, "m_iAmmo") + CheckWeaponAmmoType(ActiveWeapon))); 
				SetEntProp(ActiveWeapon, Prop_Send, "m_iClip1", 0, 4);
				SetEntData(client, (FindDataMapOffs(client, "m_iAmmo") + CheckWeaponAmmoType(ActiveWeapon)), m_iAmmo + CheckWeaponUpgradeLimit(ActiveWeapon, client, false), 4, true);
			}
		}
	}
	ReloadCooldown[client] = CreateTimer(1.0, timer_ReloadCooldown, client);
	return Plugin_Continue;
}

public Action:timer_ReloadCooldown(Handle:timer, any:client)
{
	ReloadCooldown[client] = INVALID_HANDLE;
}

public Action:timer_RestoreShotgun(Handle:timer, any:pack)
{
	ResetPack(pack);
	new ActiveWeapon = ReadPackCell(pack);
	new m_iClip1 = ReadPackCell(pack);
	new client = ReadPackCell(pack);

	SetEntProp(ActiveWeapon, Prop_Send, "m_iClip1", m_iClip1, 4);
	SetEntProp(ActiveWeapon, Prop_Send, "m_reloadNumShells", (CheckWeaponUpgradeLimit(ActiveWeapon, client, true) - m_iClip1), 4);
}

public Action:timer_SetNumShells(Handle:timer, any:client)
{
	new ActiveWeapon = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
	decl String:WEAPON_NAME[64];
	GetEdictClassname(ActiveWeapon, WEAPON_NAME, sizeof(WEAPON_NAME));
	
	if(StrContains(WEAPON_NAME, "shotgun", false) != -1)
	{
		new m_iClip1 = GetEntProp(ActiveWeapon, Prop_Send, "m_iClip1");
		SetEntProp(ActiveWeapon, Prop_Send, "m_reloadNumShells", CheckWeaponUpgradeLimit(ActiveWeapon, client, true) - m_iClip1, 4);
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
        if(!IsClientConnected(i))
            continue;
        if(!IsClientInGame(i))
            continue;
        if(GetClientTeam(i)!=2)
            continue;
        if(!IsFakeClient(i))
            continue;
        if(!HasIdlePlayer(i))
            continue;
        
        new spectator_userid = GetEntData(i, FindSendPropInfo("SurvivorBot", "m_humanSpectatorUserID"));
        new spectator_client = GetClientOfUserId(spectator_userid);
        
        if(spectator_client == client)
            return true;
    }
    return false;
}

stock GetAnyValidClient()
{
    for (new target = 1; target <= MaxClients; target++)
    {
        if (IsClientInGame(target)) return target;
    }
    return -1;
}

stock GetClientUsedUpgrade(upgrade)
{
	for(new client = 1; client <= MaxClients; client++)
	{
		if(!IsClientConnected(client))
			continue;
		if(!IsClientInGame(client))
			continue;

		if(iUpgrade[client][upgrade] > 0 && (iBitsUpgrades[client] - iUpgrade[client][upgrade]) == GetEntProp(client, Prop_Send, "m_upgradeBitVec"))
		{
			RemoveUpgrade(client, upgrade);
			return client;
		}
	}
	return 0;
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