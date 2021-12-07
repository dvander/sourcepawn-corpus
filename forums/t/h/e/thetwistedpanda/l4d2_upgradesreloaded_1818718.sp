#include <sourcemod>
#include <sdktools>

#define TOTAL_UPGRADES 18

#define TOTAL_AWARDS 128

new g_iArmorUpgradeAmt = 9999, g_iHealthUpgradeAmt = 150;
new g_iArmorDefaultAmt = 0, g_iHealthDefaultAmt = 100;

public Plugin:myinfo =
{
	name = "[L4D2] Survivor Upgrades Reloaded",
	description = "Survivor Upgrades Returns, Reloaded!",
	author = "Marcus101RR, Whosat & Jerrith",
	version = "1.5.0",
	url = "http://forums.alliedmods.net"
};

new g_iUpgradeIndex[TOTAL_UPGRADES + 1];
new String:g_sAwardTitle[TOTAL_AWARDS + 1][64];
new String:g_sUpgradeTitle[TOTAL_UPGRADES + 1][64];
new String:g_sUpgradeShort[TOTAL_UPGRADES + 1][64];
new Handle:g_hPenaltyUpgrades;
new Handle:g_hUpgradeIndex[TOTAL_UPGRADES + 1] = { INVALID_HANDLE, ... };
new Handle:g_hAwardIndex[TOTAL_AWARDS + 1] = { INVALID_HANDLE, ... };

new g_iBitsUpgrade[MAXPLAYERS + 1];
new g_iUpgrade[MAXPLAYERS + 1][31];
new g_iCount[MAXPLAYERS + 1][TOTAL_AWARDS + 1];
new bool:g_bAnnounceText[MAXPLAYERS + 1];
new Handle:g_hTimer_Morphogenic[MAXPLAYERS + 1] = { INVALID_HANDLE, ... };
new Handle:g_hTimer_Regeneration[MAXPLAYERS + 1] = { INVALID_HANDLE, ... };

new bool:g_bRoundEnd;
new Float:g_fFirstAidDuration, Float:g_fReviveDuration;
new String:g_sSavePath[PLATFORM_MAX_PATH];

public OnPluginStart()
{
	decl String:sTemp[64];
	GetGameFolderName(sTemp, 64);
	if(!StrEqual(sTemp, "left4dead2", false))
		SetFailState("Plugin Supports Left 4 Dead 2 Only.");

	BuildPath(Path_SM, g_sSavePath, PLATFORM_MAX_PATH, "data/l4d2_upgradesreloaded.txt");
	CreateConVar("sm_upgradesreloaded_version", "1.5.0", "Survivor Upgrades Reloaded Version", FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_REPLICATED|FCVAR_PLUGIN, false, 0.0, false, 0.0);
	g_hPenaltyUpgrades = CreateConVar("survivor_upgrade_awards_death_amount", "2", "Number of Upgrades Lost per Death", FCVAR_NOTIFY|FCVAR_PLUGIN, true, 1.0, true, 8.0);
	g_hAwardIndex[0] = CreateConVar("survivor_upgrade_awards_death", "0", "Lose All Upgrades (0 - Disable, 1 - Bots Only, 2 - Humans Only, 3 - All Players", FCVAR_NOTIFY|FCVAR_PLUGIN, true, 0.0, true, 3.0);
	g_hAwardIndex[14] = CreateConVar("survivor_upgrade_awards_blind_luck", "1", "Number of Blind Luck Awards To Earn Upgrade", FCVAR_NOTIFY|FCVAR_PLUGIN, true, 0.0, true, 64.0);
	g_hAwardIndex[15] = CreateConVar("survivor_upgrade_awards_pyrotechnician", "5", "Number of Pyrotechnician Awards To Earn Upgrade", FCVAR_NOTIFY|FCVAR_PLUGIN, true, 0.0, true, 64.0);
	g_hAwardIndex[18] = CreateConVar("survivor_upgrade_awards_witch_hunter", "1", "Number of Witch Hunter Awards To Earn Upgrade", FCVAR_NOTIFY|FCVAR_PLUGIN, true, 0.0, true, 64.0);
	g_hAwardIndex[19] = CreateConVar("survivor_upgrade_awards_crowned", "1", "Number of Crowned Awards To Earn Upgrade", FCVAR_NOTIFY|FCVAR_PLUGIN, true, 0.0, true, 64.0);
	g_hAwardIndex[21] = CreateConVar("survivor_upgrade_awards_dead_stop", "1", "Number of Dead Stop Awards To Earn Upgrade", FCVAR_NOTIFY|FCVAR_PLUGIN, true, 0.0, true, 64.0);
	g_hAwardIndex[26] = CreateConVar("survivor_upgrade_awards_boom_cork", "1", "Number of Boom-Cork Awards To Earn Upgrade", FCVAR_NOTIFY|FCVAR_PLUGIN, true, 0.0, true, 64.0);
	g_hAwardIndex[66] = CreateConVar("survivor_upgrade_awards_helping_hand", "5", "Number of Helping Hand Awards To Earn Upgrade", FCVAR_NOTIFY|FCVAR_PLUGIN, true, 0.0, true, 64.0);
	g_hAwardIndex[67] = CreateConVar("survivor_upgrade_awards_my_bodyguard", "10", "Number of My Bodyguard Awards To Earn Upgrade", FCVAR_NOTIFY|FCVAR_PLUGIN, true, 0.0, true, 64.0);
	g_hAwardIndex[68] = CreateConVar("survivor_upgrade_awards_pharm_assist", "10", "Number of Pharm-Assist Awards To Earn Upgrade", FCVAR_NOTIFY|FCVAR_PLUGIN, true, 0.0, true, 64.0);
	g_hAwardIndex[69] = CreateConVar("survivor_upgrade_awards_adrenaline", "5", "Number of Adrenaline Awards To Earn Upgrade", FCVAR_NOTIFY|FCVAR_PLUGIN, true, 0.0, true, 64.0);
	g_hAwardIndex[70] = CreateConVar("survivor_upgrade_awards_medic", "5", "Number of Medic Awards To Earn Upgrade", FCVAR_NOTIFY|FCVAR_PLUGIN, true, 0.0, true, 64.0);
	g_hAwardIndex[76] = CreateConVar("survivor_upgrade_awards_special_savior", "10", "Number of Special Savior Awards To Earn Upgrade", FCVAR_NOTIFY|FCVAR_PLUGIN, true, 0.0, true, 64.0);
	g_hAwardIndex[81] = CreateConVar("survivor_upgrade_awards_tankbusters", "1", "Number of Tankbusters Award To Earn Upgrade", FCVAR_NOTIFY|FCVAR_PLUGIN, true, 0.0, true, 64.0);
	g_hAwardIndex[84] = CreateConVar("survivor_upgrade_awards_teamkill", "1", "Number of Team Kill Penalties To Lose Upgrade", FCVAR_NOTIFY|FCVAR_PLUGIN, true, 0.0, true, 64.0);
	g_hAwardIndex[85] = CreateConVar("survivor_upgrade_awards_teamincapacitate", "1", "Number of Team-Incapacitate Penalty To Lose Upgrade", FCVAR_NOTIFY|FCVAR_PLUGIN, true, 0.0, true, 64.0);
	g_hAwardIndex[87] = CreateConVar("survivor_upgrade_awards_friendly_fire", "10", "Number of Friendly-Fire Penalty To Lose Upgrade", FCVAR_NOTIFY|FCVAR_PLUGIN, true, 0.0, true, 64.0);
	RegConsoleCmd("sm_upgrades", PrintToChatUpgrades, "List Upgrades.");

	g_iUpgradeIndex[0] = 1;
	g_hUpgradeIndex[0] = CreateConVar("survivor_upgrade_incendiary_ammo_enable", "1", "Enable/Disable Incendiary Ammo", FCVAR_NOTIFY|FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_iUpgradeIndex[1] = 2;
	g_hUpgradeIndex[1] = CreateConVar("survivor_upgrade_explosive_ammo_enable", "1", "Enable/Disable Explosive Ammo", FCVAR_NOTIFY|FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_iUpgradeIndex[2] = 4;
	g_hUpgradeIndex[2] = CreateConVar("survivor_upgrade_laser_sight_enable", "1", "Enable/Disable Laser Sight", FCVAR_NOTIFY|FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_iUpgradeIndex[3] = 8;
	g_hUpgradeIndex[3] = CreateConVar("survivor_upgrade_kevlar_armor_enable", "1", "Enable/Disable Kevlar Body Armor", FCVAR_NOTIFY|FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_iUpgradeIndex[4] = 16;
	g_hUpgradeIndex[4] = CreateConVar("survivor_upgrade_hot_meal_enable", "1", "Enable/Disable Hot Meal", FCVAR_NOTIFY|FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_iUpgradeIndex[5] = 32;
	g_hUpgradeIndex[5] = CreateConVar("survivor_upgrade_ointment_enable", "1", "Enable/Disable Ointment", FCVAR_NOTIFY|FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_iUpgradeIndex[6] = 64;
	g_hUpgradeIndex[6] = CreateConVar("survivor_upgrade_backpack_enable", "1", "Enable/Disable Ammo Backpack", FCVAR_NOTIFY|FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_iUpgradeIndex[7] = 128;
	g_hUpgradeIndex[7] = CreateConVar("survivor_upgrade_steroids_enable", "1", "Enable/Disable Steroids", FCVAR_NOTIFY|FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_iUpgradeIndex[8] = 256;
	g_hUpgradeIndex[8] = CreateConVar("survivor_upgrade_barrel_chamber_enable", "1", "Enable/Disable Barrel Chamber", FCVAR_NOTIFY|FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_iUpgradeIndex[9] = 512;
	g_hUpgradeIndex[9] = CreateConVar("survivor_upgrade_heavy_duty_enable", "1", "Enable/Disable Heavy Duty Batteries", FCVAR_NOTIFY|FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_iUpgradeIndex[10] = 1024;
	g_hUpgradeIndex[10] = CreateConVar("survivor_upgrade_bandages_enable", "1", "Enable/Disable Bandages", FCVAR_NOTIFY|FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_iUpgradeIndex[11] = 2048;
	g_hUpgradeIndex[11] = CreateConVar("survivor_upgrade_beta_blockers_enable", "1", "Enable/Disable Beta-Blockers", FCVAR_NOTIFY|FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_iUpgradeIndex[12] = 4092;
	g_hUpgradeIndex[12] = CreateConVar("survivor_upgrade_morphogenic_cells_enable", "1", "Enable/Disable Morphogenic Cells", FCVAR_NOTIFY|FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_iUpgradeIndex[13] = 8192;
	g_hUpgradeIndex[13] = CreateConVar("survivor_upgrade_air_boots_enable", "1", "Enable/Disable Air Boots", FCVAR_NOTIFY|FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_iUpgradeIndex[14] = 16384;
	g_hUpgradeIndex[14] = CreateConVar("survivor_upgrade_bandoliers_enable", "1", "Enable/Disable Bandoliers", FCVAR_NOTIFY|FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_iUpgradeIndex[15] = 32768;
	g_hUpgradeIndex[15] = CreateConVar("survivor_upgrade_hollow_point_enable", "1", "Enable/Disable Hollow Point Ammunition", FCVAR_NOTIFY|FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_iUpgradeIndex[16] = 65536;
	g_hUpgradeIndex[16] = CreateConVar("survivor_upgrade_knife_enable", "1", "Enable/Disable Knife", FCVAR_NOTIFY|FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_iUpgradeIndex[17] = 131072;
	g_hUpgradeIndex[17] = CreateConVar("survivor_upgrade_quick_heal_enable", "1", "Enable/Disable Quick Heal", FCVAR_NOTIFY|FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_iUpgradeIndex[18] = 262144;
	g_hUpgradeIndex[18] = CreateConVar("survivor_upgrade_smelling_salts_enable", "1", "Enable/Disable Smelling Salts", FCVAR_NOTIFY|FCVAR_PLUGIN, true, 0.0, true, 1.0);

	HookEvent("adrenaline_used", Event_AdrenalineUsed, EventHookMode_Post);
	HookEvent("pills_used", Event_PillsUsed, EventHookMode_Post);
	HookEvent("defibrillator_used", Event_DefibrillatorUsed, EventHookMode_Post);
	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode:3);
	HookEvent("item_pickup", Event_ItemPickup, EventHookMode_Post);
	HookEvent("player_use", Event_PlayerUse, EventHookMode_Post);
	HookEvent("ammo_pickup", Event_AmmoPickup, EventHookMode_Post);
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Post);
	HookEvent("survivor_rescued", Event_Rescued, EventHookMode_Post);
	HookEvent("award_earned", Event_AwardEarned, EventHookMode_Post);
	HookEvent("round_start", Round_Start, EventHookMode_Post);
	HookEvent("round_end", Round_End, EventHookMode_Pre);
	HookEvent("heal_success", Event_HealSuccess, EventHookMode_Post);
	HookEvent("map_transition", Round_End, EventHookMode_Pre);
	HookEvent("player_bot_replace", Event_BotReplacedPlayer, EventHookMode_Post);
	HookEvent("bot_player_replace", Event_PlayerReplacedBot, EventHookMode_Post);
	HookEvent("receive_upgrade", Event_ReceiveUpgrade, EventHookMode_Post);
	HookEvent("revive_success", Event_ReviveSuccess, EventHookMode_Post);
	HookEvent("player_incapacitated", Event_PlayerIncapacitated, EventHookMode_Post);
	HookEvent("heal_begin", Event_HealBegin, EventHookMode_Pre);
	HookEvent("revive_begin", Event_ReviveBegin, EventHookMode_Pre);
	HookEvent("player_hurt", Event_PlayerHurt, EventHookMode_Post);
	HookEvent("infected_hurt", Event_InfectedHurt, EventHookMode_Post);
	HookEvent("player_jump", Event_PlayerJump, EventHookMode_Post);
	
	SetConVarInt(FindConVar("pain_pills_health_threshold"), 150, false, false);
	g_fFirstAidDuration = GetConVarFloat(FindConVar("first_aid_kit_use_duration"));
	g_fReviveDuration = GetConVarFloat(FindConVar("survivor_revive_duration"));

	AutoExecConfig(true, "l4d2_upgradesreloaded", "sourcemod");
}

public Event_PlayerSpawn(Handle:event, String:name[], bool:Broadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(0 < client)
		CreateTimer(5.0, Event_TimerPlayerSpawn, client);
}

public Event_PlayerDeath(Handle:event, String:name[], bool:Broadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(client > 0)
	{
		if(GetConVarInt(g_hAwardIndex[0]))
			RemoveSurvivorUpgrade(client, GetConVarInt(g_hPenaltyUpgrades), 0);
	}
}

public Action:Event_TimerPlayerSpawn(Handle:timer, any:client)
{
	if(g_bRoundEnd || !IsClientInGame(client))
		return Plugin_Continue;

	if(IsFakeClient(client))
	{
		if(!HasIdlePlayer(client))
			CreateTimer(1.0, SetSurvivorUpgrades, client, 0);

		if(GetClientTeam(client) == 2)
			CreateTimer(1.0, SetSurvivorUpgrades, client, 0);
	}

	return Plugin_Continue;
}

public Event_Rescued(Handle:event, String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "victim"));
	if(client > 0)
		CreateTimer(1.0, SetSurvivorUpgrades, client, 0);
}

public Event_BotReplacedPlayer(Handle:event, String:name[], bool:dontBroadcast)
{
	new bot = GetClientOfUserId(GetEventInt(event, "bot"));
	if(bot > 0)
		CreateTimer(1.0, SetSurvivorUpgrades, bot, 0);
}

public Event_PlayerReplacedBot(Handle:event, String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "player"));
	if(client > 0)
		CreateTimer(1.0, SetSurvivorUpgrades, client, 0);
}

public Action:SetSurvivorUpgrades(Handle:timer, any:client)
{
	if(client > 0 && IsClientInGame(client))
	{
		if(0 < g_iUpgrade[client][3])
		{
			SetEntProp(client, Prop_Send, "m_ArmorValue", g_iArmorUpgradeAmt, 4, 0);
			SetEntProp(client, Prop_Send, "m_bHasHelmet", 1, 4, 0);
		}
		else
			SetEntProp(client, Prop_Send, "m_ArmorValue", g_iArmorDefaultAmt, 4, 0);

		if(0 < g_iUpgrade[client][4])
			SetEntProp(client, Prop_Send, "m_iMaxHealth", g_iHealthUpgradeAmt, 4, 0);
		else
			SetEntProp(client, Prop_Send, "m_iMaxHealth", g_iHealthDefaultAmt, 4, 0);

		if(0 < g_iUpgrade[client][2])
		{
			CheatCommand(client, "upgrade_add", "laser_sight", "");
			new iEnt = GetPlayerWeaponSlot(client, 1);
			if(0 < iEnt)
			{
				decl String:sClassname[64];
				GetEdictClassname(iEnt, sClassname, 32);
				if(!StrEqual(sClassname, "weapon_melee", true))
					SetEntProp(iEnt, Prop_Send, "m_upgradeBitVec", 4, 4, 0);
			}
		}

		EmitSoundToClient(client, "player/orch_hit_Csharp_short.wav", SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
	}

	return Plugin_Continue;
}

public Event_ItemPickup(Handle:event, String:name[], bool:Broadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(0 < client)
	{
		if(0 < g_iUpgrade[client][2])
		{
			CheatCommand(client, "upgrade_add", "laser_sight", "");
			new iEnt = GetPlayerWeaponSlot(client, 1);
			if(0 < iEnt)
			{
				decl String:sClassname[64];
				GetEdictClassname(iEnt, sClassname, 32);
				if(!StrEqual(sClassname, "weapon_melee", true))
					SetEntProp(iEnt, Prop_Send, "m_upgradeBitVec", any:4, 4, 0);
			}
		}
	
		if(0 < g_iUpgrade[client][6])
		{
			decl String:sItem[32];
			GetEventString(event, "item", sItem, 32);

			if(StrContains(sItem, "smg", false) == -1)
				GivePlayerAmmo(client);
			if(StrEqual(sItem, "weapon_rifle_m60", true))
				UpgradeBandoliers(client);
		}
	}
}

public Action:Event_PlayerUse(Handle:event, String:name[], bool:dontBroadcast)
{
	new targetid = GetEventInt(event, "targetid");
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(0 < targetid && 0 < client)
	{
		decl String:sItem[64];
		GetEdictClassname(targetid, sItem, 64);
		if(StrContains(sItem, "ammo", false) != -1)
		{
			if(0 < g_iUpgrade[client][6])
			{
				ClearPlayerAmmo(client);
				CheatCommand(client, "give", "ammo", "");
				GivePlayerAmmo(client);
			}

			if(0 < g_iUpgrade[client][14])
				UpgradeBandoliers(client);
		}
	}

	return Plugin_Continue;
}

public Event_AmmoPickup(Handle:event, String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(client > 0)
	{
		GivePlayerAmmo(client);
	}
}

GivePlayerAmmo(client)
{
	new iEnt = GetPlayerWeaponSlot(client, 0);
	if(iEnt > 0 && IsValidEntity(iEnt))
	{
		new m_iAmmo = FindDataMapOffs(client, "m_iAmmo");
		SetEntData(client, m_iAmmo + 12, CheckWeaponUpgradeLimit(iEnt) - GetEntProp(iEnt, Prop_Send, "m_iClip1", 4, 0) + 540, 4, false);
		SetEntData(client, m_iAmmo + 20, CheckWeaponUpgradeLimit(iEnt) - GetEntProp(iEnt, Prop_Send, "m_iClip1", 4, 0) + 975, 4, false);
		SetEntData(client, m_iAmmo + 28, CheckWeaponUpgradeLimit(iEnt) - GetEntProp(iEnt, Prop_Send, "m_iClip1", 4, 0) + 84, 4, false);
		SetEntData(client, m_iAmmo + 32, CheckWeaponUpgradeLimit(iEnt) - GetEntProp(iEnt, Prop_Send, "m_iClip1", 4, 0) + 135, 4, false);
		SetEntData(client, m_iAmmo + 36, CheckWeaponUpgradeLimit(iEnt) - GetEntProp(iEnt, Prop_Send, "m_iClip1", 4, 0) + 225, 4, false);
		SetEntData(client, m_iAmmo + 40, CheckWeaponUpgradeLimit(iEnt) - GetEntProp(iEnt, Prop_Send, "m_iClip1", 4, 0) + 270, 4, false);
	}
}

ClearPlayerAmmo(client)
{
	new m_iAmmo = FindDataMapOffs(client, "m_iAmmo");
	SetEntData(client, m_iAmmo + 12, 0, 4, false);
	SetEntData(client, m_iAmmo + 20, 0, 4, false);
	SetEntData(client, m_iAmmo + 28, 0, 4, false);
	SetEntData(client, m_iAmmo + 32, 0, 4, false);
	SetEntData(client, m_iAmmo + 36, 0, 4, false);
	SetEntData(client, m_iAmmo + 40, 0, 4, false);
}

public OnClientPostAdminCheck(client)
{
	ClientSaveToFileLoad(client);
	//Slowhacking Baaaaaad!
	//ClientCommand(client, "bind f3 sm_upgrades");
}

public OnClientDisconnect(client)
{
	ClientSaveToFileSave(client);
}

public GiveSurvivorUpgrade(client, amount, awardid)
{
	new num = 0;
	while (num < amount)
	{
		decl String:ClientUserName[32];
		GetClientName(client, ClientUserName, 32);
		new numOwned = GetSurvivorUpgrades(client);
		if(GetAvailableUpgrades() == numOwned)
		{
			new i = 1;
			while (i <= MaxClients)
			{
				if(IsClientInGame(i))
				{
					PrintToChat(i, "\x03%s ", ClientUserName, g_sAwardTitle[awardid]);
					i++;
				}
				i++;
			}

			return;
		}
		new offset = GetRandomInt(0, GetAvailableUpgrades() - numOwned + 1);
		new val = 0;
		while (offset > 0 || g_iUpgrade[client][val] || GetConVarInt(g_hUpgradeIndex[val]) == 1)
		{
			if(!g_iUpgrade[client][val])
			{
				offset--;
			}
			val++;
		}
		if(IsPlayerAlive(client))
		{
			GiveUpgrade(client, val);
			new i = 1;
			while (i <= MaxClients)
			{
				if(IsClientInGame(i))
				{
					PrintToChat(i, "\x03%s ", ClientUserName, g_sUpgradeShort[val], g_sAwardTitle[awardid]);
					i++;
				}
				i++;
			}
			num++;
		}
		num++;
	}
}

public RemoveSurvivorUpgrade(client, amount, awardid)
{
	new num = 0;
	while (num < amount)
	{
		decl String:ClientUserName[32];
		GetClientName(client, ClientUserName, 32);
		new numMiss = MissingSurvivorUpgrades(client);
		if(numMiss == 19)
		{
			new i = 1;
			while (i <= MaxClients)
			{
				if(IsClientInGame(i))
				{
					PrintToChat(i, "\x03%s ", ClientUserName);
					i++;
				}
				i++;
			}

			return;
		}
		new offset = GetRandomInt(0, GetAvailableUpgrades() - numMiss + 1);
		new val = 0;
		while (offset > 0 || !g_iUpgrade[client][val])
		{
			if(g_iUpgrade[client][val])
			{
				offset--;
			}
			val++;
		}
		RemoveUpgrade(client, val);
		new i = 1;
		while (i <= MaxClients)
		{
			if(IsClientInGame(i))
			{
				PrintToChat(i, "\x03%s ", ClientUserName, g_sUpgradeShort[val], g_sAwardTitle[awardid]);
				i++;
			}
			i++;
		}
		num++;
	}
}

public GiveUpgrade(client, upgrade)
{
	new i = 0;
	while (i < 19)
	{
		if(client > 0)
		{
			g_iUpgrade[client][upgrade] = g_iUpgradeIndex[upgrade];
			new var3 = g_iBitsUpgrade[client];
			var3 = g_iUpgrade[client][upgrade] + var3;
			CreateTimer(1.0, SetSurvivorUpgrades, client, 0);
			if(g_iUpgradeIndex[upgrade] == 1)
			{
				new iEnt = GetPlayerWeaponSlot(client, 0);
				if(0 < iEnt)
				{
					new iUPGRADE_AMMO = GetEntProp(iEnt, Prop_Send, "m_nUpgradedPrimaryAmmoLoaded", 4, 0);
					iUPGRADE_AMMO = CheckWeaponUpgradeLimit(iEnt) + iUPGRADE_AMMO;
					if(g_iUpgradeIndex[upgrade] == 1)
					{
						CheatCommand(client, "upgrade_add", "incendiary_ammo", "");
					}
					if(g_iUpgradeIndex[upgrade] == 2)
					{
						CheatCommand(client, "upgrade_add", "explosive_ammo", "");
					}
					if(iUPGRADE_AMMO > 100)
					{
						SetEntProp(iEnt, Prop_Send, "m_nUpgradedPrimaryAmmoLoaded", any:100, 4, 0);
					}
					else
					{
						SetEntProp(iEnt, Prop_Send, "m_nUpgradedPrimaryAmmoLoaded", iUPGRADE_AMMO, 4, 0);
					}
				}
				g_iUpgrade[client][upgrade] = 0;
				i++;
			}
			i++;
		}
		i++;
	}
}

public RemoveUpgrade(client, upgrade)
{
	new i = 0;
	while (i < 19)
	{
		if(client > 0)
		{
			g_iUpgrade[client][upgrade] = 0;
			new var2 = g_iBitsUpgrade[client];
			var2 = var2 - g_iUpgradeIndex[upgrade];
			CreateTimer(1.0, SetSurvivorUpgrades, client, 0);
			i++;
		}
		i++;
	}
}

CheckWeaponUpgradeLimit(weapon)
{
	new UpgradeLimit = 0;
	decl String:sClassname[64];
	GetEdictClassname(weapon, sClassname, 32);
	if(StrEqual(sClassname, "weapon_rifle", true))
	{
		UpgradeLimit = 50;
	}
	else
	{
		if(StrEqual(sClassname, "weapon_rifle_desert", true))
		{
			UpgradeLimit = 60;
		}
		if(StrEqual(sClassname, "weapon_rifle_ak47", true))
		{
			UpgradeLimit = 40;
		}
		if(StrEqual(sClassname, "weapon_pumpshotgun", true))
		{
			UpgradeLimit = 8;
		}
		if(StrEqual(sClassname, "weapon_autoshotgun", true))
		{
			UpgradeLimit = 10;
		}
		if(StrEqual(sClassname, "weapon_hunting_rifle", true))
		{
			UpgradeLimit = 15;
		}
		if(StrEqual(sClassname, "weapon_sniper_military", true))
		{
			UpgradeLimit = 30;
		}
		if(StrEqual(sClassname, "weapon_grenade_launcher", true))
		{
			UpgradeLimit = 1;
		}
	}
	return UpgradeLimit;
}

public GetAvailableUpgrades()
{
	new upgrades = 0;
	new i = 0;
	while (i < 19)
	{
		if(0 < GetConVarInt(g_hUpgradeIndex[i]))
		{
			upgrades++;
			i++;
		}
		i++;
	}
	return upgrades;
}

public GetSurvivorUpgrades(client)
{
	new upgrades = 0;
	new i = 0;
	while (i < 19)
	{
		if(0 < g_iUpgrade[client][i])
		{
			upgrades++;
			i++;
		}
		i++;
	}
	return upgrades;
}

public ResetClientUpgrades(client)
{
	new i = 0;
	while (i < 19)
	{
		g_iUpgrade[client][i] = 0;
		i++;
	}
	g_iBitsUpgrade[client] = 0;
}

public MissingSurvivorUpgrades(client)
{
	new upgrades = 0;
	new i = 0;
	while (i < 19)
	{
		if(0 >= g_iUpgrade[client][i])
		{
			upgrades++;
			i++;
		}
		i++;
	}
	return upgrades;
}

public Action:PrintToChatUpgrades(client, args)
{
	DisplayUpgradeMenu(client);
	return Plugin_Continue;
}

public DisplayUpgradeMenu(client)
{
	if(GetClientTeam(client) == 2)
	{
		new Handle:UpgradePanel = CreatePanel(Handle:0);
		decl String:buffer[256];
		Format(buffer, 255, "Survivor Upgrades (%d/%d)", GetSurvivorUpgrades(client), GetAvailableUpgrades() + -2);
		SetPanelTitle(UpgradePanel, buffer, false);
		new i = 1;
		while (i <= MaxClients)
		{
			if(IsClientConnected(i))
			{
				if(!IsClientInGame(i))
				{
				}
				else
				{
					if(GetClientTeam(i) == 2)
					{
						decl String:text[64];
						new percentage = RoundFloat(float(GetSurvivorUpgrades(i)) / GetAvailableUpgrades() + -2 * 100);
						decl String:ClientUserName[64];
						GetClientName(i, ClientUserName, 64);
						Format(text, 64, "%s (%d%%)", ClientUserName, percentage);
						DrawPanelText(UpgradePanel, text);
					}
				}
			}
			i++;
		}
		DrawPanelItem(UpgradePanel, "Display Upgrades", 0);
		DrawPanelItem(UpgradePanel, "Toggle Notifications", 0);
		DrawPanelItem(UpgradePanel, "Reset Upgrades", 0);
		SendPanelToClient(UpgradePanel, client, DisplayUpgradeMenuHandler, 30);
		CloseHandle(UpgradePanel);
	}
	else
	{
		PrintToChat(client, "");
	}
}

public DisplayUpgradeMenuHandler(Handle:UpgradePanel, MenuAction:action, param1, param2)
{
	new client = param1;
	if(action == MenuAction_Select)
	{
		if(param2 == 1)
		{
			new upgrade = 0;
			while (upgrade < 31)
			{
				if(0 < g_iUpgrade[client][upgrade])
				{
					PrintToChat(client, "%s", g_sUpgradeTitle[upgrade]);
					upgrade++;
				}
				upgrade++;
			}
		}
		else
		{
			if(param2 == 2)
			{
				if(g_bAnnounceText[client] != true)
				{
					g_bAnnounceText[client] = true;
					PrintToChat(client, "");
				}
				else
				{
					g_bAnnounceText[client] = false;
					PrintToChat(client, "");
				}
			}
			if(param2 == 3)
			{
				ResetClientUpgrades(client);
				PrintToChat(client, "");
			}
		}
	}
	else if(action == MenuAction_End)
		CloseHandle(UpgradePanel);
}

public Event_AwardEarned(Handle:event, String:name[], bool:Broadcast)
{
	if(g_bRoundEnd)
		return;

	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new achievementid = GetEventInt(event, "award");
	if(achievementid == 14)
	{
		g_iCount[client][achievementid] += 1;
		if(GetConVarInt(g_hAwardIndex[achievementid]) <= g_iCount[client][achievementid])
		{
			GiveSurvivorUpgrade(client, 1, achievementid);
			g_iCount[client][achievementid] = 0;
		}
	}
	if(achievementid == 15)
	{
		g_iCount[client][achievementid] += 1;
		if(GetConVarInt(g_hAwardIndex[achievementid]) <= g_iCount[client][achievementid])
		{
			GiveSurvivorUpgrade(client, 1, achievementid);
			g_iCount[client][achievementid] = 0;
		}
	}
	if(achievementid == 18)
	{
		g_iCount[client][achievementid] += 1;
		if(GetConVarInt(g_hAwardIndex[achievementid]) <= g_iCount[client][achievementid])
		{
			GiveSurvivorUpgrade(client, 1, achievementid);
			g_iCount[client][achievementid] = 0;
		}
	}
	if(achievementid == 19)
	{
		g_iCount[client][achievementid] += 1;
		if(GetConVarInt(g_hAwardIndex[achievementid]) <= g_iCount[client][achievementid])
		{
			GiveSurvivorUpgrade(client, 1, achievementid);
			g_iCount[client][achievementid] = 0;
		}
	}
	if(achievementid == 21)
	{
		g_iCount[client][achievementid] += 1;
		if(GetConVarInt(g_hAwardIndex[achievementid]) <= g_iCount[client][achievementid])
		{
			GiveSurvivorUpgrade(client, 1, achievementid);
			g_iCount[client][achievementid] = 0;
		}
	}
	if(achievementid == 26)
	{
		g_iCount[client][achievementid] += 1;
		if(GetConVarInt(g_hAwardIndex[achievementid]) <= g_iCount[client][achievementid])
		{
			GiveSurvivorUpgrade(client, 1, achievementid);
			g_iCount[client][achievementid] = 0;
		}
	}
	if(achievementid == 66)
	{
		g_iCount[client][achievementid] += 1;
		if(GetConVarInt(g_hAwardIndex[achievementid]) <= g_iCount[client][achievementid])
		{
			GiveSurvivorUpgrade(client, 1, achievementid);
			g_iCount[client][achievementid] = 0;
		}
	}
	if(achievementid == 67)
	{
		g_iCount[client][achievementid] += 1;
		if(GetConVarInt(g_hAwardIndex[achievementid]) <= g_iCount[client][achievementid])
		{
			GiveSurvivorUpgrade(client, 1, achievementid);
			g_iCount[client][achievementid] = 0;
		}
	}
	if(achievementid == 68)
	{
		g_iCount[client][achievementid] += 1;
		if(GetConVarInt(g_hAwardIndex[achievementid]) <= g_iCount[client][achievementid])
		{
			GiveSurvivorUpgrade(client, 1, achievementid);
			g_iCount[client][achievementid] = 0;
		}
	}
	if(achievementid == 69)
	{
		g_iCount[client][achievementid] += 1;
		if(GetConVarInt(g_hAwardIndex[achievementid]) <= g_iCount[client][achievementid])
		{
			GiveSurvivorUpgrade(client, 1, achievementid);
			g_iCount[client][achievementid] = 0;
		}
	}
	if(achievementid == 70)
	{
		g_iCount[client][achievementid] += 1;
		if(GetConVarInt(g_hAwardIndex[achievementid]) <= g_iCount[client][achievementid])
		{
			GiveSurvivorUpgrade(client, 1, achievementid);
			g_iCount[client][achievementid] = 0;
		}
	}
	if(achievementid == 76)
	{
		g_iCount[client][achievementid] += 1;
		if(GetConVarInt(g_hAwardIndex[achievementid]) <= g_iCount[client][achievementid])
		{
			GiveSurvivorUpgrade(client, 1, achievementid);
			g_iCount[client][achievementid] = 0;
		}
	}
	if(achievementid == 81)
	{
		g_iCount[client][achievementid] += 1;
		if(GetConVarInt(g_hAwardIndex[achievementid]) <= g_iCount[client][achievementid])
		{
			GiveSurvivorUpgrade(client, 1, achievementid);
			g_iCount[client][achievementid] = 0;
		}
	}
	if(achievementid == 84)
	{
		g_iCount[client][achievementid] += 1;
		if(GetConVarInt(g_hAwardIndex[achievementid]) <= g_iCount[client][achievementid])
		{
			RemoveSurvivorUpgrade(client, 1, achievementid);
			g_iCount[client][achievementid] = 0;
		}
	}
	if(achievementid == 85)
	{
		g_iCount[client][achievementid] += 1;
		if(GetConVarInt(g_hAwardIndex[achievementid]) <= g_iCount[client][achievementid])
		{
			RemoveSurvivorUpgrade(client, 1, achievementid);
			g_iCount[client][achievementid] = 0;
		}
	}
	if(achievementid == 87)
	{
		g_iCount[client][achievementid] += 1;
		if(GetConVarInt(g_hAwardIndex[achievementid]) <= g_iCount[client][achievementid])
		{
			RemoveSurvivorUpgrade(client, 1, achievementid);
			g_iCount[client][achievementid] = 0;
		}
	}
}

public Action:Round_Start(Handle:event, String:name[], bool:dontBroadcast)
{
	g_bRoundEnd = false;
	
	return Plugin_Continue;
}

public Action:Round_End(Handle:event, String:name[], bool:dontBroadcast)
{
	g_bRoundEnd = true;
	return Plugin_Continue;
}

public Event_HealSuccess(Handle:event, String:name[], bool:Broadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new subject = GetClientOfUserId(GetEventInt(event, "subject"));
	//...? new m_iHealth = GetEventInt(event, "health_restored");
	new m_iMaxHealth = GetEntData(subject, FindDataMapOffs(subject, "m_iMaxHealth"), 4);
	if(0 < g_iUpgrade[client][5])
		SetEntData(subject, FindDataMapOffs(subject, "m_iHealth"), g_iHealthDefaultAmt, 4, true);

	if(g_iUpgrade[subject][4] > 0)
	{
		SetEntData(subject, FindDataMapOffs(subject, "m_iHealth"), RoundFloat(GetConVarFloat(FindConVar("first_aid_heal_percent")) * m_iMaxHealth), 4, true);
		if(0 < g_iUpgrade[client][5])
			SetEntData(subject, FindDataMapOffs(subject, "m_iHealth"), m_iMaxHealth, 4, true);
	}
}

ClientSaveToFileSave(targetid)
{
	decl Handle:kv;
	decl String:cName[32];
	kv = CreateKeyValues("SurvivorUpgradesReloaded", "", "");
	FileToKeyValues(kv, g_sSavePath);
	GetClientAuthString(targetid, cName, 32);
	KvJumpToKey(kv, cName, true);
	new i = 0;
	while (i < 19)
	{
		decl String:buffer[512];
		Format(buffer, 512, "Upgrade #%i", i);
		KvSetNum(kv, buffer, g_iUpgrade[targetid][i]);
		i++;
	}
	KvRewind(kv);
	KeyValuesToFile(kv, g_sSavePath);
	CloseHandle(kv);
}

ClientSaveToFileLoad(targetid)
{
	decl Handle:kv;
	decl String:cName[32];
	kv = CreateKeyValues("SurvivorUpgradesReloaded", "", "");
	FileToKeyValues(kv, g_sSavePath);
	GetClientAuthString(targetid, cName, 32);
	KvJumpToKey(kv, cName, true);
	g_iBitsUpgrade[targetid] = 0;
	new i = 0;
	while (i < 19)
	{
		decl String:buffer[512];
		Format(buffer, 512, "Upgrade #%i", i);
		g_iUpgrade[targetid][i] = KvGetNum(kv, buffer, 0);
		new var1 = g_iBitsUpgrade[targetid];
		var1 = g_iUpgrade[targetid][i] + var1;
		i++;
	}
	CloseHandle(kv);
}

public Event_PillsUsed(Handle:event, String:name[], bool:Broadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	UpgradeChemist(client, 1);
}

public Event_AdrenalineUsed(Handle:event, String:name[], bool:Broadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	UpgradeChemist(client, 2);
}

public Event_DefibrillatorUsed(Handle:event, String:name[], bool:Broadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new subject = GetClientOfUserId(GetEventInt(event, "subject"));
	UpgradeHeavyDutyBatteries(client, subject);
}

public Event_ReceiveUpgrade(Handle:event, String:name[], bool:Broadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	UpgradeBarrelChamber(client);
}

public Event_ReviveSuccess(Handle:event, String:name[], bool:Broadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new subject = GetClientOfUserId(GetEventInt(event, "subject"));
	UpgradeSteroids(client, subject);
	UpgradeMorphogenicCells(subject);
}

public Event_PlayerIncapacitated(Handle:event, String:name[], bool:Broadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	UpgradeBetaBlockers(client);
	if(g_hTimer_Morphogenic[client] != INVALID_HANDLE)
	{
		KillTimer(g_hTimer_Morphogenic[client], false);
		g_hTimer_Morphogenic[client] = INVALID_HANDLE;
	}
	if(g_hTimer_Regeneration[client] != INVALID_HANDLE)
	{
		KillTimer(g_hTimer_Regeneration[client], false);
		g_hTimer_Regeneration[client] = INVALID_HANDLE;
	}
}

public Event_PlayerHurt(Handle:event, String:name[], bool:Broadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new dmg_health = GetEventInt(event, "dmg_health");
	new health = GetEntData(client, FindDataMapOffs(client, "m_iHealth"), 4);
	if(g_hTimer_Morphogenic[client] != INVALID_HANDLE)
	{
		KillTimer(g_hTimer_Morphogenic[client], false);
		g_hTimer_Morphogenic[client] = INVALID_HANDLE;
	}
	if(g_hTimer_Regeneration[client] != INVALID_HANDLE)
	{
		KillTimer(g_hTimer_Regeneration[client], false);
		g_hTimer_Regeneration[client] = INVALID_HANDLE;
	}
	UpgradeMorphogenicCells(client);
	UpgradeHollowPointAmmunition(client, attacker, dmg_health, health, 1);
}

public Event_InfectedHurt(Handle:event, String:name[], bool:Broadcast)
{
	new entityid = GetEventInt(event, "entityid");
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new amount = GetEventInt(event, "amount");
	new health = GetEntProp(entityid, Prop_Data, "m_iHealth", 4, 0);
	UpgradeHollowPointAmmunition(entityid, attacker, amount, health, 2);
}

public Action:Timer_MorphogenicTimer(Handle:timer, any:client)
{
	g_hTimer_Morphogenic[client] = INVALID_HANDLE;
	g_hTimer_Regeneration[client] = CreateTimer(0.1, Timer_RegenerationTimer, client, 1);
	return Plugin_Continue;
}

public Event_PlayerJump(Handle:event, String:name[], bool:Broadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(GetClientTeam(client) == 2)
	{
		UpgradeAirBoots(client);
	}
}

public Event_HealBegin(Handle:event, String:name[], bool:Broadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	UpgradeQuickHeal(client);
}

public Event_ReviveBegin(Handle:event, String:name[], bool:Broadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	UpgradeSmellingSalts(client);
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if(client)
	{
		if(buttons & 2048)
		{
			UpgradeKnife(client);
		}
		return Plugin_Continue;
	}
	return Plugin_Continue;
}

public UpgradeChemist(client, type)
{
	if(type == 1)
	{
		new Float:m_iHealth = float(GetEntData(client, FindDataMapOffs(client, "m_iHealth"), 4));
		new Float:m_iMaxHealth = float(GetEntData(client, FindDataMapOffs(client, "m_iMaxHealth"), 4));
		new Float:m_iHealthBufferBits = 0.5 * GetConVarInt(FindConVar("pain_pills_health_value"));
		new Float:m_iHealthBuffer = GetEntDataFloat(client, FindSendPropOffs("CTerrorPlayer", "m_healthBuffer"));
		if(0 < g_iUpgrade[client][7])
		{
			if(m_iHealth + m_iHealthBuffer + m_iHealthBufferBits > m_iMaxHealth)
			{
				m_iHealthBufferBits = m_iMaxHealth - m_iHealth;
				SetEntPropFloat(client, Prop_Send, "m_healthBuffer", m_iHealthBufferBits, 0);
			}
			SetEntPropFloat(client, Prop_Send, "m_healthBuffer", m_iHealthBuffer + m_iHealthBufferBits, 0);
		}
	}
	if(type == 2)
	{
		new Float:m_iHealth = float(GetEntData(client, FindDataMapOffs(client, "m_iHealth"), 4));
		new Float:m_iMaxHealth = float(GetEntData(client, FindDataMapOffs(client, "m_iMaxHealth"), 4));
		new Float:m_iHealthBufferBits = 0.5 * GetConVarInt(FindConVar("adrenaline_health_buffer"));
		new Float:m_iHealthBuffer = GetEntDataFloat(client, FindSendPropOffs("CTerrorPlayer", "m_healthBuffer"));
		if(0 < g_iUpgrade[client][7])
		{
			if(m_iHealth + m_iHealthBuffer + m_iHealthBufferBits > m_iMaxHealth)
			{
				m_iHealthBufferBits = m_iMaxHealth - m_iHealth;
				SetEntPropFloat(client, Prop_Send, "m_healthBuffer", m_iHealthBufferBits, 0);
			}
			SetEntPropFloat(client, Prop_Send, "m_healthBuffer", m_iHealthBuffer + m_iHealthBufferBits, 0);
		}
	}
}

public UpgradeHeavyDutyBatteries(client, subject)
{
	if(0 < g_iUpgrade[client][9])
	{
		new Float:m_iHealth = float(GetEntData(subject, FindDataMapOffs(subject, "m_iHealth"), 4));
		SetEntData(subject, FindDataMapOffs(subject, "m_iHealth"), RoundFloat(1.5 * m_iHealth), 4, true);
	}
}

public UpgradeBarrelChamber(client)
{
	if(0 < g_iUpgrade[client][8])
	{
		new iEnt = GetPlayerWeaponSlot(client, 0);
		new Float:iPrimaryAmmoLoaded = float(GetEntProp(iEnt, Prop_Send, "m_nUpgradedPrimaryAmmoLoaded", 4, 0));
		SetEntProp(iEnt, Prop_Send, "m_nUpgradedPrimaryAmmoLoaded", RoundFloat(1.5 * iPrimaryAmmoLoaded), 4, 0);
	}
}

public UpgradeSteroids(client, subject)
{
	if(0 < g_iUpgrade[subject][10])
	{
		new Float:m_iHealthBuffer = 1.5 * float(GetConVarInt(FindConVar("survivor_revive_health")));
		SetEntPropFloat(subject, Prop_Send, "m_healthBuffer", m_iHealthBuffer, 0);
	}
}

public UpgradeBetaBlockers(client)
{
	if(0 < g_iUpgrade[client][11])
	{
		new m_iHealthBuffer = RoundFloat(1.5 * GetConVarInt(FindConVar("survivor_incap_health")));
		SetEntProp(client, Prop_Send, "m_iHealth", m_iHealthBuffer, 4, 0);
	}
}

public UpgradeMorphogenicCells(client)
{
	if(0 < g_iUpgrade[client][12])
	{
		//new m_iHealth = GetEntData(client, FindDataMapOffs(client, "m_iHealth"), 4);
		//new m_iMaxHealth = GetEntData(client, FindDataMapOffs(client, "m_iMaxHealth"), 4);
		if(GetClientTeam(client) == 2)
		{
			g_hTimer_Morphogenic[client] = CreateTimer(10.0, Timer_MorphogenicTimer, client, 0);
		}
	}
}

public Action:Timer_RegenerationTimer(Handle:timer, any:client)
{
	if(IsClientInGame(client))
	{
		new m_iHealth = GetEntData(client, FindDataMapOffs(client, "m_iHealth"), 4);
		new m_iMaxHealth = GetEntData(client, FindDataMapOffs(client, "m_iMaxHealth"), 4);
		if(RoundFloat(0.5 * m_iMaxHealth) <= m_iHealth)
		{
			g_hTimer_Regeneration[client] = INVALID_HANDLE;
			return Plugin_Stop;
		}
		SetEntData(client, FindDataMapOffs(client, "m_iHealth"), m_iHealth + 1, 4, true);
		return Plugin_Continue;
	}
	return Plugin_Handled;
}

public UpgradeBandoliers(client)
{
	if(0 < g_iUpgrade[client][14])
	{
		new iEnt = GetPlayerWeaponSlot(client, 0);
		if(0 < iEnt)
		{
			decl String:sClassname[64];
			GetEdictClassname(iEnt, sClassname, 32);
			if(StrEqual(sClassname, "weapon_rifle_m60", true))
			{
				if(0 < g_iUpgrade[client][6])
				{
					SetEntProp(iEnt, Prop_Send, "m_iClip1", any:225, 1, 0);
				}
				else
				{
					SetEntProp(iEnt, Prop_Send, "m_iClip1", any:150, 1, 0);
				}
			}
			else
			{
				if(StrEqual(sClassname, "weapon_grenade_launcher", true))
				{
					if(0 < g_iUpgrade[client][6])
					{
						new m_iAmmo = FindDataMapOffs(client, "m_iAmmo");
						SetEntData(client, m_iAmmo + 68, CheckWeaponUpgradeLimit(iEnt) - GetEntProp(iEnt, Prop_Send, "m_iClip1", 4, 0) + 45, 4, false);
					}
				}
			}
		}
	}
}

public UpgradeAirBoots(client)
{
	if(g_iUpgrade[client][13] > 0)
	{
		SetEntDataFloat(client, FindDataMapOffs(client, "m_flGravity"), 0.75, false);
	}
	else
	{
		SetEntDataFloat(client, FindDataMapOffs(client, "m_flGravity"), 1.0, false);
	}
}

public UpgradeHollowPointAmmunition(client, attacker, dmg_health, health, type)
{
	if(0 < g_iUpgrade[attacker][15])
	{
		new m_iHealth = health - RoundFloat(0.5 * float(dmg_health));
		if(m_iHealth < 1)
		{
			return;
		}
		if(GetClientTeam(attacker) == 2)
		{
			SetEntityHealth(client, m_iHealth);
		}
		if(GetClientTeam(attacker) == 2)
		{
			SetEntProp(client, Prop_Data, "m_iHealth", m_iHealth, 4, 0);
		}
	}
}

public UpgradeKnife(client)
{
	if(0 < g_iUpgrade[client][16])
	{
		decl String:ClientUserName[64];
		GetClientName(client, ClientUserName, 64);
		if(IsClientInGame(client))
		{
			if(0 < GetEntPropEnt(client, Prop_Send, "m_pounceAttacker", 0))
			{
				ForcePlayerSuicide(GetEntPropEnt(client, Prop_Send, "m_pounceAttacker", 0));
				EmitSoundToClient(client, "weapons/knife/knife_hitwall1.wav", SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
				PrintToChatAll("%s used a Knife!", ClientUserName);
				RemoveUpgrade(client, 16);
			}
			if(0 < GetEntPropEnt(client, Prop_Send, "m_jockeyAttacker", 0))
			{
				ForcePlayerSuicide(GetEntPropEnt(client, Prop_Send, "m_jockeyAttacker", 0));
				EmitSoundToClient(client, "weapons/knife/knife_hitwall1.wav", SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
				PrintToChatAll("%s used a Knife!", ClientUserName);
				RemoveUpgrade(client, 16);
			}
			if(0 < GetEntPropEnt(client, Prop_Send, "m_pummelAttacker", 0))
			{
				ForcePlayerSuicide(GetEntPropEnt(client, Prop_Send, "m_pummelAttacker", 0));
				EmitSoundToClient(client, "weapons/knife/knife_hitwall1.wav", SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
				PrintToChatAll("%s used a Knife!", ClientUserName);
				RemoveUpgrade(client, 16);
			}
			if(0 < GetEntPropEnt(client, Prop_Send, "m_tongueOwner", 0))
			{
				ForcePlayerSuicide(GetEntPropEnt(client, Prop_Send, "m_tongueOwner", 0));
				EmitSoundToClient(client, "weapons/knife/knife_hitwall1.wav", SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
				PrintToChatAll("%s used a Knife!", ClientUserName);
				RemoveUpgrade(client, 16);
			}
		}
	}
}

public UpgradeQuickHeal(client)
{
	if(0 < g_iUpgrade[client][17])
	{
		SetConVarFloat(FindConVar("first_aid_kit_use_duration"), g_fFirstAidDuration / 2, false, false);
	}
	else
	{
		SetConVarFloat(FindConVar("first_aid_kit_use_duration"), g_fFirstAidDuration, false, false);
	}
}

public UpgradeSmellingSalts(client)
{
	if(0 < g_iUpgrade[client][18])
	{
		SetConVarFloat(FindConVar("survivor_revive_duration"), g_fReviveDuration / 2, false, false);
	}
	else
	{
		SetConVarFloat(FindConVar("survivor_revive_duration"), g_fReviveDuration, false, false);
	}
}

bool:HasIdlePlayer(bot)
{
	new userid = GetEntData(bot, FindSendPropInfo("SurvivorBot", "m_humanSpectatorUserID"), 4);
	new client = GetClientOfUserId(userid);
	if(0 < client)
	{
		if(IsClientConnected(client))
		{
			return true;
		}
	}
	return false;
}

CheatCommand(client, String:command[], String:argument1[], String:argument2[])
{
	new userFlags = GetUserFlagBits(client);
	SetUserFlagBits(client, 16384);
	new flags = GetCommandFlags(command);
	SetCommandFlags(command, flags & -16385);
	FakeClientCommand(client, "%s %s %s", command, argument1, argument2);
	SetCommandFlags(command, flags);
	SetUserFlagBits(client, userFlags);
}