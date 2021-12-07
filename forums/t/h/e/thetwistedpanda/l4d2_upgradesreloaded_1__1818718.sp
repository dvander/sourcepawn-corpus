#pragma semicolon 1
/**
 * \x01 - Default
 * \x02 - Team Color
 * \x03 - Light Green
 * \x04 - Orange
 * \x05 - Olive
 * 
 */

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION		"1.5.1"
#define UPGRADEID		30
#define MAX_UPGRADES		18
#define AWARDID			128
#define CVAR_FLAGS		FCVAR_PLUGIN|FCVAR_NOTIFY
#define UPGRADE_LOAD_TIME	1.0

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
new Handle:penalty_upgrades;

new bool:b_round_end;

new UpgradeIndex[MAX_UPGRADES + 1] = 0;
new String:UpgradeTitle[MAX_UPGRADES + 1][256];
new String:UpgradeShort[MAX_UPGRADES + 1][256];
new String:AwardTitle[AWARDID + 1][256];
new iBitsUpgrades[MAXPLAYERS + 1] = 0;
new iUpgrade[MAXPLAYERS + 1][UPGRADEID + 1];
new iCount[MAXPLAYERS + 1][AWARDID + 1];
new bool:iAnnounceText[MAXPLAYERS + 1] = false;

new Float:FirstAidDuration;
new Float:ReviveDuration;

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

	AwardIndex[0] = CreateConVar("survivor_upgrade_awards_death", "0", "Lose All Upgrades (0 - Disable, 1 - Bots Only, 2 - Humans Only, 3 - All Players", CVAR_FLAGS, true, 0.0, true, 3.0);
	AwardTitle[0] = "\x05Death Penalty\x01";
	AwardIndex[14] = CreateConVar("survivor_upgrade_awards_blind_luck", "1", "Number of Blind Luck Awards To Earn Upgrade", CVAR_FLAGS, true, 0.0, true, 64.0);
	AwardTitle[14] = "\x05Blind Luck Award\x01";
	AwardIndex[15] = CreateConVar("survivor_upgrade_awards_pyrotechnician", "5", "Number of Pyrotechnician Awards To Earn Upgrade", CVAR_FLAGS, true, 0.0, true, 64.0);
	AwardTitle[15] = "\x05Pyrotechnician Award\x01";
	AwardIndex[18] = CreateConVar("survivor_upgrade_awards_witch_hunter", "1", "Number of Witch Hunter Awards To Earn Upgrade", CVAR_FLAGS, true, 0.0, true, 64.0);
	AwardTitle[18] = "\x05Witch Hunter Award\x01";
	AwardIndex[19] = CreateConVar("survivor_upgrade_awards_crowned", "1", "Number of Crowned Awards To Earn Upgrade", CVAR_FLAGS, true, 0.0, true, 64.0);
	AwardTitle[19] = "\x05Crowned Award\x01";
	AwardIndex[21] = CreateConVar("survivor_upgrade_awards_dead_stop", "1", "Number of Dead Stop Awards To Earn Upgrade", CVAR_FLAGS, true, 0.0, true, 64.0);
	AwardTitle[21] = "\x05Dead Stop Award\x01";
	AwardIndex[26] = CreateConVar("survivor_upgrade_awards_boom_cork", "1", "Number of Boom-Cork Awards To Earn Upgrade", CVAR_FLAGS, true, 0.0, true, 64.0);
	AwardTitle[26] = "\x05Boom-Cork Award\x01";
	AwardIndex[66] = CreateConVar("survivor_upgrade_awards_helping_hand", "5", "Number of Helping Hand Awards To Earn Upgrade", CVAR_FLAGS, true, 0.0, true, 64.0);
	AwardTitle[66] = "\x05Helping Hand Award\x01";
	AwardIndex[67] = CreateConVar("survivor_upgrade_awards_my_bodyguard", "10", "Number of My Bodyguard Awards To Earn Upgrade", CVAR_FLAGS, true, 0.0, true, 64.0);
	AwardTitle[67] = "\x05My Bodyguard Award\x01";
	AwardIndex[68] = CreateConVar("survivor_upgrade_awards_pharm_assist", "10", "Number of Pharm-Assist Awards To Earn Upgrade", CVAR_FLAGS, true, 0.0, true, 64.0);
	AwardTitle[68] = "\x05Pharm-Assist Award\x01";
	AwardIndex[69] = CreateConVar("survivor_upgrade_awards_adrenaline", "5", "Number of Adrenaline Awards To Earn Upgrade", CVAR_FLAGS, true, 0.0, true, 64.0);
	AwardTitle[69] = "\x05Adrenaline Award\x01";
	AwardIndex[70] = CreateConVar("survivor_upgrade_awards_medic", "5", "Number of Medic Awards To Earn Upgrade", CVAR_FLAGS, true, 0.0, true, 64.0);
	AwardTitle[70] = "\x05Medic Award\x01";
	AwardIndex[76] = CreateConVar("survivor_upgrade_awards_special_savior", "10", "Number of Special Savior Awards To Earn Upgrade", CVAR_FLAGS, true, 0.0, true, 64.0);
	AwardTitle[76] = "\x05Special Savior Award\x01";
	AwardIndex[81] = CreateConVar("survivor_upgrade_awards_tankbusters", "1", "Number of Tankbusters Award To Earn Upgrade", CVAR_FLAGS, true, 0.0, true, 64.0);
	AwardTitle[81] = "\x05Tankbusters Award\x01";
	AwardIndex[84] = CreateConVar("survivor_upgrade_awards_teamkill", "1", "Number of Team Kill Penalties To Lose Upgrade", CVAR_FLAGS, true, 0.0, true, 64.0);
	AwardTitle[84] = "\x05Team-Kill Penalty\x01";
	AwardIndex[85] = CreateConVar("survivor_upgrade_awards_teamincapacitate", "1", "Number of Team-Incapacitate Penalty To Lose Upgrade", CVAR_FLAGS, true, 0.0, true, 64.0);
	AwardTitle[85] = "\x05Team-Incapacitate Penalty\x01";
	AwardIndex[87] = CreateConVar("survivor_upgrade_awards_friendly_fire", "10", "Number of Friendly-Fire Penalty To Lose Upgrade", CVAR_FLAGS, true, 0.0, true, 64.0);
	AwardTitle[87] = "\x05Friendly-Fire Penalty\x01";

	RegConsoleCmd("sm_upgrades", PrintToChatUpgrades, "List Upgrades.");

	UpgradeIndex[0] = 1;
	UpgradeTitle[0] = "\x03Incendiary Ammo \x01(\x04Fire-Bullet Damage\x01)";
	UpgradeShort[0] = "\x03Incendiary Ammo\x01";
	UpgradeEnabled[0] = CreateConVar("survivor_upgrade_incendiary_ammo_enable", "1", "Enable/Disable Incendiary Ammo", CVAR_FLAGS, true, 0.0, true, 1.0);

	UpgradeIndex[1] = 2;
	UpgradeTitle[1] = "\x03Explosive Ammo \x01(\x04Explosive-Bullet Damage\x01)";
	UpgradeShort[1] = "\x03Explosive Ammo\x01";
	UpgradeEnabled[1] = CreateConVar("survivor_upgrade_explosive_ammo_enable", "1", "Enable/Disable Explosive Ammo", CVAR_FLAGS, true, 0.0, true, 1.0);

	UpgradeIndex[2] = 4;
	UpgradeTitle[2] = "\x03Laser Sight \x01(\x04Increased Accuracy\x01)";
	UpgradeShort[2] = "\x03Laser Sight\x01";
	UpgradeEnabled[2] = CreateConVar("survivor_upgrade_laser_sight_enable", "1", "Enable/Disable Laser Sight", CVAR_FLAGS, true, 0.0, true, 1.0);

	UpgradeIndex[3] = 8;
	UpgradeTitle[3] = "\x03Kevlar Body Armor \x01(\x04Reduced Damage\x01)";
	UpgradeShort[3] = "\x03Kevlar Body Armor\x01";
	UpgradeEnabled[3] = CreateConVar("survivor_upgrade_kevlar_armor_enable", "1", "Enable/Disable Kevlar Body Armor", CVAR_FLAGS, true, 0.0, true, 1.0);

	UpgradeIndex[4] = 16;
	UpgradeTitle[4] = "\x03Hot Meal \x01(\x04Increased Maximum Health\x01)";
	UpgradeShort[4] = "\x03Hot Meal\x01";
	UpgradeEnabled[4] = CreateConVar("survivor_upgrade_hot_meal_enable", "1", "Enable/Disable Hot Meal", CVAR_FLAGS, true, 0.0, true, 1.0);

	UpgradeIndex[5] = 32;
	UpgradeTitle[5] = "\x03Ointment \x01(\x04Increased Healing Effect\x01)";
	UpgradeShort[5] = "\x03Ointment\x01";
	UpgradeEnabled[5] = CreateConVar("survivor_upgrade_ointment_enable", "1", "Enable/Disable Ointment", CVAR_FLAGS, true, 0.0, true, 1.0);

	UpgradeIndex[6] = 64;
	UpgradeTitle[6] = "\x03Ammo Backpack \x01(\x04Increased Ammunition Reserve\x01)";
	UpgradeShort[6] = "\x03Ammo Backpack\x01";
	UpgradeEnabled[6] = CreateConVar("survivor_upgrade_backpack_enable", "1", "Enable/Disable Ammo Backpack", CVAR_FLAGS, true, 0.0, true, 1.0);

	UpgradeIndex[7] = 128;
	UpgradeTitle[7] = "\x03Steroids \x01(\x04Increased Buffer Effect\x01)";
	UpgradeShort[7] = "\x03Steroids\x01";
	UpgradeEnabled[7] = CreateConVar("survivor_upgrade_steroids_enable", "1", "Enable/Disable Steroids", CVAR_FLAGS, true, 0.0, true, 1.0);

	UpgradeIndex[8] = 256;
	UpgradeTitle[8] = "\x03Barrel Chamber \x01(\x04Increased Special Ammo\x01)";
	UpgradeShort[8] = "\x03Barrel Chamber\x01";
	UpgradeEnabled[8] = CreateConVar("survivor_upgrade_barrel_chamber_enable", "1", "Enable/Disable Barrel Chamber", CVAR_FLAGS, true, 0.0, true, 1.0);

	UpgradeIndex[9] = 512;
	UpgradeTitle[9] = "\x03Heavy Duty Batteries \x01(\x04Increased Defibrillator Effect\x01)";
	UpgradeShort[9] = "\x03Heavy Duty Batteries\x01";
	UpgradeEnabled[9] = CreateConVar("survivor_upgrade_heavy_duty_enable", "1", "Enable/Disable Heavy Duty Batteries", CVAR_FLAGS, true, 0.0, true, 1.0);

	UpgradeIndex[10] = 1024;
	UpgradeTitle[10] = "\x03Bandages \x01(\x04Increased Revive Buffer\x01)";
	UpgradeShort[10] = "\x03Bandages\x01";
	UpgradeEnabled[10] = CreateConVar("survivor_upgrade_bandages_enable", "1", "Enable/Disable Bandages", CVAR_FLAGS, true, 0.0, true, 1.0);

	UpgradeIndex[11] = 2048;
	UpgradeTitle[11] = "\x03Beta-Blockers \x01(\x04Increased Incapacitation Health\x01)";
	UpgradeShort[11] = "\x03Beta-Blockers\x01";
	UpgradeEnabled[11] = CreateConVar("survivor_upgrade_beta_blockers_enable", "1", "Enable/Disable Beta-Blockers", CVAR_FLAGS, true, 0.0, true, 1.0);

	UpgradeIndex[12] = 4092;
	UpgradeTitle[12] = "\x03Morphogenic Cells \x01(\x04Limited Health Regeneration\x01)";
	UpgradeShort[12] = "\x03Morphogenic Cells\x01";
	UpgradeEnabled[12] = CreateConVar("survivor_upgrade_morphogenic_cells_enable", "1", "Enable/Disable Morphogenic Cells", CVAR_FLAGS, true, 0.0, true, 1.0);

	UpgradeIndex[13] = 8192;
	UpgradeTitle[13] = "\x03Air Boots \x01(\x04Increased Jump Effect\x01)";
	UpgradeShort[13] = "\x03Air Boots\x01";
	UpgradeEnabled[13] = CreateConVar("survivor_upgrade_air_boots_enable", "1", "Enable/Disable Air Boots", CVAR_FLAGS, true, 0.0, true, 1.0);

	UpgradeIndex[14] = 16384;
	UpgradeTitle[14] = "\x03Bandoliers \x01(\x04Allow M60 Ammo Supply\x01)";
	UpgradeShort[14] = "\x03Bandoliers\x01";
	UpgradeEnabled[14] = CreateConVar("survivor_upgrade_bandoliers_enable", "1", "Enable/Disable Bandoliers", CVAR_FLAGS, true, 0.0, true, 1.0);

	UpgradeIndex[15] = 32768;
	UpgradeTitle[15] = "\x03Hollow Point Ammunition \x01(\x04Increased Bullet Damage\x01)";
	UpgradeShort[15] = "\x03Hollow Point Ammunition\x01";
	UpgradeEnabled[15] = CreateConVar("survivor_upgrade_hollow_point_enable", "1", "Enable/Disable Hollow Point Ammunition", CVAR_FLAGS, true, 0.0, true, 1.0);

	UpgradeIndex[16] = 65536;
	UpgradeTitle[16] = "\x03Knife \x01(\x04Self-Save Pinned\x01)";
	UpgradeShort[16] = "\x03Knife\x01";
	UpgradeEnabled[16] = CreateConVar("survivor_upgrade_knife_enable", "1", "Enable/Disable Knife", CVAR_FLAGS, true, 0.0, true, 1.0);

	UpgradeIndex[17] = 131072;
	UpgradeTitle[17] = "\x03Quick Heal \x01(\x04Healing Duration Reduced\x01)";
	UpgradeShort[17] = "\x03Quick Heal\x01";
	UpgradeEnabled[17] = CreateConVar("survivor_upgrade_quick_heal_enable", "1", "Enable/Disable Quick Heal", CVAR_FLAGS, true, 0.0, true, 1.0);

	UpgradeIndex[18] = 262144;
	UpgradeTitle[18] = "\x03Smelling Salts \x01(\x04Revive Duration Reduced\x01)";
	UpgradeShort[18] = "\x03Smelling Salts\x01";
	UpgradeEnabled[18] = CreateConVar("survivor_upgrade_smelling_salts_enable", "1", "Enable/Disable Smelling Salts", CVAR_FLAGS, true, 0.0, true, 1.0);

	HookEvent("adrenaline_used", event_AdrenalineUsed, EventHookMode_Post);
	HookEvent("pills_used", event_PillsUsed, EventHookMode_Post);
	HookEvent("defibrillator_used", event_DefibrillatorUsed, EventHookMode_Post);
	HookEvent("player_spawn", event_PlayerSpawn, EventHookMode);
	HookEvent("item_pickup", event_ItemPickup);
	HookEvent("player_use", event_PlayerUse);
	HookEvent("ammo_pickup", event_AmmoPickup, EventHookMode_Post);
	HookEvent("player_death", event_PlayerDeath);
	HookEvent("survivor_rescued", event_Rescued);
	HookEvent("award_earned", event_AwardEarned);
	HookEvent("round_start", round_start);
	HookEvent("round_end", round_end, EventHookMode_Pre);
	HookEvent("heal_success", event_HealSuccess);
	HookEvent("map_transition", round_end, EventHookMode_Pre);
	HookEvent("player_bot_replace", event_BotReplacedPlayer, EventHookMode_Post);
	HookEvent("bot_player_replace", event_PlayerReplacedBot, EventHookMode_Post);
	HookEvent("receive_upgrade", event_ReceiveUpgrade);
	HookEvent("revive_success", event_ReviveSuccess);
	HookEvent("player_incapacitated", event_PlayerIncapacitated);
	HookEvent("heal_begin", event_HealBegin, EventHookMode_Pre);
	HookEvent("revive_begin", event_ReviveBegin, EventHookMode_Pre);

	HookEvent("player_hurt", event_PlayerHurt, EventHookMode_Post);
	HookEvent("infected_hurt", event_InfectedHurt, EventHookMode_Post);

	HookEvent("player_jump", event_PlayerJump);

	SetConVarInt(FindConVar("pain_pills_health_threshold"), 150, false, false);
	FirstAidDuration = GetConVarFloat(FindConVar("first_aid_kit_use_duration"));
	ReviveDuration = GetConVarFloat(FindConVar("survivor_revive_duration"));

	AutoExecConfig(true, "l4d2_upgradesreloaded");
}

public event_PlayerSpawn(Handle:event, const String:name[], bool:Broadcast) 
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(client > 0)
	{
		CreateTimer(5.0, event_TimerPlayerSpawn, client);
	}
}

public event_PlayerDeath(Handle:event, const String:name[], bool:Broadcast) 
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	// 0 - Disabled
	if(GetConVarInt(AwardIndex[0]) == 0)
	{
		return;
	}
	// 1 - Bots Only
	if(client > 0 && GetConVarInt(AwardIndex[0]) == 1 && IsFakeClient(client) && GetClientTeam(client) == 2)
	{
		RemoveSurvivorUpgrade(client, GetConVarInt(penalty_upgrades), 0);
	}
	// 2 - Humans Only
	if(client > 0 && GetConVarInt(AwardIndex[0]) == 2 && !IsFakeClient(client) && GetClientTeam(client) == 2)
	{
		RemoveSurvivorUpgrade(client, GetConVarInt(penalty_upgrades), 0);
	}
	// 3 - All Players
	if(client > 0 && GetConVarInt(AwardIndex[0]) == 3 && GetClientTeam(client) == 2)
	{
		RemoveSurvivorUpgrade(client, GetConVarInt(penalty_upgrades), 0);
	}
	return;
}

public Action:event_TimerPlayerSpawn(Handle:timer, any:client)
{
	if(b_round_end == true)
	{
		return;
	}
	if(!IsClientInGame(client) || !IsClientConnected(client) || !IsPlayerAlive(client) || HasIdlePlayer(client))
	{
		return;
	}
	if(IsFakeClient(client) && GetClientTeam(client) == 2)
	{
		if(!HasIdlePlayer(client) && GetClientOfUserId(GetEntData(client, FindSendPropInfo("SurvivorBot", "m_humanSpectatorUserID"))) == 0 && GetClientTeam(client) == 2)
		{
			CreateTimer(UPGRADE_LOAD_TIME, SetSurvivorUpgrades, client);
		}
	}
	if(!IsFakeClient(client))
	{
		if(IsClientInGame(client))
		{
			if(GetClientTeam(client) == 2)
			{
				CreateTimer(UPGRADE_LOAD_TIME, SetSurvivorUpgrades, client);
			}
		}
	}
}

public event_Rescued(Handle:event, const String:name[], bool:dontBroadcast) 
{
	new client = GetClientOfUserId(GetEventInt(event,"victim"));
	if(client > 0 && IsClientInGame(client) && !IsClientObserver(client) && GetClientTeam(client) == 2)
	{
		CreateTimer(UPGRADE_LOAD_TIME, SetSurvivorUpgrades, client);
	}
}

public event_BotReplacedPlayer(Handle:event, const String:name[], bool:dontBroadcast) 
{
	new bot = GetClientOfUserId(GetEventInt(event,"bot"));

	if(bot > 0 && IsClientInGame(bot) && !IsClientObserver(bot) && GetClientTeam(bot) == 2)
	{
		CreateTimer(UPGRADE_LOAD_TIME, SetSurvivorUpgrades, bot);
	}
}

public event_PlayerReplacedBot(Handle:event, const String:name[], bool:dontBroadcast) 
{
	new client = GetClientOfUserId(GetEventInt(event,"player"));

	if(client > 0 && IsClientInGame(client) && !IsClientObserver(client) && GetClientTeam(client) == 2)
	{
		CreateTimer(UPGRADE_LOAD_TIME, SetSurvivorUpgrades, client);
	}
}

public Action:SetSurvivorUpgrades(Handle:timer, any:client)
{
	if(client > 0 && IsClientInGame(client))
	{
		if(iUpgrade[client][3] > 0)
		{
			SetEntProp(client, Prop_Send, "m_ArmorValue", 9999);
			SetEntProp(client, Prop_Send, "m_bHasHelmet", 1);
		}
		else
		{
			SetEntProp(client, Prop_Send, "m_ArmorValue", 0);
		}
		if(iUpgrade[client][4] > 0)
		{
			SetEntProp(client, Prop_Send, "m_iMaxHealth", 150);
		}
		else
		{
			SetEntProp(client, Prop_Send, "m_iMaxHealth", 100);
		}
	
		if(iUpgrade[client][2] > 0)
		{
			CheatCommand(client, "upgrade_add", "laser_sight", "");
			new iWEAPON2 = GetPlayerWeaponSlot(client, 1);
			if(iWEAPON2 > 0)
			{
				decl String:WEAPON_NAME2[64];
				GetEdictClassname(iWEAPON2, WEAPON_NAME2, 32);
				if(!StrEqual(WEAPON_NAME2, "weapon_melee") && !StrEqual(WEAPON_NAME2, "weapon_chainsaw") && GetEntProp(iWEAPON2, Prop_Send, "m_upgradeBitVec") == 0)
				{
					SetEntProp(iWEAPON2, Prop_Send, "m_upgradeBitVec", 4, 4);
				}
			}
		}
	}
	if(IsClientInGame(client) && iBitsUpgrades[client] > 0)
	{
		EmitSoundToClient(client, "player/orch_hit_Csharp_short.wav");
	}
}

public event_ItemPickup(Handle:event, const String:name[], bool:Broadcast) 
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new String:iWeaponName[32];
	GetEventString(event, "item", iWeaponName, 32);

	if(client > 0)
	{

		if(iUpgrade[client][2] > 0)
		{
			CheatCommand(client, "upgrade_add", "laser_sight", "");
			new iWEAPON2 = GetPlayerWeaponSlot(client, 1);
			if(iWEAPON2 > 0)
			{
				decl String:WEAPON_NAME2[64];
				GetEdictClassname(iWEAPON2, WEAPON_NAME2, 32);
				if(!StrEqual(WEAPON_NAME2, "weapon_melee") && !StrEqual(WEAPON_NAME2, "weapon_chainsaw") && GetEntProp(iWEAPON2, Prop_Send, "m_upgradeBitVec") == 0)
				{
					SetEntProp(iWEAPON2, Prop_Send, "m_upgradeBitVec", 4, 4);
				}
			}
		}
		if(iUpgrade[client][6] > 0)
		{
			if(StrContains(iWeaponName, "smg", false) != -1 || StrContains(iWeaponName, "rifle", false) != -1 || StrContains(iWeaponName, "shotgun", false) != -1 || StrContains(iWeaponName, "sniper", false) != -1)
			{
				GivePlayerAmmo(client);
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
			if(iUpgrade[client][6] > 0)
			{
				ClearPlayerAmmo(client);
				CheatCommand(client, "give", "ammo", "");
				GivePlayerAmmo(client);
			}
			if(iUpgrade[client][14] > 0)
			{
				UpgradeBandoliers(client);
			}
		}
	}
}

public event_AmmoPickup(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event,"userid"));
	if (client == 0)
		return;

	if(client > 0 && iUpgrade[client][6] > 0)
	{
		GivePlayerAmmo(client);
	}
}

GivePlayerAmmo(client)
{
	new iWEAPON = GetPlayerWeaponSlot(client, 0);
	if(iWEAPON > 0)
	{
		GetEntProp(iWEAPON, Prop_Send, "m_iClip1");
	
		new m_iAmmo = FindDataMapOffs(client, "m_iAmmo");
		SetEntData(client, m_iAmmo+RIFLE_OFFSET_AMMO, RoundToNearest((RIFLE_AMMO * (1.5))) + (CheckWeaponUpgradeLimit(iWEAPON) - GetEntProp(iWEAPON, Prop_Send, "m_iClip1")));
		SetEntData(client, m_iAmmo+SMG_OFFSET_AMMO, RoundToNearest((SMG_AMMO * (1.5))) + (CheckWeaponUpgradeLimit(iWEAPON) - GetEntProp(iWEAPON, Prop_Send, "m_iClip1")));
		SetEntData(client, m_iAmmo+SHOTGUN_OFFSET_AMMO, RoundToNearest((SHOTGUN_AMMO * (1.5))) + (CheckWeaponUpgradeLimit(iWEAPON) - GetEntProp(iWEAPON, Prop_Send, "m_iClip1")));
		SetEntData(client, m_iAmmo+AUTOSHOTGUN_OFFSET_AMMO, RoundToNearest((AUTOSHOTGUN_AMMO * (1.5))) + (CheckWeaponUpgradeLimit(iWEAPON) - GetEntProp(iWEAPON, Prop_Send, "m_iClip1")));
		SetEntData(client, m_iAmmo+HUNTING_RIFLE_OFFSET_AMMO, RoundToNearest((HUNTING_RIFLE_AMMO * (1.5))) + (CheckWeaponUpgradeLimit(iWEAPON) - GetEntProp(iWEAPON, Prop_Send, "m_iClip1")));
		SetEntData(client, m_iAmmo+SNIPER_OFFSET_AMMO, RoundToNearest((SNIPER_AMMO * (1.5))) + (CheckWeaponUpgradeLimit(iWEAPON) - GetEntProp(iWEAPON, Prop_Send, "m_iClip1")));
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

public OnClientPostAdminCheck(client)
{
	ClientSaveToFileLoad(client);
	ClientCommand(client, "bind f3 sm_upgrades");
}

public OnClientDisconnect(client)
{
	ClientSaveToFileSave(client);
}

public GiveSurvivorUpgrade(client, amount, awardid)
{
	for(new num = 0; num < amount; num++)
	{
		decl String:ClientUserName[MAX_NAME_LENGTH];
		GetClientName(client, ClientUserName, sizeof(ClientUserName));

		new numOwned = GetSurvivorUpgrades(client);
		if(numOwned == GetAvailableUpgrades())
		{
			for (new i = 1; i <= MaxClients; i++)
			{
				if(IsClientInGame(i) && iAnnounceText[i] == true)
					PrintToChat(i, "\x3%s \x01has earned the %s.", ClientUserName, AwardTitle[awardid]);
			}
			return;
		}
		new offset = GetRandomInt(0,GetAvailableUpgrades()-(numOwned+1));
		new val = 0;
		while(offset > 0 || iUpgrade[client][val] || GetConVarInt(UpgradeEnabled[val]) != 1)
		{
			if((!iUpgrade[client][val]) && GetConVarInt(UpgradeEnabled[val]) == 1)
			{
				offset--;
			}
			val++;
		}
		if(IsPlayerAlive(client))
		{
			GiveUpgrade(client, val);
			for (new i = 1; i <= MaxClients; i++)
			{
				if(IsClientInGame(i) && iAnnounceText[i] == true)
					PrintToChat(i, "\x3%s \x01earned %s from %s.", ClientUserName, UpgradeShort[val], AwardTitle[awardid]);
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
		if(numMiss == MAX_UPGRADES+1)
		{
			for(new i = 1; i <= MaxClients; i++)
			{
				if(IsClientInGame(i) && iAnnounceText[i] == true)
					PrintToChat(i, "\x3%s \x01lost all upgrades.", ClientUserName);
			}
			return;
		}
		new offset = GetRandomInt(0,GetAvailableUpgrades()-(numMiss+1));
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
			if(IsClientInGame(i) && iAnnounceText[i] == true)
				PrintToChat(i, "\x03%s \x01lost %s from %s.", ClientUserName, UpgradeShort[val], AwardTitle[awardid]);
		}
	}
}

public GiveUpgrade(client, upgrade)
{
	for(new i = 0; i < MAX_UPGRADES + 1; i++)
	{
		if(client > 0 && i == upgrade)
		{
			iUpgrade[client][upgrade] = UpgradeIndex[upgrade];
			iBitsUpgrades[client] += iUpgrade[client][upgrade];
			CreateTimer(UPGRADE_LOAD_TIME, SetSurvivorUpgrades, client);
			if(UpgradeIndex[upgrade] == 1 || UpgradeIndex[upgrade] == 2)
			{
				new iWEAPON = GetPlayerWeaponSlot(client, 0);
				if(iWEAPON > 0)
				{
					new iUPGRADE_AMMO = GetEntProp(iWEAPON, Prop_Send, "m_nUpgradedPrimaryAmmoLoaded");
					iUPGRADE_AMMO += CheckWeaponUpgradeLimit(iWEAPON);

					if(UpgradeIndex[upgrade] == 1)
					{
						CheatCommand(client, "upgrade_add", "incendiary_ammo", "");
					}
					if(UpgradeIndex[upgrade] == 2)
					{
						CheatCommand(client, "upgrade_add", "explosive_ammo", "");
					}
					if(iUPGRADE_AMMO > 100)
					{
						SetEntProp(iWEAPON, Prop_Send, "m_nUpgradedPrimaryAmmoLoaded", 100, 4);
					}
					else
					{
						SetEntProp(iWEAPON, Prop_Send, "m_nUpgradedPrimaryAmmoLoaded", iUPGRADE_AMMO, 4);
					}
				}
				iUpgrade[client][upgrade] = 0;
			}
		}
	}
}

public RemoveUpgrade(client, upgrade)
{
	for(new i = 0; i < MAX_UPGRADES + 1; i++)
	{
		if(client > 0 && i == upgrade)
		{
			iUpgrade[client][upgrade] = 0;
			iBitsUpgrades[client] -= UpgradeIndex[upgrade];
			CreateTimer(UPGRADE_LOAD_TIME, SetSurvivorUpgrades, client);
		}
	}
}

CheckWeaponUpgradeLimit(weapon)
{
	new UpgradeLimit = 0;
	decl String:WEAPON_NAME[64];
	GetEdictClassname(weapon, WEAPON_NAME, 32);

	if(StrEqual(WEAPON_NAME, "weapon_rifle") || StrEqual(WEAPON_NAME, "weapon_smg") || StrEqual(WEAPON_NAME, "weapon_smg_silenced") || StrEqual(WEAPON_NAME, "weapon_smg_mp5"))
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
	else if(StrEqual(WEAPON_NAME, "weapon_hunting_rifle"))
	{
		UpgradeLimit = 15;	 
	}
	else if(StrEqual(WEAPON_NAME, "weapon_sniper_military"))
	{
		UpgradeLimit = 30;	 
	}
	else if(StrEqual(WEAPON_NAME, "weapon_grenade_launcher"))
	{
		UpgradeLimit = 1;
	}
	return UpgradeLimit;
}

public GetAvailableUpgrades()
{
	new upgrades = 0;
	for(new i = 0; i < MAX_UPGRADES + 1; i++)
	{
		if(GetConVarInt(UpgradeEnabled[i]) > 0)
		{
			upgrades++;
		}
	}
	return upgrades;
}

public GetSurvivorUpgrades(client)
{
	new upgrades = 0;
	for(new i = 0; i < MAX_UPGRADES + 1; i++)
	{
		if(iUpgrade[client][i] > 0)
		{
			upgrades++;
		}
	}
	return upgrades;
}

public ResetClientUpgrades(client)
{
	for(new i = 0; i < MAX_UPGRADES + 1; i++)
	{
		iUpgrade[client][i] = 0;
	}
	iBitsUpgrades[client] = 0;
}

public MissingSurvivorUpgrades(client)
{
	new upgrades = 0;
	for(new i = 0; i < MAX_UPGRADES + 1; i++)
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
}

public DisplayUpgradeMenu(client)
{
	if(GetClientTeam(client) == 2)
	{
		new Handle:UpgradePanel = CreatePanel();

		decl String:buffer[255];
		Format(buffer, sizeof(buffer), "Survivor Upgrades (%d/%d)", GetSurvivorUpgrades(client), (GetAvailableUpgrades()-2));
		SetPanelTitle(UpgradePanel, buffer);
		
		for(new i = 1; i <= MaxClients; i++)
		{
			if(!IsClientConnected(i))
				continue;
			if(!IsClientInGame(i))
				continue;
			if(GetClientTeam(i) == 2)
			{
				new String:text[64];
				new percentage = RoundFloat((float(GetSurvivorUpgrades(i)) / (GetAvailableUpgrades()-2)) * 100);

				decl String:ClientUserName[MAX_TARGET_LENGTH];
				GetClientName(i, ClientUserName, sizeof(ClientUserName));

				Format(text, sizeof(text), "%s (%d%%)", ClientUserName, percentage);
				DrawPanelText(UpgradePanel, text);
			}
		}
		
		DrawPanelItem(UpgradePanel, "Display Upgrades");
		DrawPanelItem(UpgradePanel, "Toggle Notifications");
		DrawPanelItem(UpgradePanel, "Reset Upgrades");
		
		SendPanelToClient(UpgradePanel, client, DisplayUpgradeMenuHandler, 30);
		CloseHandle(UpgradePanel);
	}
	else
	{
		PrintToChat(client, "\x01[\x03ERROR\x01] An Error occurred, please contact developer.");
	}
}

public DisplayUpgradeMenuHandler(Handle:UpgradePanel, MenuAction:action, param1, param2)
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
			if(iAnnounceText[client] != true)
			{
				iAnnounceText[client] = true;
				PrintToChat(client, "\x01Announcement Text \x04On\x01.");
			}
			else
			{
				iAnnounceText[client] = false;
				PrintToChat(client, "\x01Announcement Text \x04Off\x01.");
			}
		}
		else if(param2 == 3)
		{
			ResetClientUpgrades(client);
			PrintToChat(client, "\x01Upgrades \x04Reset\x01.");
		}
	}
	else if(action == MenuAction_Cancel)
	{
		// Nothing
	}
}

public event_AwardEarned(Handle:event, const String:name[], bool:Broadcast) 
{
	if(b_round_end == true)
	{
		return;
	}

	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new achievementid = GetEventInt(event, "award");
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
}

public Action:round_start(Handle:event, const String:name[], bool:dontBroadcast)
{
	b_round_end = false;
}

public Action:round_end(Handle:event, const String:name[], bool:dontBroadcast)
{
	b_round_end = true;
}

public event_HealSuccess(Handle:event, const String:name[], bool:Broadcast) 
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new subject = GetClientOfUserId(GetEventInt(event, "subject"));
	new m_iHealth = GetEventInt(event, "health_restored");	

	new m_iMaxHealth = GetEntData(subject, FindDataMapOffs(subject, "m_iMaxHealth"), 4);
	if(iUpgrade[client][5] > 0)
	{
		SetEntData(subject, FindDataMapOffs(subject, "m_iHealth"), 100, 4, true);
	}
	if(iUpgrade[subject][4] > 0 && m_iMaxHealth > 100)
	{
		SetEntData(subject, FindDataMapOffs(subject, "m_iHealth"), RoundFloat(m_iMaxHealth * GetConVarFloat(FindConVar("first_aid_heal_percent"))), 4, true);
		if(iUpgrade[client][5] > 0)
		{
			SetEntData(subject, FindDataMapOffs(subject, "m_iHealth"), m_iMaxHealth, 4, true);
		}
	}
}

/* Save To File */
ClientSaveToFileSave(targetid)
{
	decl Handle:kv;
	decl String:cName[MAX_NAME_LENGTH];
	kv = CreateKeyValues("SurvivorUpgradesReloaded");
	FileToKeyValues(kv, SavePath);

	GetClientAuthString(targetid, cName, sizeof(cName));

	KvJumpToKey(kv, cName, true);

	for(new i = 0; i < MAX_UPGRADES + 1; i++)
	{
		decl String:buffer[512];
		Format(buffer, sizeof(buffer), "Upgrade #%i", i);
		KvSetNum(kv, buffer, iUpgrade[targetid][i]);
	}

	KvRewind(kv);
	KeyValuesToFile(kv, SavePath);
	CloseHandle(kv);
}

/* Load Save From File */
ClientSaveToFileLoad(targetid)
{
	decl Handle:kv;
	decl String:cName[MAX_NAME_LENGTH];
	kv = CreateKeyValues("SurvivorUpgradesReloaded");
	FileToKeyValues(kv, SavePath);

	GetClientAuthString(targetid, cName, sizeof(cName));

	KvJumpToKey(kv, cName, true);

	iBitsUpgrades[targetid] = 0;

	for(new i = 0; i < MAX_UPGRADES + 1; i++)
	{
		decl String:buffer[512];
		Format(buffer, sizeof(buffer), "Upgrade #%i", i);
		iUpgrade[targetid][i] = KvGetNum(kv, buffer, 0);
		iBitsUpgrades[targetid] += iUpgrade[targetid][i];
	}
	CloseHandle(kv);
}


public event_PillsUsed(Handle:event, const String:name[], bool:Broadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	UpgradeChemist(client, 1);
}

public event_AdrenalineUsed(Handle:event, const String:name[], bool:Broadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	UpgradeChemist(client, 2);
}

public event_DefibrillatorUsed(Handle:event, const String:name[], bool:Broadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new subject = GetClientOfUserId(GetEventInt(event, "subject"));
	UpgradeHeavyDutyBatteries(client, subject);
}

public event_ReceiveUpgrade(Handle:event, const String:name[], bool:Broadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	UpgradeBarrelChamber(client);
}

public event_ReviveSuccess(Handle:event, const String:name[], bool:Broadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new subject = GetClientOfUserId(GetEventInt(event, "subject"));
	UpgradeSteroids(client, subject);
	UpgradeMorphogenicCells(subject);
}

public event_PlayerIncapacitated(Handle:event, const String:name[], bool:Broadcast)
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
}

public event_PlayerHurt(Handle:event, const String:name[], bool:Broadcast)
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
}

public event_InfectedHurt(Handle:event, const String:name[], bool:Broadcast)
{
	new entityid = (GetEventInt(event, "entityid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new amount = GetEventInt(event, "amount");
	new health = GetEntProp(entityid, Prop_Data, "m_iHealth");	

	UpgradeHollowPointAmmunition(entityid, attacker, amount, health, 2);
}

public Action:timer_MorphogenicTimer(Handle:timer, any:client)
{
	MorphogenicTimer[client] = INVALID_HANDLE;
	RegenerationTimer[client] = CreateTimer(0.1, timer_RegenerationTimer, client, TIMER_REPEAT);
}

public event_PlayerJump(Handle:event, const String:name[], bool:Broadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(GetClientTeam(client) == 2)
	{
		UpgradeAirBoots(client);
	}
}

public event_HealBegin(Handle:event, const String:name[], bool:Broadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	UpgradeQuickHeal(client);
}

public event_ReviveBegin(Handle:event, const String:name[], bool:Broadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	UpgradeSmellingSalts(client);
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if(client == 0)
		return Plugin_Continue;
	
	if(buttons & IN_ATTACK2)
	{
		UpgradeKnife(client);
	}	
	return Plugin_Continue;
}

public UpgradeChemist(client, type)
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
		new Float:iPrimaryAmmoLoaded = float(GetEntProp(iWEAPON, Prop_Send, "m_nUpgradedPrimaryAmmoLoaded"));
		SetEntProp(iWEAPON, Prop_Send, "m_nUpgradedPrimaryAmmoLoaded", RoundFloat(iPrimaryAmmoLoaded*1.5), 4);
	}
}

public UpgradeSteroids(client, subject)
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
					SetEntData(client, m_iAmmo+GRENADE_LAUNCHER_OFFSET_AMMO, RoundToNearest((GRENADE_LAUNCHER_AMMO * (1.5))) + (CheckWeaponUpgradeLimit(iWEAPON) - GetEntProp(iWEAPON, Prop_Send, "m_iClip1")));
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

		if(IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) == 2)
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
		}
	}
}

public UpgradeQuickHeal(client)
{
	if(iUpgrade[client][17] > 0)
	{
		SetConVarFloat(FindConVar("first_aid_kit_use_duration"), FirstAidDuration/2, false, false);
	}
	else
	{
		SetConVarFloat(FindConVar("first_aid_kit_use_duration"), FirstAidDuration, false, false);
	}
}

public UpgradeSmellingSalts(client)
{
	if(iUpgrade[client][18] > 0)
	{
		SetConVarFloat(FindConVar("survivor_revive_duration"), ReviveDuration/2, false, false);
	}
	else
	{
		SetConVarFloat(FindConVar("survivor_revive_duration"), ReviveDuration, false, false);
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