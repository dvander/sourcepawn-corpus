/* Domination DeathMatch
* by: InstantDeath
* 
* current Features:
* 
* 	-custom buy menu
* 	-Advanced Spawn Protection
* 	-Increased cash for kill by specific weapon
* 	-ATM/bank system
* 	-Bonus cash for headshot kills
* 	-Lives system
* 	-In game modification of cash kill setting
* 	-domination rewarda
* 	
* 
* Credits:
*
*	Pred - coding for part of spawn protection.
*	bl4nk
*	SAMUARI16
* 	Those helpful guys in the #sourcemod channel in irc
*
*
*
*	Author Notes:
*	Team Domination Modes:
*	0 - TeamATMacct steal
*	1 - Damage
*	2 - Enemy Player steal
*	3 - Health Regen
* */

#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <hacks>

#pragma semicolon 1

#define TEAM_T	2
#define TEAM_CT 3
#define CTs_Win	8
#define Terrorists_Win 9
#define bomb_exploded 1
#define bomb_defused 7
#define CT_acct 65
#define T_acct 64
#define PLUGIN_VERSION "2.1"

#define Slot_HEgrenade 11
#define Slot_Flashbang 12
#define Slot_Smokegrenade 13

new Handle:cvarrespawncount = INVALID_HANDLE;
new Handle:cvarrespawntime = INVALID_HANDLE;
//new Handle:cvarspawnprotect = INVALID_HANDLE;
new Handle:cvarheadshotbonus = INVALID_HANDLE;
new Handle:cvarextralifecost = INVALID_HANDLE;
new Handle:cvardomination = INVALID_HANDLE;
new Handle:cvardominationcash = INVALID_HANDLE;
new Handle:cvardominationcashbonus = INVALID_HANDLE;
new Handle:cvarteamacct = INVALID_HANDLE;
new Handle:cvarmaxwithdraw = INVALID_HANDLE;
new Handle:cvarheadshotdom = INVALID_HANDLE;
new Handle:cvarweapondomreq = INVALID_HANDLE;
new Handle:cvarcustomspawn = INVALID_HANDLE;
new Handle:spawnfile		= INVALID_HANDLE;
new Handle:cvarpluginstatus	= INVALID_HANDLE;
new Handle:cvarteamdomtime	= INVALID_HANDLE;
new Handle:cvarlifeteamSwCost = INVALID_HANDLE;


new ak47;
new aug;
new awp;
new deagle;
new elite;
new famas;
new fiveseven;
new flashbang;
new g3sg1;
new galil;
new glock;
new hegrenade;
new knife;
new m249;
new m3;
new m4a1;
new mac10;
new mp5navy;
new p228;
new p90;
new scout;
new sg550;
new sg552;
new smokegrenade_projectile;
new tmp;
new ump45;
new usp;
new xm1014;
new ak47_cost;
new aug_cost;
new awp_cost;
new deagle_cost;
new elite_cost;
new famas_cost;
new fiveseven_cost;
new flashbang_cost;
new g3sg1_cost;
new galil_cost;
new glock_cost;
new hegrenade_cost;
new m249_cost;
new m3_cost;
new m4a1_cost;
new mac10_cost;
new mp5navy_cost;
new p228_cost;
new p90_cost;
new scout_cost;
new sg550_cost;
new sg552_cost;
new smokegrenade_cost;
new tmp_cost;
new ump45_cost;
new usp_cost;
new xm1014_cost;
new kevlar;
new kevlarhelmet;
new helmet_cost;
new defusekit;
new nvgoggles;

new bool:spawnfile_exist, bool: spawnlist_exist;
new LastSpawnT, LastSpawnCT;
new String:spawnlistfile[PLATFORM_MAX_PATH];
new RespawnCount[MAXPLAYERS+1];
new g_Account = -1;
new bool:PlayerisWaiting[MAXPLAYERS+1];
new KillCount[MAXPLAYERS+1][MAXPLAYERS+1];
new ATMaccount[MAXPLAYERS+3];
new DominationCount[MAXPLAYERS+1];
new DominationCompare[MAXPLAYERS+1];
new bool:latespawn;
new bool:AutomaticHealth[MAXPLAYERS+1] = false;
new WithdrawCount[MAXPLAYERS+1];
new HeadshotCount[MAXPLAYERS+1];
new LastPrimaryWeapon[MAXPLAYERS+1];
new LastSecondaryWeapon[MAXPLAYERS+1];
new LastEquipmentItem[MAXPLAYERS+1][7];
new bool:buymenucont[MAXPLAYERS+1];
new bool:buymenudisplay[MAXPLAYERS+1];
new bool:healthmenu[MAXPLAYERS+1];
new bool:cashreceived[MAXPLAYERS+1];
new WeaponKills[MAXPLAYERS+1][28];
new bool:TeamDomination[2];
new bool:DominationDmg[2];
new bool:TeamDomination_ModeChecked;
new TeamDomination_Mode;
new g_TimeLeft_T, g_TimeLeft_CT; 
new bool: bankrupt, bool: PlayerisProtected[MAXPLAYERS+1], bool: PlayerisSwapping[MAXPLAYERS+1];
new lastcheck_T, lastcheck_CT;
new PlayerItems[MAXPLAYERS+1][8][3];
new bool:firstjoin[MAXPLAYERS+1];
new ClientCredits[MAXPLAYERS+1];
new bool: PlayerHealthChecked[MAXPLAYERS+1], bool: NewItem[MAXPLAYERS+1];
new g_iHooks[MAXPLAYERS+1], g_offsCollisionGroup;

public Plugin:myinfo = 
{
	name = "Domination DM",
	author = "InstantDeath",
	description = "Domination Deathmatch",
	version = PLUGIN_VERSION,
	url = "http://www.xpgaming.net"
};

public OnPluginStart()
{
	LoadTranslations("dominationdm.phrases");
	
	CreateConVar("sm_dominationdm_version", PLUGIN_VERSION, "Domination Deathmatch Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	cvarpluginstatus = CreateConVar("sm_dominationdm_enable", "1", "Enable or disable this plugin", FCVAR_PLUGIN|FCVAR_REPLICATED|FCVAR_NOTIFY);
	cvarrespawncount = CreateConVar("dm_respawn_count", "10", "Number of times a player may respawn");
	cvarrespawntime = CreateConVar("dm_respawn_time", "5.0", "Delay in seconds before the player may respawn");
	//cvarspawnprotect = CreateConVar("dm_spawnprotect_time", "3.0", "time in seconds a player is protected");
	cvarheadshotbonus = CreateConVar("dm_headshotbonus", "250", "The ammount of cash that is awarded for a headshot kill");
	cvarextralifecost = CreateConVar("dm_extralifecost", "2000", "How much extra lives cost.");
	cvardomination = CreateConVar("dm_dominationreq", "3", "How many kills in a row it takes to have dominated a person");
	cvardominationcash = CreateConVar("dm_dominationcash", "1000", "How much cash is stolen by the attacker when they dominate a person");
	cvardominationcashbonus = CreateConVar("dm_dominationcash_bonus", "500", "How much cash is awarded to the attacker when they continue to dominate a person");
	cvarteamacct = CreateConVar("dm_default_teamcash", "5000", "The default ammount of money each team starts with in their ATM account");
	cvarmaxwithdraw = CreateConVar("dm_maxwithdrawal", "800", "The maximum amount of money allowed to be withdrawed from team account at a time.");
	cvarheadshotdom = CreateConVar("dm_headshotreq", "4", "How many headshot kills in a row before lives are rewarded.");
	cvarweapondomreq = CreateConVar("dm_weapondom_interval", "5", "The inteval for how many kills in a row with the same weapon is required for a weapon domination");
	cvarcustomspawn = CreateConVar("dm_customspawn", "1", "Whether custom spawning is on or not");
	cvarteamdomtime = CreateConVar("dm_teamdomination_time", "60", "How long a team domination will last");
	cvarlifeteamSwCost = CreateConVar("dm_teamswitch_lifecost", "1000", "How much a team switch and 5 lives cost.");
	RegAdminCmd("sm_dmweapon", Command_dmweapon, ADMFLAG_BAN, "[SM] Usage: sm_dmweapon <weaponname> <cash>");
	RegAdminCmd("sm_itemcost", Command_ItemCost, ADMFLAG_BAN, "[SM] Usage: sm_itemcost <item> <cost>");
	RegAdminCmd("sm_addspawn", Command_AddSpawn, ADMFLAG_RCON, "[SM] Usage: sm_addspawn <ct/t>");
	RegAdminCmd("sm_backpack", Command_BackpackInfo, ADMFLAG_BAN, "[SM] Usage: sm_backpack <userid>");
	RegConsoleCmd("buy_menu", Command_Buymenu);
	RegConsoleCmd("dm_rebuy", Command_Rebuy);
	RegConsoleCmd("dm_swap_primary", Command_SwapPrimary);
	RegConsoleCmd("dm_automenu", Command_AutoMenu);
	RegConsoleCmd("say", Command_Say);
	
	//RegConsoleCmd("testDom", Command_testDom, "test function");
	
	//hook required events
	HookEvent("player_death", OnPlayerDeath);
	HookEvent("player_death", BeforePlayerDeath, EventHookMode_Pre);
	HookEvent("player_hurt", OnPlayerHurt);
	HookEvent("round_freeze_end",RoundFreezeEndEvent);
	HookEvent("round_end", OnRoundEnd);
	HookEvent("item_pickup", OnItemPickup);
	HookEvent("player_spawn", OnPlayerSpawn);
	HookEvent("player_team", OnPlayerChangeTeam);
	HookEvent("weapon_fire", OnWeaponFire, EventHookMode_Pre);
	
	g_Account = FindSendPropOffs("CCSPlayer", "m_iAccount");
	
	if (g_Account == -1)
	{
		SetFailState("[SM] - Unable to start, cannot find necessary send prop offsets.");
		return;
	}
	
	g_offsCollisionGroup = FindSendPropOffs("CBaseEntity", "m_CollisionGroup");
	
	if (g_offsCollisionGroup == -1)
	{
		PrintToServer("PLUGIN ERROR: Failed to get the offset for CBaseEntity::m_CollisionGroup");
	}
	
	// default values for money recieved for killing enemy
	ak47 = 500;
	aug = 500;
	awp = 420;
	deagle = 1080;
	elite = 1160;
	famas = 500;
	fiveseven = 1250;
	flashbang = 1400;
	g3sg1 = 410;
	galil = 590;
	glock = 1160;
	hegrenade = 1560;
	knife = 2200;
	m249 = 380;
	m3 = 690;
	m4a1 = 500;
	mac10 = 1150;
	mp5navy = 880;
	p228 = 1350;
	p90 = 710;
	scout = 650;
	sg550 = 510;
	sg552 = 600;
	smokegrenade_projectile = 1400;
	tmp = 850;
	ump45 = 780;
	usp = 1260;
	xm1014 = 690;
	
	ak47_cost = 2500;
	aug_cost = 3500;
	awp_cost = 4750;
	deagle_cost = 650;
	elite_cost = 800;
	famas_cost = 2250;
	fiveseven_cost = 750;
	flashbang_cost = 200;
	g3sg1_cost = 5000;
	galil_cost = 2000;
	glock_cost = 400;
	hegrenade_cost = 300;
	m249_cost = 5750;
	m3_cost = 1700;
	m4a1_cost = 3100;
	mac10_cost = 1400;
	mp5navy_cost = 1500;
	p228_cost = 600;
	p90_cost = 2350;
	scout_cost = 2750;
	sg550_cost = 4200;
	sg552_cost = 3500;
	smokegrenade_cost = 300;
	tmp_cost = 1250;
	ump45_cost = 1700;
	usp_cost = 500;
	xm1014_cost = 3000;
	kevlar = 650;
	kevlarhelmet = 1000;
	helmet_cost = 300;
	defusekit = 200;
	nvgoggles = 1250;
	
	ServerCommand("mp_buytime 300");
	g_TimeLeft_T = GetConVarInt(cvarteamdomtime);
	g_TimeLeft_CT = GetConVarInt(cvarteamdomtime);
	
}

public OnMapStart()
{
	new String: Spawnlist[] = "configs/spawnlist.cfg";
	BuildPath(Path_SM,spawnlistfile,sizeof(spawnlistfile), Spawnlist);
	spawnfile = CreateKeyValues("Spawn Points");
	FileToKeyValues(spawnfile,spawnlistfile);
	if(!FileExists(spawnlistfile)) 
	{
		LogMessage("[SM] spawnlist.cfg not parsed...file doesnt exist!");
		SetFailState("[SM] spawnlist.cfg not parsed...file doesnt exist! Please install the plugin correctly...");
		spawnfile_exist = false;
	}
	else
	{
		spawnfile_exist = true;
	}
	KvRewind(spawnfile);
	
	ATMaccount[T_acct] = GetConVarInt(cvarteamacct);
	ATMaccount[CT_acct] = GetConVarInt(cvarteamacct);
	
	lastcheck_T = 0;
	lastcheck_CT = 0;
	
	
	decl String: CurrentMap[64];
	new bool:status;
	GetCurrentMap(CurrentMap, sizeof(CurrentMap));
	status = KvJumpToKey(spawnfile, CurrentMap, false);
	if(status == false)
	{
		spawnlist_exist = false;
		LogError("Couldn't find Map spawns in Spawnlist!");
	}
	else
	{
		spawnlist_exist = true;
		LastSpawnT = 0;
		LastSpawnCT = 0;
		KvRewind(spawnfile);
	}
	TeamDomination[0] = false;
	TeamDomination[1] = false;
	bankrupt = false;
	lastcheck_T = 0;
	lastcheck_CT = 0;
	g_TimeLeft_T = GetConVarInt(cvarteamdomtime);
	g_TimeLeft_CT = GetConVarInt(cvarteamdomtime);
}

public OnMapEnd()
{
	KvRewind(spawnfile);
	KeyValuesToFile(spawnfile, spawnlistfile);
}

public OnPluginEnd()
{
	CloseHandle(spawnfile);
}

public OnGameFrame()
{
	
	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			if(PlayerisProtected[i] && IsPlayerAlive(i) && !IsFakeClient(i))
			{
				new Float: distance;
				new bool:IsValidSpawn = true;
				new Float:vec[3], Float:vec2[3];
				new playercount = GetClientCount(true), reqdistance = (-12*playercount)+860;
				
				//PrintHintText(i, "%t", "Player_Spawn");
				if(GetClientButtons(i) & IN_ATTACK)
				{					
					if(playercount <= 10)
						reqdistance = 740;
					
					for(new a = 1; a <= MaxClients; a++)
					{
						if(a != i && IsClientInGame(a) && IsClientInGame(i))
						{
							if(GetClientTeam(a) != GetClientTeam(i) && !PlayerisProtected[a])
							{
								GetClientAbsOrigin(i, vec);
								GetClientAbsOrigin(a, vec2);
								distance = GetVectorDistance(vec, vec2, false);
								
								if(distance < reqdistance)
								{
									IsValidSpawn = false;
								}
							}
						}
					}
					if(IsValidSpawn)
						PlayerProt(i);
					else
					{
						PrintHintText(i, "%t", "Invalid_Spawn");
					}
				}
				
				for(new b = 1; b <= MaxClients; b++)
				{
					if(b != i && IsClientInGame(b) && IsClientInGame(i))
					{
						GetClientAbsOrigin(i, vec);
						GetClientAbsOrigin(b, vec2);
						distance = GetVectorDistance(vec, vec2, false);
						
						if(distance < 100)
						{
							SetEntData(b, g_offsCollisionGroup, 2, 4, true);
							SetEntData(i, g_offsCollisionGroup, 2, 4, true);
						}
						else
							SetEntData(b, g_offsCollisionGroup, 5, 4, true);
					}
				}
			}
		}
	}
}

public Action:PlayerProtection(Handle:timer, any:client)
{
	PlayerisProtected[client] = true;
	PrintHintText(client, "%t", "Player_Spawn");
	return Plugin_Stop;
}

public Action:PreSpawn(Handle:timer, any:client)
{
	if(IsClientInGame(client))
	{
		//PrintToConsole(client, "[SM] Player tripped pre-spawn msg");
		//PlayerisProtected2[client] = true;
		if(PlayerisProtected[client] && IsPlayerAlive(client))
		{
			PrintHintText(client, "%t", "Player_Spawn");
		}
		else
		{
			return Plugin_Stop;
		}
	}
	
	return Plugin_Continue;
}

public Weapon_CanUse(client, weapon, dummy1, dummy2, dummy3, dummy4)
{
	new String: WeaponName[32];
	// block any weapon the player tries to pick up while being protected.
	if(PlayerisProtected[client])
	{
		return 0;
	}
	GetEdictClassname(weapon, WeaponName, sizeof(WeaponName));
	if(StrEqual(WeaponName, "weapon_ak47", false) && ak47_cost == -1)
	{
		return 0;
	}
	else if(StrEqual(WeaponName, "weapon_aug", false) && aug_cost == -1)
	{
		return 0;
	}
	else if(StrEqual(WeaponName, "weapon_awp", false) && awp_cost == -1)
	{
		return 0;
	}
	else if(StrEqual(WeaponName, "weapon_deagle", false) && deagle_cost == -1)
	{	
		return 0;
	}
	else if(StrEqual(WeaponName, "weapon_elite", false) && elite_cost == -1)
	{
		return 0;
	}
	else if(StrEqual(WeaponName, "weapon_famas", false) && famas_cost == -1)
	{
		return 0;
	}
	else if(StrEqual(WeaponName, "weapon_fiveseven", false) && fiveseven_cost == -1)
	{
		return 0;
	}
	else if(StrEqual(WeaponName, "weapon_flashbang", false) && flashbang_cost == -1)
	{
		return 0;
	}
	else if(StrEqual(WeaponName, "weapon_g3sg1", false) && g3sg1_cost == -1)
	{
		return 0;
	}
	else if(StrEqual(WeaponName, "weapon_galil", false) && galil_cost == -1)
	{
		return 0;
	}
	else if(StrEqual(WeaponName, "weapon_glock", false) && glock_cost == -1)
	{
		return 0;
	}
	else if(StrEqual(WeaponName, "weapon_hegrenade", false) && hegrenade_cost == -1)
	{
		return 0;
	}
	else if(StrEqual(WeaponName, "weapon_m249", false) && m249_cost == -1)
	{
		return 0;
	}
	else if(StrEqual(WeaponName, "weapon_m3", false) && m3_cost == -1)
	{
		return 0;
	}
	else if(StrEqual(WeaponName, "weapon_m4a1", false) && m4a1_cost == -1)
	{
		return 0;
	}
	else if(StrEqual(WeaponName, "weapon_mac10", false) && mac10_cost == -1)
	{
		return 0;
	}
	else if(StrEqual(WeaponName, "weapon_mp5navy", false) && mp5navy_cost == -1)
	{
		return 0;
	}
	else if(StrEqual(WeaponName, "weapon_p228", false) && p228_cost == -1)
	{
		return 0;
	}
	else if(StrEqual(WeaponName, "weapon_p90", false) && p90_cost == -1)
	{
		return 0;
	}
	else if(StrEqual(WeaponName, "weapon_scout", false) && scout_cost == -1)
	{
		return 0;
	}
	else if(StrEqual(WeaponName, "weapon_sg550", false) && sg550_cost == -1)
	{
		return 0;
	}
	else if(StrEqual(WeaponName, "weapon_sg552", false) && sg552_cost == -1)
	{
		return 0;
	}
	else if(StrEqual(WeaponName, "weapon_smokegrenade", false) && smokegrenade_cost == -1)
	{
		return 0;
	}
	else if(StrEqual(WeaponName, "weapon_tmp", false) && tmp_cost == -1)
	{
		return 0;
	}
	else if(StrEqual(WeaponName, "weapon_ump45", false) && ump45_cost == -1)
	{
		return 0;
	}
	else if(StrEqual(WeaponName, "weapon_usp", false) && usp_cost == -1)
	{
		return 0;
	}
	else if(StrEqual(WeaponName, "weapon_xm1014", false) && xm1014_cost == -1)
	{
		return 0;
	}
	
	return Hacks_Continue;
}

public Action:OnWeaponFire(Handle:event,const String:name[],bool:dontBroadcast)
{
	new userid = GetEventInt(event, "userid");
	new client = GetClientOfUserId(userid);
	new weaponid;
	if(PlayerisProtected[client])
	{
		weaponid = GetPlayerWeaponSlot(client, 0);
		if(weaponid != -1)
		{
			ClientCommand(client, "drop");
			//RemovePlayerItem(client, weaponid);
		}
		weaponid = GetPlayerWeaponSlot(client, 1);
		if(weaponid != -1)
		{
			ClientCommand(client, "drop");
			//RemovePlayerItem(client, weaponid);
		}
		
		weaponid = GetPlayerWeaponSlot(client, 3);
		if(weaponid != -1)
		{
			RemovePlayerItem(client, weaponid);
		}
	}
}

public Action:OnItemPickup(Handle:event,const String:name[],bool:dontBroadcast)
{
	new userid = GetEventInt(event, "userid");
	new client = GetClientOfUserId(userid);
	new weaponid;
	if(PlayerisProtected[client])
	{
		weaponid = GetPlayerWeaponSlot(client, 0);
		if(weaponid != -1)
		{
			ClientCommand(client, "drop");
			//RemovePlayerItem(client, weaponid);
		}
		weaponid = GetPlayerWeaponSlot(client, 1);
		if(weaponid != -1)
		{
			ClientCommand(client, "drop");
			//RemovePlayerItem(client, weaponid);
		}
		
		weaponid = GetPlayerWeaponSlot(client, 3);
		if(weaponid != -1)
		{
			RemovePlayerItem(client, weaponid);
		}
	}
}

public Action:BeforePlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	// get players entity ids
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	new String:weaponname[32];
	
	if(IsClientInGame(victim))
	{
		if(PlayerItems[victim][0][0] != -1)
		{
			GetWeaponByID(PlayerItems[victim][0][0], weaponname, sizeof(weaponname));
			GivePlayerItem(victim, weaponname);
			PlayerItems[victim][0][0] = -1;
			PlayerItems[victim][0][1] = -1;
			PlayerItems[victim][0][2] = -1;
			
			//PrintToConsole(client, "Weapon: %s", weaponname);
		}
		if(PlayerItems[victim][7][0] != -1)
		{
			GetWeaponByID(PlayerItems[victim][7][0], weaponname, sizeof(weaponname));
			GivePlayerItem(victim, weaponname);
			
			PlayerItems[victim][7][0] = -1;
			PlayerItems[victim][7][1] = -1;
			PlayerItems[victim][7][2] = -1;
		}
		PlayerisSwapping[victim] = false;
	}
	return Plugin_Continue;
}

public Action:Command_AutoMenu(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: dm_automenu <on/off>");
		return Plugin_Handled;
	}
	new String:setting[32];
	GetCmdArg(1, setting,sizeof(setting));
	if(StrEqual(setting, "on", false))
		buymenucont[client] = true;
	else
	buymenucont[client] = false;
	
	return Plugin_Handled;
}

public Action:Command_BackpackInfo(client, args)
{
	new userid, target;
	new String:Slot1[32], String:Slot2[32], String:Slot3[32], String:Slot4[32], String:Slot5[32], String:Slot6[32], String:Slot7[32], String:Slot8[32];
	new String: name[64];
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_backpack <#userid>");
		return Plugin_Handled;
	}
	new String:tmpu[32];
	GetCmdArg(1, tmpu,sizeof(tmpu));
	userid = StringToInt(tmpu);
	target = GetClientOfUserId(userid);
	GetClientName(target, name, sizeof(name));
	GetWeaponByID(PlayerItems[target][0][0], Slot1, sizeof(Slot1));
	GetWeaponByID(PlayerItems[target][1][0], Slot2, sizeof(Slot2));
	GetWeaponByID(PlayerItems[target][2][0], Slot3, sizeof(Slot3));
	GetWeaponByID(PlayerItems[target][3][0], Slot4, sizeof(Slot4));
	GetWeaponByID(PlayerItems[target][4][0], Slot5, sizeof(Slot5));
	GetWeaponByID(PlayerItems[target][5][0], Slot6, sizeof(Slot6));
	GetWeaponByID(PlayerItems[target][6][0], Slot7, sizeof(Slot7));
	GetWeaponByID(PlayerItems[target][7][0], Slot8, sizeof(Slot8));
	PrintToConsole(client, "In %s's backpack:", name);
	PrintToConsole(client, "	Slot 1: %s", Slot1);
	PrintToConsole(client, "	Slot 2: %s", Slot2);
	PrintToConsole(client, "	Slot 3: %s", Slot3);
	PrintToConsole(client, "	Slot 4: %s", Slot4);
	PrintToConsole(client, "	Slot 5: %s", Slot5);
	PrintToConsole(client, "	Slot 6: %s", Slot6);
	PrintToConsole(client, "	Slot 7: %s", Slot7);
	PrintToConsole(client, "	Slot 8: %s", Slot8);
	return Plugin_Handled;
}

//transfers weapon to and from backpack

public Action:TimedWeaponSwap(Handle: timer, any:client)
{
	
	new String:weaponname[32];
	new weaponid;
	//PrintToConsole(client, "[SM] Ran TimedWeaponSwap");
	weaponid = GetPlayerWeaponSlot(client, 0);
	if(PlayerItems[client][7][0] != -1)
	{
		//PrintToConsole(client, "[SM] backpack is not empty");
		GetWeaponByID(PlayerItems[client][7][0], weaponname, sizeof(weaponname));
		GivePlayerItem(client, weaponname);
		//PrintToConsole(client, "Weapon: %s", weaponname);
		weaponid = GetPlayerWeaponSlot(client, 0);
		SetPrimaryAmmo(client, weaponid, PlayerItems[client][7][1]);
		GetEdictClassname(weaponid, weaponname, sizeof(weaponname));
		SetWeaponAmmo(client, GetWeaponAmmoOffset(weaponname), PlayerItems[client][7][2]);
		
		PlayerItems[client][7][0] = PlayerItems[client][0][0];
		PlayerItems[client][7][1] = PlayerItems[client][0][1];
		PlayerItems[client][7][2] = PlayerItems[client][0][2];
		PlayerItems[client][0][0] = -1;
		PlayerItems[client][0][1] = -1;
		PlayerItems[client][0][2] = -1;
		
		PlayerisSwapping[client] = false;
	}
	else if(PlayerItems[client][7][0] == -1)
	{
		if(PlayerItems[client][0][0] != -1)
		{
			PlayerItems[client][7][0] = PlayerItems[client][0][0];
			PlayerItems[client][7][1] = PlayerItems[client][0][1];
			PlayerItems[client][7][2] = PlayerItems[client][0][2];
			PlayerItems[client][0][0] = -1;
			PlayerItems[client][0][1] = -1;
			PlayerItems[client][0][2] = -1;
			//PrintToConsole(client, "[SM] backpack is not empty");
			GetWeaponByID(PlayerItems[client][7][0], weaponname, sizeof(weaponname));
			GivePlayerItem(client, weaponname);
			//PrintToConsole(client, "Weapon: %s", weaponname);
			weaponid = GetPlayerWeaponSlot(client, 0);
			SetPrimaryAmmo(client, weaponid, PlayerItems[client][7][1]);
			GetEdictClassname(weaponid, weaponname, sizeof(weaponname));
			SetWeaponAmmo(client, GetWeaponAmmoOffset(weaponname), PlayerItems[client][7][2]);
			PlayerItems[client][7][0] = -1;
			PlayerItems[client][7][1] = -1;
			PlayerItems[client][7][2] = -1;
		}
	}
	
	return Plugin_Stop;
}

public Action:Command_SwapPrimary(client, args)
{
	new weaponid, clip1, clip2;
	new String: weaponname[32];
	new colors[3];
	if(PlayerisSwapping[client] && PlayerisProtected[client])
		return Plugin_Handled;
	
	weaponid = GetPlayerWeaponSlot(client, 0);
	if(weaponid != -1)
	{
		colors[0] = 225;
		colors[1] = 10;
		colors[2] = 0;
		
		if(PlayerItems[client][7][0] != -1)
		{
			clip1 = GetPrimaryAmmo(client, weaponid);
			GetEdictClassname(weaponid, weaponname, sizeof(weaponname));
			clip2 = GetWeaponAmmo(client, GetWeaponAmmoOffset(weaponname));
			//PrintToConsole(client, "Got Primary Ammo: %d", clip1);
			//PrintToConsole(client, "Got Secondary Ammo: %d", clip2);
			
			
			//PrintToConsole(client, "Weapon: %s", weaponname);
			RemovePlayerItem(client, weaponid);
			weaponid = GetWeaponidByName(weaponname);
			PlayerItems[client][0][0] = weaponid;
			PlayerItems[client][0][1] = clip1;
			PlayerItems[client][0][2] = clip2;
			SendDialogToOne(client, colors, "%t", "Swap_Primary");
			PlayerisSwapping[client] = true;
			CreateTimer(1.1,TimedWeaponSwap, client,TIMER_FLAG_NO_MAPCHANGE);
			weaponid = GetPlayerWeaponSlot(client, 1);
			if(weaponid != -1)
			{
				ClientCommand(client, "slot2");
			}
			else 
			{
				ClientCommand(client, "slot3");
			}
		}
		//PrintToConsole(client, "weapon Entity index: %d", weaponid);
		if(PlayerItems[client][7][0] == -1)
		{	
			if(PlayerItems[client][0][0] == -1)
			{
				clip1 = GetPrimaryAmmo(client, weaponid);
				GetEdictClassname(weaponid, weaponname, sizeof(weaponname));
				clip2 = GetWeaponAmmo(client, GetWeaponAmmoOffset(weaponname));
				//PrintToConsole(client, "Got Primary Ammo: %d", clip1);
				//PrintToConsole(client, "Got Secondary Ammo: %d", clip2);
				
				
				//PrintToConsole(client, "Weapon: %s", weaponname);
				RemovePlayerItem(client, weaponid);
				weaponid = GetWeaponidByName(weaponname);
				PlayerItems[client][7][0] = weaponid;
				PlayerItems[client][7][1] = clip1;
				PlayerItems[client][7][2] = clip2;
				SendDialogToOne(client, colors, "%t", "putin_backpack");
				PlayerisSwapping[client] = false;
				
				weaponid = GetPlayerWeaponSlot(client, 1);
				if(weaponid != -1)
				{
					ClientCommand(client, "slot2");
				}
				else
				{
					ClientCommand(client, "slot3");
				}
			}	
		}
	}
	else if(PlayerItems[client][7][0] != -1)
	{
		PlayerisSwapping[client] = false;
		GetWeaponByID(PlayerItems[client][7][0], weaponname, sizeof(weaponname));
		GivePlayerItem(client, weaponname);
		//PrintToConsole(client, "Weapon: %s", weaponname);
		weaponid = GetPlayerWeaponSlot(client, 0);
		SetPrimaryAmmo(client, weaponid, PlayerItems[client][7][1]);
		GetEdictClassname(weaponid, weaponname, sizeof(weaponname));
		SetWeaponAmmo(client, GetWeaponAmmoOffset(weaponname), PlayerItems[client][7][2]);
		PlayerItems[client][7][0] = -1;
		PlayerItems[client][7][1] = -1;
		PlayerItems[client][7][2] = -1;
	}
	
	return Plugin_Handled;
}


public Action:Command_Buymenu(client, args)
{
	new team = GetClientTeam(client);
	if(!GetConVarBool(cvarpluginstatus))
	{
		PrintToChat(client, "[SM] %t", "DDM_disabled");
		return Plugin_Handled;
	}
	if(team == TEAM_CT || team == TEAM_T)
	{
		BuyMenu_control(client, args);
	}
	return Plugin_Handled;
}

public Action:Command_Rebuy(client, args)
{
	new team = GetClientTeam(client);
	if(!GetConVarBool(cvarpluginstatus))
	{
		PrintToChat(client, "[SM] %t", "DDM_disabled");
		return Plugin_Handled;
	}
	if(team == TEAM_CT || team == TEAM_T)
	{
		RebuyPrimary(client, LastPrimaryWeapon[client]);
		RebuySecondary(client, LastSecondaryWeapon[client]);
		RebuyEquip(client);
	}
	return Plugin_Handled;
}

public bool:IsWeaponRestricted(String: WeaponName[])
{	
	if(StrEqual(WeaponName, "weapon_ak47", false) && ak47_cost == -1)
	{
		return true;
	}
	else if(StrEqual(WeaponName, "weapon_aug", false) && aug_cost == -1)
	{
		return true;
	}
	else if(StrEqual(WeaponName, "weapon_awp", false) && awp_cost == -1)
	{
		return true;
	}
	else if(StrEqual(WeaponName, "weapon_deagle", false) && deagle_cost == -1)
	{	
		return true;
	}
	else if(StrEqual(WeaponName, "weapon_elite", false) && elite_cost == -1)
	{
		return true;
	}
	else if(StrEqual(WeaponName, "weapon_famas", false) && famas_cost == -1)
	{
		return true;
	}
	else if(StrEqual(WeaponName, "weapon_fiveseven", false) && fiveseven_cost == -1)
	{
		return true;
	}
	else if(StrEqual(WeaponName, "weapon_flashbang", false) && flashbang_cost == -1)
	{
		return true;
	}
	else if(StrEqual(WeaponName, "weapon_g3sg1", false) && g3sg1_cost == -1)
	{
		return true;
	}
	else if(StrEqual(WeaponName, "weapon_galil", false) && galil_cost == -1)
	{
		return true;
	}
	else if(StrEqual(WeaponName, "weapon_glock", false) && glock_cost == -1)
	{
		return true;
	}
	else if(StrEqual(WeaponName, "weapon_hegrenade", false) && hegrenade_cost == -1)
	{
		return true;
	}
	else if(StrEqual(WeaponName, "weapon_m249", false) && m249_cost == -1)
	{
		return true;
	}
	else if(StrEqual(WeaponName, "weapon_m3", false) && m3_cost == -1)
	{
		return true;
	}
	else if(StrEqual(WeaponName, "weapon_m4a1", false) && m4a1_cost == -1)
	{
		return true;
	}
	else if(StrEqual(WeaponName, "weapon_mac10", false) && mac10_cost == -1)
	{
		return true;
	}
	else if(StrEqual(WeaponName, "weapon_mp5navy", false) && mp5navy_cost == -1)
	{
		return true;
	}
	else if(StrEqual(WeaponName, "weapon_p228", false) && p228_cost == -1)
	{
		return true;
	}
	else if(StrEqual(WeaponName, "weapon_p90", false) && p90_cost == -1)
	{
		return true;
	}
	else if(StrEqual(WeaponName, "weapon_scout", false) && scout_cost == -1)
	{
		return true;
	}
	else if(StrEqual(WeaponName, "weapon_sg550", false) && sg550_cost == -1)
	{
		return true;
	}
	else if(StrEqual(WeaponName, "weapon_sg552", false) && sg552_cost == -1)
	{
		return true;
	}
	else if(StrEqual(WeaponName, "weapon_smokegrenade", false) && smokegrenade_cost == -1)
	{
		return true;
	}
	else if(StrEqual(WeaponName, "weapon_tmp", false) && tmp_cost == -1)
	{
		return true;
	}
	else if(StrEqual(WeaponName, "weapon_ump45", false) && ump45_cost == -1)
	{
		return true;
	}
	else if(StrEqual(WeaponName, "weapon_usp", false) && usp_cost == -1)
	{
		return true;
	}
	else if(StrEqual(WeaponName, "weapon_xm1014", false) && xm1014_cost == -1)
	{
		return true;
	}
	
	return false;
}
public FindWeaponReward(String: weaponName[])
{
	//return the cash that is awarded for that specific weapon
	if(StrEqual(weaponName, "ak47", false))
	{
		return ak47;
	}
	else if(StrEqual(weaponName, "aug", false))
	{
		return aug;
	}
	else if(StrEqual(weaponName, "awp", false))
	{
		return awp;
	}
	else if(StrEqual(weaponName, "deagle", false))
	{
		return deagle;
	}
	else if(StrEqual(weaponName, "elite", false))
	{
		return elite;
	}
	else if(StrEqual(weaponName, "famas", false))
	{
		return famas;
	}
	else if(StrEqual(weaponName, "fiveseven", false))
	{
		return fiveseven;
	}
	else if(StrEqual(weaponName, "flashbang", false))
	{
		return flashbang;
	}
	else if(StrEqual(weaponName, "g3sg1", false))
	{
		return g3sg1;
	}
	else if(StrEqual(weaponName, "galil", false))
	{
		return galil;
	}
	else if(StrEqual(weaponName, "glock", false))
	{
		return glock;
	}
	else if(StrEqual(weaponName, "hegrenade", false))
	{
		return hegrenade;
	}
	else if(StrEqual(weaponName, "knife", false))
	{
		return knife;
	}
	else if(StrEqual(weaponName, "m249", false))
	{
		return m249;
	}
	else if(StrEqual(weaponName, "m3", false))
	{
		return m3;
	}
	else if(StrEqual(weaponName, "m4a1", false))
	{
		return m4a1;
	}
	else if(StrEqual(weaponName, "mac10", false))
	{
		return mac10;
	}
	else if(StrEqual(weaponName, "mp5navy", false))
	{	
		return mp5navy;
	}
	else if(StrEqual(weaponName, "p228", false))
	{
		return p228;
	}
	else if(StrEqual(weaponName, "p90", false))
	{
		return p90;
	}
	else if(StrEqual(weaponName, "scout", false))
	{
		return scout;
	}
	else if(StrEqual(weaponName, "sg550", false))
	{
		return sg550;
	}
	else if(StrEqual(weaponName, "sg552", false))
	{
		return sg552;
	}
	else if(StrEqual(weaponName, "smokegrenade_projectile", false))
	{
		return smokegrenade_projectile;
	}
	else if(StrEqual(weaponName, "tmp", false))
	{
		return tmp;
	}
	else if(StrEqual(weaponName, "ump45", false))
	{
		return ump45;
	}
	else if(StrEqual(weaponName, "usp", false))
	{
		return usp;
	}
	else if(StrEqual(weaponName, "xm1014", false))
	{
		return xm1014;
	}
	return 0;
}

public SetWeaponReward(client, String: weaponName[], cash)
{
	//set the cash that is awarded for that specific weapon
	if(StrEqual(weaponName, "ak47", false))
	{
		ak47 = cash;
	}
	else if(StrEqual(weaponName, "aug", false))
	{
		aug = cash;
	}
	else if(StrEqual(weaponName, "awp", false))
	{
		awp = cash;
	}
	else if(StrEqual(weaponName, "deagle", false))
	{	
		deagle = cash;
	}
	else if(StrEqual(weaponName, "elite", false))
	{
		elite = cash;
	}
	else if(StrEqual(weaponName, "famas", false))
	{
		famas = cash;
	}
	else if(StrEqual(weaponName, "fiveseven", false))
	{
		fiveseven = cash;
	}
	else if(StrEqual(weaponName, "flashbang", false))
	{
		flashbang = cash;
	}
	else if(StrEqual(weaponName, "g3sg1", false))
	{
		g3sg1 = cash;
	}
	else if(StrEqual(weaponName, "galil", false))
	{
		galil = cash;
	}
	else if(StrEqual(weaponName, "glock", false))
	{
		glock = cash;
	}
	else if(StrEqual(weaponName, "hegrenade", false))
	{
		hegrenade = cash;
	}
	else if(StrEqual(weaponName, "knife", false))
	{
		knife = cash;
	}
	else if(StrEqual(weaponName, "m249", false))
	{
		m249 = cash;
	}
	else if(StrEqual(weaponName, "m3", false))
	{
		m3 = cash;
	}
	else if(StrEqual(weaponName, "m4a1", false))
	{
		m4a1 = cash;
	}
	else if(StrEqual(weaponName, "mac10", false))
	{
		mac10 = cash;
	}
	else if(StrEqual(weaponName, "mp5navy", false))
	{
		mp5navy = cash;
	}
	else if(StrEqual(weaponName, "p228", false))
	{
		p228 = cash;
	}
	else if(StrEqual(weaponName, "p90", false))
	{
		p90 = cash;
	}
	else if(StrEqual(weaponName, "scout", false))
	{
		scout = cash;
	}
	else if(StrEqual(weaponName, "sg550", false))
	{
		sg550 = cash;
	}
	else if(StrEqual(weaponName, "sg552", false))
	{
		sg552 = cash;
	}
	else if(StrEqual(weaponName, "smokegrenade_projectile", false))
	{
		smokegrenade_projectile = cash;
	}
	else if(StrEqual(weaponName, "tmp", false))
	{
		tmp = cash;
	}
	else if(StrEqual(weaponName, "ump45", false))
	{
		ump45 = cash;
	}
	else if(StrEqual(weaponName, "usp", false))
	{
		usp = cash;
	}
	else if(StrEqual(weaponName, "xm1014", false))
	{
		xm1014 = cash;
	}
	else
	ReplyToCommand(client, "[SM] Cannot find weapon for the specified weapon name.");
}

public SetItemCost(client, String: ItemName[], cost)
{
	//set the cost for that specific weapon
	if(StrEqual(ItemName, "ak47", false))
	{
		ak47_cost = cost;
	}
	else if(StrEqual(ItemName, "aug", false))
	{
		aug_cost = cost;
	}
	else if(StrEqual(ItemName, "awp", false))
	{
		awp_cost = cost;
	}
	else if(StrEqual(ItemName, "deagle", false))
	{	
		deagle_cost = cost;
	}
	else if(StrEqual(ItemName, "elite", false))
	{
		elite_cost = cost;
	}
	else if(StrEqual(ItemName, "famas", false))
	{
		famas_cost = cost;
	}
	else if(StrEqual(ItemName, "fiveseven", false))
	{
		fiveseven_cost = cost;
	}
	else if(StrEqual(ItemName, "flashbang", false))
	{
		flashbang_cost = cost;
	}
	else if(StrEqual(ItemName, "g3sg1", false))
	{
		g3sg1_cost = cost;
	}
	else if(StrEqual(ItemName, "galil", false))
	{
		galil_cost = cost;
	}
	else if(StrEqual(ItemName, "glock", false))
	{
		glock_cost = cost;
	}
	else if(StrEqual(ItemName, "hegrenade", false))
	{
		hegrenade_cost = cost;
	}
	else if(StrEqual(ItemName, "m249", false))
	{
		m249_cost = cost;
	}
	else if(StrEqual(ItemName, "m3", false))
	{
		m3_cost = cost;
	}
	else if(StrEqual(ItemName, "m4a1", false))
	{
		m4a1_cost = cost;
	}
	else if(StrEqual(ItemName, "mac10", false))
	{
		mac10_cost = cost;
	}
	else if(StrEqual(ItemName, "mp5navy", false))
	{
		mp5navy_cost = cost;
	}
	else if(StrEqual(ItemName, "p228", false))
	{
		p228_cost = cost;
	}
	else if(StrEqual(ItemName, "p90", false))
	{
		p90_cost = cost;
	}
	else if(StrEqual(ItemName, "scout", false))
	{
		scout_cost = cost;
	}
	else if(StrEqual(ItemName, "sg550", false))
	{
		sg550_cost = cost;
	}
	else if(StrEqual(ItemName, "sg552", false))
	{
		sg552_cost = cost;
	}
	else if(StrEqual(ItemName, "smokegrenade_projectile", false))
	{
		smokegrenade_cost = cost;
	}
	else if(StrEqual(ItemName, "tmp", false))
	{
		tmp_cost = cost;
	}
	else if(StrEqual(ItemName, "ump45", false))
	{
		ump45_cost = cost;
	}
	else if(StrEqual(ItemName, "usp", false))
	{
		usp_cost = cost;
	}
	else if(StrEqual(ItemName, "xm1014", false))
	{
		xm1014_cost = cost;
	}
	else if(StrEqual(ItemName, "kevlar", false))
	{
		kevlar = cost;
	}
	else if(StrEqual(ItemName, "helmet", false))
	{
		helmet_cost = cost;
	}
	else if(StrEqual(ItemName, "kevlarhelmet", false))
	{
		kevlarhelmet = cost;
	}
	else if(StrEqual(ItemName, "defusekit", false))
	{
		defusekit = cost;
	}
	else if(StrEqual(ItemName, "nvgoggles", false))
	{
		nvgoggles = cost;
	}
	
	else
	ReplyToCommand(client, "[SM] Cannot find weapon for the specified weapon name.");
}

public AddWeaponKill(client, String:Weapon[])
{
	new weaponid;
	if(StrEqual(Weapon, "ak47", false))
	{
		WeaponKills[client][0] = WeaponKills[client][0] + 1;
		weaponid = 0;
	}
	else if(StrEqual(Weapon, "aug", false))
	{
		WeaponKills[client][1] = WeaponKills[client][1] + 1;
		weaponid = 1;
	}
	else if(StrEqual(Weapon, "awp", false))
	{
		WeaponKills[client][2] = WeaponKills[client][2] + 1;
		weaponid = 2;
	}
	else if(StrEqual(Weapon, "deagle", false))
	{	
		WeaponKills[client][3] = WeaponKills[client][3] + 1;
		weaponid = 3;
	}
	else if(StrEqual(Weapon, "elite", false))
	{
		WeaponKills[client][4] = WeaponKills[client][4] + 1;
		weaponid = 4;
	}
	else if(StrEqual(Weapon, "famas", false))
	{
		WeaponKills[client][5] = WeaponKills[client][5] + 1;
		weaponid = 5;
	}
	else if(StrEqual(Weapon, "fiveseven", false))
	{
		WeaponKills[client][6] = WeaponKills[client][6] + 1;
		weaponid = 6;
	}
	else if(StrEqual(Weapon, "flashbang", false))
	{
		WeaponKills[client][7] = WeaponKills[client][7] + 1;
		weaponid = 7;
	}
	else if(StrEqual(Weapon, "g3sg1", false))
	{
		WeaponKills[client][8] = WeaponKills[client][8] + 1;
		weaponid = 8;
	}
	else if(StrEqual(Weapon, "galil", false))
	{
		WeaponKills[client][9] = WeaponKills[client][9] + 1;
		weaponid = 9;
	}
	else if(StrEqual(Weapon, "glock", false))
	{
		WeaponKills[client][10] = WeaponKills[client][10] + 1;
		weaponid = 10;
	}
	else if(StrEqual(Weapon, "hegrenade", false))
	{
		WeaponKills[client][11] = WeaponKills[client][11] + 1;
		weaponid = 11;
	}
	else if(StrEqual(Weapon, "knife", false))
	{
		WeaponKills[client][12] = WeaponKills[client][12] + 1;
		weaponid = 12;
	}
	else if(StrEqual(Weapon, "m249", false))
	{
		WeaponKills[client][13] = WeaponKills[client][13] + 1;
		weaponid = 13;
	}
	else if(StrEqual(Weapon, "m3", false))
	{
		WeaponKills[client][14] = WeaponKills[client][14] + 1;
		weaponid = 14;
	}
	else if(StrEqual(Weapon, "m4a1", false))
	{
		WeaponKills[client][15] = WeaponKills[client][15] + 1;
		weaponid = 15;
	}
	else if(StrEqual(Weapon, "mac10", false))
	{
		WeaponKills[client][16] = WeaponKills[client][16] + 1;
		weaponid = 16;
	}
	else if(StrEqual(Weapon, "mp5navy", false))
	{
		WeaponKills[client][17] = WeaponKills[client][17] + 1;
		weaponid = 17;
	}
	else if(StrEqual(Weapon, "p228", false))
	{
		WeaponKills[client][18] = WeaponKills[client][18] + 1;
		weaponid = 18;
	}
	else if(StrEqual(Weapon, "p90", false))
	{
		WeaponKills[client][19] = WeaponKills[client][19] + 1;
		weaponid = 19;
	}
	else if(StrEqual(Weapon, "scout", false))
	{
		WeaponKills[client][20] = WeaponKills[client][20] + 1;
		weaponid = 20;
	}
	else if(StrEqual(Weapon, "sg550", false))
	{
		WeaponKills[client][21] = WeaponKills[client][21] + 1;
		weaponid = 21;
	}
	else if(StrEqual(Weapon, "sg552", false))
	{
		WeaponKills[client][22] = WeaponKills[client][22] + 1;
		weaponid = 22;
	}
	else if(StrEqual(Weapon, "smokegrenade_projectile", false))
	{
		WeaponKills[client][23] = WeaponKills[client][23] + 1;
		weaponid = 23;
	}
	else if(StrEqual(Weapon, "tmp", false))
	{
		WeaponKills[client][24] = WeaponKills[client][24] + 1;
		weaponid = 24;
	}
	else if(StrEqual(Weapon, "ump45", false))
	{
		WeaponKills[client][25] = WeaponKills[client][25] + 1;
		weaponid = 25;
	}
	else if(StrEqual(Weapon, "usp", false))
	{
		WeaponKills[client][26] = WeaponKills[client][26] + 1;
		weaponid = 26;
	}
	else if(StrEqual(Weapon, "xm1014", false))
	{
		WeaponKills[client][27] = WeaponKills[client][27] + 1;
		weaponid = 27;
	}
	
	for(new i = 0; i < 28; i++)
	{
		if(i != weaponid && WeaponKills[client][i] > 0)
		{
			WeaponKills[client][i] = 0;
		}
	}
}

public GetWeaponidByName(String:Weapon[])
{
	if(StrEqual(Weapon, "weapon_ak47", false))
	{
		return 0;
	}
	else if(StrEqual(Weapon, "weapon_aug", false))
	{
		return 1;
	}
	else if(StrEqual(Weapon, "weapon_awp", false))
	{
		return 2;
	}
	else if(StrEqual(Weapon, "weapon_deagle", false))
	{	
		return 3;
	}
	else if(StrEqual(Weapon, "weapon_elite", false))
	{
		return 4;
	}
	else if(StrEqual(Weapon, "weapon_famas", false))
	{
		return 5;
	}
	else if(StrEqual(Weapon, "weapon_fiveseven", false))
	{
		return 6;
	}
	else if(StrEqual(Weapon, "weapon_flashbang", false))
	{
		return 7;
	}
	else if(StrEqual(Weapon, "weapon_g3sg1", false))
	{
		return 8;
	}
	else if(StrEqual(Weapon, "weapon_galil", false))
	{
		return 9;
	}
	else if(StrEqual(Weapon, "weapon_glock", false))
	{
		return 10;
	}
	else if(StrEqual(Weapon, "weapon_hegrenade", false))
	{
		return 11;
	}
	else if(StrEqual(Weapon, "weapon_knife", false))
	{
		return 12;
	}
	else if(StrEqual(Weapon, "weapon_m249", false))
	{
		return 13;
	}
	else if(StrEqual(Weapon, "weapon_m3", false))
	{
		return 14;
	}
	else if(StrEqual(Weapon, "weapon_m4a1", false))
	{
		return 15;
	}
	else if(StrEqual(Weapon, "weapon_mac10", false))
	{
		return 16;
	}
	else if(StrEqual(Weapon, "weapon_mp5navy", false))
	{
		return 17;
	}
	else if(StrEqual(Weapon, "weapon_p228", false))
	{
		return 18;
	}
	else if(StrEqual(Weapon, "weapon_p90", false))
	{
		return 19;
	}
	else if(StrEqual(Weapon, "weapon_scout", false))
	{
		return 20;
	}
	else if(StrEqual(Weapon, "weapon_sg550", false))
	{
		return 21;
	}
	else if(StrEqual(Weapon, "weapon_sg552", false))
	{
		return 22;
	}
	else if(StrEqual(Weapon, "weapon_smokegrenade", false))
	{
		return 23;
	}
	else if(StrEqual(Weapon, "weapon_tmp", false))
	{
		return 24;
	}
	else if(StrEqual(Weapon, "weapon_ump45", false))
	{
		return 25;
	}
	else if(StrEqual(Weapon, "weapon_usp", false))
	{
		return 26;
	}
	else if(StrEqual(Weapon, "weapon_xm1014", false))
	{
		return 27;
	}
	else if(StrEqual(Weapon, "weapon_c4", false))
	{
		return 28;
	}
	else
	return -1;
}

public GetWeaponByID(weaponid, String:WeaponName[], maxlen)
{
	if(weaponid == 0)
	{
		strcopy(WeaponName, maxlen, "weapon_ak47");
	}
	else if(weaponid == 1)
	{
		strcopy(WeaponName, maxlen, "weapon_aug");
	}
	else if(weaponid == 2)
	{
		strcopy(WeaponName, maxlen, "weapon_awp");
	}
	else if(weaponid == 3)
	{
		strcopy(WeaponName, maxlen, "weapon_deagle");
	}
	else if(weaponid == 4)
	{
		strcopy(WeaponName, maxlen, "weapon_elite");
	}
	else if(weaponid == 5)
	{
		strcopy(WeaponName, maxlen, "weapon_famas");
	}
	else if(weaponid == 6)
	{
		strcopy(WeaponName, maxlen, "weapon_fiveseven");
	}
	
	else if(weaponid == 7)
	{
		strcopy(WeaponName, maxlen, "weapon_flashbang");
	}
	else if(weaponid == 8)
	{
		strcopy(WeaponName, maxlen, "weapon_g3sg1");
	}
	else if(weaponid == 9)
	{
		strcopy(WeaponName, maxlen, "weapon_galil");
	}
	else if(weaponid == 10)
	{
		strcopy(WeaponName, maxlen, "weapon_glock");
	}
	else if(weaponid == 11)
	{
		strcopy(WeaponName, maxlen, "weapon_hegrenade");
	}
	else if(weaponid == 12)
	{
		strcopy(WeaponName, maxlen, "weapon_knife");
	}
	else if(weaponid == 13)
	{
		strcopy(WeaponName, maxlen, "weapon_m249");
	}
	else if(weaponid == 14)
	{
		strcopy(WeaponName, maxlen, "weapon_m3");
	}
	else if(weaponid == 15)
	{
		strcopy(WeaponName, maxlen, "weapon_m4a1");
	}
	else if(weaponid == 16)
	{
		strcopy(WeaponName, maxlen, "weapon_mac10");
	}
	else if(weaponid == 17)
	{
		strcopy(WeaponName, maxlen, "weapon_mp5navy");
	}
	else if(weaponid == 18)
	{
		strcopy(WeaponName, maxlen, "weapon_p228");
	}
	else if(weaponid == 19)
	{
		strcopy(WeaponName, maxlen, "weapon_p90");
	}
	else if(weaponid == 20)
	{
		strcopy(WeaponName, maxlen, "weapon_scout");
	}
	else if(weaponid == 21)
	{
		strcopy(WeaponName, maxlen, "weapon_sg550");
	}
	else if(weaponid == 22)
	{
		strcopy(WeaponName, maxlen, "weapon_sg552");
	}
	else if(weaponid == 23)
	{
		strcopy(WeaponName, maxlen, "weapon_smokegrenade");
	}
	else if(weaponid == 24)
	{
		strcopy(WeaponName, maxlen, "weapon_tmp");
	}
	else if(weaponid == 25)
	{
		strcopy(WeaponName, maxlen, "weapon_ump45");
	}
	else if(weaponid == 26)
	{
		strcopy(WeaponName, maxlen, "weapon_usp");
	}
	else if(weaponid == 27)
	{
		strcopy(WeaponName, maxlen, "weapon_xm1014");
	}
	else if(weaponid == 28)
	{
		strcopy(WeaponName, maxlen, "weapon_c4");
	}
}

public GetWeaponAmmoOffset(String:Weapon[])
{
	if(StrEqual(Weapon, "weapon_deagle", false))
	{
		return 1;
	}
	else if(StrEqual(Weapon, "weapon_ak47", false) || StrEqual(Weapon, "weapon_aug", false) || StrEqual(Weapon, "weapon_g3sg1", false) || StrEqual(Weapon, "weapon_scout", false))
	{
		return 2;
	}
	else if(StrEqual(Weapon, "weapon_famas", false) || StrEqual(Weapon, "weapon_galil", false) || StrEqual(Weapon, "weapon_m4a1", false) || StrEqual(Weapon, "weapon_sg550", false) || StrEqual(Weapon, "weapon_sg552", false))
	{
		return 3;
	}
	else if(StrEqual(Weapon, "weapon_m249", false))
	{
		return 4;
	}
	else if(StrEqual(Weapon, "weapon_awp", false))
	{
		return 5;
	}
	else if(StrEqual(Weapon, "weapon_elite", false) || StrEqual(Weapon, "weapon_glock", false) || StrEqual(Weapon, "weapon_mp5navy", false) || StrEqual(Weapon, "weapon_tmp", false))
	{
		return 6;
	}
	else if(StrEqual(Weapon, "weapon_xm1014", false) || StrEqual(Weapon, "weapon_m3", false))
	{
		return 7;
	}
	else if(StrEqual(Weapon, "weapon_mac10", false) || StrEqual(Weapon, "weapon_ump45", false) || StrEqual(Weapon, "weapon_usp", false))
	{
		return 8;
	}
	else if(StrEqual(Weapon, "weapon_p228", false))
	{
		return 9;
	}
	else if(StrEqual(Weapon, "weapon_fiveseven", false) || StrEqual(Weapon, "weapon_p90", false))
	{
		return 10;
	}
	else if(StrEqual(Weapon, "weapon_hegrenade", false))
	{
		return 11;
	}
	else if(StrEqual(Weapon, "weapon_flashbang", false))
	{
		return 12;
	}
	else if(StrEqual(Weapon, "weapon_smokegrenade", false))
	{
		return 13;
	}
	return -1;
}

public SetupBackPack(client)
{
	// begin weapon save for spawn protection
	new String: weaponname[32];
	new weaponid;
	
	/*new myweapons = FindSendPropInfo("CBaseCombatCharacter", "m_hMyWeapons");
	new grenades[3];
	grenades[0] = 0; // flashbang
	grenades[1] = 0; // hegrenade
	grenades[2] = 0; // smokegrenade
	
	decl i;
	decl String:buffer[64];
	
	for(i=0; i<188; i+=4) // See http://bailopan.net/table_dump.txt
	{
	new weap = GetEntDataEnt2(client, myweapons+ i);
	if (!IsValidEntity(weap))
		continue;
	
	GetEdictClassname(weap, buffer, sizeof(buffer));
	
	if (strcmp(buffer, "flashbang") == 0)
		grenades[0]++;
	if (strcmp(buffer, "hegrenade") == 0)
		grenades[1]++;
	if (strcmp(buffer, "smokegrenade") == 0)
		grenades[2]++;
	}*/
	weaponid = GetPlayerWeaponSlot(client, 0);
	if(weaponid != -1)
	{
		GetEdictClassname(weaponid, weaponname, sizeof(weaponname));
		RemovePlayerItem(client, weaponid);
		weaponid = GetWeaponidByName(weaponname);
		PlayerItems[client][0][0] = weaponid;
	}
	else if(PlayerItems[client][0][0] == -1)
	{
		PlayerItems[client][0][0] = -1;
		PlayerItems[client][0][1] = 0;
		PlayerItems[client][0][2] = 0;
	}
	
	weaponid = GetPlayerWeaponSlot(client, 1);
	if(weaponid != -1)
	{
		GetEdictClassname(weaponid, weaponname, sizeof(weaponname));
		RemovePlayerItem(client, weaponid);
		weaponid = GetWeaponidByName(weaponname);
		PlayerItems[client][1][0] = weaponid;
	}
	else if(PlayerItems[client][1][0] == -1)
	{
		PlayerItems[client][1][0] = -1;
		PlayerItems[client][1][1] = 0;
		PlayerItems[client][1][2] = 0;
	}
	
	weaponid = GetPlayerWeaponSlot(client, 2);
	if(weaponid != -1)
	{
		GetEdictClassname(weaponid, weaponname, sizeof(weaponname));
		RemovePlayerItem(client, weaponid);
		weaponid = GetWeaponidByName(weaponname);
		PlayerItems[client][2][0] = weaponid;
		PlayerItems[client][2][1] = 1;
	}
	else if(PlayerItems[client][2][0] == -1)
	{
		PlayerItems[client][2][0] = -1;
		PlayerItems[client][2][1] = 0;
	}
	
	if(GetPlayerWeaponSlot(client, 3) != -1)
	{
		
		if(GetWeaponAmmo(client, Slot_Flashbang)  != 0)
		{
			PlayerItems[client][3][0] = GetWeaponidByName("weapon_flashbang");
			PlayerItems[client][3][1] = GetWeaponAmmo(client, Slot_Flashbang);
		}
		else
		{
			PlayerItems[client][3][0] = -1;
			PlayerItems[client][3][1] = 0;
		}
		
		if(GetWeaponAmmo(client, Slot_HEgrenade) != 0)
		{
			PlayerItems[client][4][0] = GetWeaponidByName("weapon_hegrenade");
			PlayerItems[client][4][1] = GetWeaponAmmo(client, Slot_HEgrenade);
		}
		else
		{
			PlayerItems[client][4][0] = -1;
			PlayerItems[client][4][1] = 0;
		}
		
		if(GetWeaponAmmo(client, Slot_Smokegrenade) != 0)
		{
			PlayerItems[client][5][0] = GetWeaponidByName("weapon_smokegrenade");
			PlayerItems[client][5][1] = GetWeaponAmmo(client, Slot_Smokegrenade);
		}
		else
		{
			PlayerItems[client][5][0] = -1;
			PlayerItems[client][5][1] = 0;
		}
		do
		{
			weaponid = GetPlayerWeaponSlot(client, 3);
			if(weaponid != -1)
				RemovePlayerItem(client, weaponid);
		}while(weaponid != -1);
		
	}
	
	weaponid = GetPlayerWeaponSlot(client, 4);
	if(weaponid != -1)
	{
		SetEntityRenderFx(weaponid, RENDERFX_FADE_FAST);
	}
	CreateTimer(0.1, PlayerProtection, client,TIMER_FLAG_NO_MAPCHANGE);
	/*PrintToConsole(client, "[SM] Finished Saving player's weapons.");
	if(PlayerisProtected[client])
		PrintToConsole(client, "[SM] Player is now Protected");
	//else
	PrintToConsole(client, "[SM] Player is not Protected");*/
}

public UnloadBackPack(client)
{
	new String: weaponname[32];
	new i = 0, weaponid;
	if(PlayerItems[client][0][0] != -1)
	{
		GetWeaponByID(PlayerItems[client][0][0], weaponname, sizeof(weaponname));
		GivePlayerItem(client, weaponname);
		//PrintToConsole(client, "Weapon: %s", weaponname);
	}
	if(PlayerItems[client][1][0] != -1)
	{
		GetWeaponByID(PlayerItems[client][1][0], weaponname, sizeof(weaponname));
		GivePlayerItem(client, weaponname);
		//PrintToConsole(client, "Weapon: %s", weaponname);
	}
	else
	{
		new team = GetClientTeam(client);
		if(team == TEAM_CT)
			GivePlayerItem(client, "weapon_usp");
		else
		GivePlayerItem(client, "weapon_glock");
	}
		
	if(PlayerItems[client][2][0] != -1)
	{
		GetWeaponByID(PlayerItems[client][2][0], weaponname, sizeof(weaponname));
		GivePlayerItem(client, weaponname);
		//PrintToConsole(client, "Weapon: %s", weaponname);
	}
	else
		GivePlayerItem(client, "weapon_knife");
		
	if(PlayerItems[client][3][0] != -1)
	{
		GetWeaponByID(PlayerItems[client][3][0], weaponname, sizeof(weaponname));
		for(i = 0; i <= PlayerItems[client][3][1]; i++)
		{
			GivePlayerItem(client, weaponname);
		}
		//PrintToConsole(client, "Weapon: %s", weaponname);
	}
	if(PlayerItems[client][4][0] != -1)
	{
		GetWeaponByID(PlayerItems[client][4][0], weaponname, sizeof(weaponname));
		for(i = 0; i <= PlayerItems[client][4][1]; i++)
		{
			GivePlayerItem(client, weaponname);
		}
		//PrintToConsole(client, "Weapon: %s", weaponname);
	}
	if(PlayerItems[client][5][0] != -1)
	{
		GetWeaponByID(PlayerItems[client][5][0], weaponname, sizeof(weaponname));
		for(i = 0; i <= PlayerItems[client][5][1]; i++)
		{
			GivePlayerItem(client, weaponname);
		}
		//PrintToConsole(client, "Weapon: %s", weaponname);
	}
	
	weaponid = GetPlayerWeaponSlot(client, 4);
	if(weaponid != -1)
	{
		SetEntityRenderFx(weaponid, RENDERFX_NONE);
	}
	
	//PrintToConsole(client, "[SM] Finished giving player his weapons.");
	for(i = 0; i < 7; i++)
	{
		PlayerItems[client][i][0] = -1;
		PlayerItems[client][i][1] = 0;
	}
	
}

public GetMaxClientsOnTeam(teamid)
{
	new maxclients = GetMaxClients();
	new count = 0;
	
	for(new i = 1; i <= maxclients; i++)
	{
		if(IsClientInGame(i))
		{
			if(teamid == GetClientTeam(i))
				count++;
		}
	}
	return count;
}

public Action:TimedTeamDomination(Handle: timer, any:team)
{
	new color[3];
	if(team == TEAM_T && TeamDomination[0])
	{
		color[0] = 255;
		color[1] = 0;
		color[2] = 0;
		//SendDialogToAll(color, "%t", "TeamDomT_timeleft", g_TimeLeft_T);
		if(TeamDomination_Mode == 0)
			PrintHintTextToAll("\x03%t", "TeamDomT_timeleft_m0", g_TimeLeft_T);
		else if(TeamDomination_Mode == 1)
			PrintHintTextToAll("\x03%t", "TeamDomT_timeleft_m1", g_TimeLeft_T);
		else if(TeamDomination_Mode == 2)
			PrintHintTextToAll("\x03%t", "TeamDomT_timeleft_m2", g_TimeLeft_T);
		else if(TeamDomination_Mode == 3)
			PrintHintTextToAll("\x03%t", "TeamDomT_timeleft_m3", g_TimeLeft_T);
		g_TimeLeft_T = g_TimeLeft_T - 1;
	}
	else if(team == TEAM_CT && TeamDomination[1])
	{
		color[0] = 0;
		color[1] = 0;
		color[2] = 255;
		//SendDialogToAll(color, "%t", "TeamDomCT_timeleft", g_TimeLeft_CT);
		if(TeamDomination_Mode == 0)
			PrintHintTextToAll("%t", "TeamDomCT_timeleft_m0", g_TimeLeft_CT);
		else if(TeamDomination_Mode == 1)
			PrintHintTextToAll("%t", "TeamDomCT_timeleft_m1", g_TimeLeft_CT);
		else if(TeamDomination_Mode == 2)
			PrintHintTextToAll("%t", "TeamDomCT_timeleft_m2", g_TimeLeft_CT);
		else if(TeamDomination_Mode == 3)
			PrintHintTextToAll("%t", "TeamDomCT_timeleft_m3", g_TimeLeft_CT);
		g_TimeLeft_CT = g_TimeLeft_CT - 1;
	}
	
	if(g_TimeLeft_T <= 0 || g_TimeLeft_CT <= 0 || bankrupt)
	{
		TeamDomination[0] = false;
		TeamDomination[1] = false;
		TeamDomination_ModeChecked = false;
		bankrupt = false;
		lastcheck_T = 0;
		lastcheck_CT = 0;
		g_TimeLeft_T = GetConVarInt(cvarteamdomtime);
		g_TimeLeft_CT = GetConVarInt(cvarteamdomtime);
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

/*
* checks distance between selected spawn and all players
* if a player is at that spawn or a player near spawn,
* it will call SetSpawn again to get a new spawnpoint
*/
public Action:CheckSpawn(Handle:timer, any:client)
{
	new Float: distance;
	new bool:IsValidSpawn = true;
	new Float:vec[3], Float:vec2[3];
	
	for(new i = 1; i <= MaxClients; i++)
	{
		if(i != client && IsClientInGame(i) && IsClientInGame(client))
		{
			GetClientAbsOrigin(client, vec);
			GetClientAbsOrigin(i, vec2);
			distance = GetVectorDistance(vec, vec2, false);
			
			if(distance < 5)
			{
				IsValidSpawn = false;
			}
		}
	}
	if(!IsValidSpawn)
		SetSpawn(client);
	return Plugin_Stop;
}

/*
* Finds spawn point for correct map, and team
* calls CheckSpawn to check to see if spawnpoint is valid
*/
public SetSpawn(client)
{
	decl String: CurrentMap[64], String:SpawnID[3], String:Team[3];
	new ClientTeam = GetClientTeam(client);
	new lastspawnid;
	new Float:vec[3];
	new Float: defvalue[3] = {0.0, 0.0, 0.0};
	new bool: status, bool: status2;
	GetCurrentMap(CurrentMap, sizeof(CurrentMap));
	KvRewind(spawnfile);	
	if(ClientTeam == TEAM_T)
	{
		LastSpawnT = LastSpawnT +1;
		lastspawnid = LastSpawnT;
		Format(Team, sizeof(Team), "t");
	}
	else if(ClientTeam == TEAM_CT)
	{
		LastSpawnCT = LastSpawnCT +1;
		lastspawnid = LastSpawnCT;
		Format(Team, sizeof(Team), "ct");
	}
	
	status = KvJumpToKey(spawnfile, CurrentMap, false);
	if(status == false)
	{
		spawnlist_exist = false;
		LogError("Couldn't find Map spawns in Spawnlist!");
	}
	else
	spawnlist_exist = true;
	
	status2 = KvJumpToKey(spawnfile, Team, false);
	if(status2 == false)
	{
		LogError("Couldn't find specified team name!");
	}	
	
	IntToString(lastspawnid, SpawnID, sizeof(SpawnID));
	KvGetVector(spawnfile, SpawnID, vec, defvalue);
	if(vec[0] == defvalue[0] && vec[1] == defvalue[1] && vec[2] == defvalue[2])
	{
		lastspawnid = 1;
		IntToString(lastspawnid, SpawnID, sizeof(SpawnID));
		KvGetVector(spawnfile, SpawnID, vec, defvalue);
		if(ClientTeam == TEAM_T)
		{
			LastSpawnT = 0;
		}
		else if(ClientTeam == TEAM_CT)
		{
			LastSpawnCT = 0;
		}
	}
	
	if(vec[0] != defvalue[0] && vec[1] != defvalue[1] && vec[2] != defvalue[2])
	{
		TeleportEntity(client, vec, NULL_VECTOR, NULL_VECTOR);
		CreateTimer(0.4,CheckSpawn, client,TIMER_FLAG_NO_MAPCHANGE);
	}
	
}

public Action:Command_AddSpawn(client, args)
{
	decl String: CurrentMap[64], String:SpawnID[3], String:Team[3];
	new lastspawnid;
	new Float:vec[3];
	new bool: status, bool: status2;
	GetCurrentMap(CurrentMap, sizeof(CurrentMap));
	if(args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: dm_addspawn <ct/t>");
	}
	if(client != 0)
	{
		GetCmdArg(1, Team, sizeof(Team));
		if(StrEqual(Team, "t", false))
		{
			LastSpawnT = LastSpawnT +1;
			lastspawnid = LastSpawnT;
		}
		else if(StrEqual(Team, "ct", false))
		{
			LastSpawnCT = LastSpawnCT +1;
			lastspawnid = LastSpawnCT;
		}
		
		status = KvJumpToKey(spawnfile, CurrentMap, true);
		if(status == false)
		{
			LogError("Couldn't find Map spawns in Spawnlist!");
		}
		status = KvJumpToKey(spawnfile, Team, true);
		if(status2 == false)
		{
			LogError("Couldn't find specified team name!");
		}
		GetClientAbsOrigin(client, vec);
		IntToString(lastspawnid, SpawnID, sizeof(SpawnID));
		KvSetVector(spawnfile, SpawnID, vec);
		PrintToConsole(client, "[SM] %s spawn point #%s saved", Team, SpawnID);
		KvRewind(spawnfile);
	}
	return Plugin_Handled;
}

// gives money to the waiting dead who have no money

public CashForDead(client, amount)
{
	new ClientTeam = GetClientTeam(client);
	new maxclients = GetMaxClients();
	new teamid;
	
	if(ClientTeam == TEAM_T)
	{
		teamid = T_acct;
	}
	else if(ClientTeam == TEAM_CT)
	{
		teamid = CT_acct;
	}
	
	for (new i = 1; i <= maxclients; i++)
	{
		if(IsClientInGame(i))
		{
			if(!IsPlayerAlive(i) && PlayerisWaiting[i] && GetClientTeam(i) == ClientTeam)
			{
				if(ATMaccount[teamid] - amount >= GetConVarInt(cvarteamacct))
				{
					SetClientMoney(i, GetClientMoney(i) + amount);
					ATMaccount[teamid] = ATMaccount[teamid] - amount;
					PrintToChat(i, "[SM] %t", "cashfordead", amount);
				}
				
				if(GetClientMoney(i) > GetConVarInt(cvarextralifecost) + 800)
				{
					CreateTimer(1.0,PlayerRespawn, i,TIMER_FLAG_NO_MAPCHANGE);
					SetClientMoney(i, GetClientMoney(i) - GetConVarInt(cvarextralifecost));
					
				}
			}
		}
	}
}

public WeaponDominationCheck(attacker, victim, String:WeaponName[])
{
	new String: AttackerName[64], String: VictimName[64];
	GetClientName(attacker, AttackerName, sizeof(AttackerName));
	GetClientName(victim, VictimName, sizeof(VictimName));
	new ClientTeam = GetClientTeam(victim);
	new AttackerTeam = GetClientTeam(attacker);
	new teamid;
	new String:TeamName[64];
	new maxclients = GetMaxClients();
	new reward, total;
	
	if(ClientTeam == TEAM_T)
	{
		teamid = T_acct;
		Format(TeamName, sizeof(TeamName), "Terrorist team");
	}
	else if(ClientTeam == TEAM_CT)
	{
		teamid = CT_acct;
		Format(TeamName, sizeof(TeamName), "Counter-Terrorist team");
	}
	for(new i = 0; i < 28; i++)
	{
		if(WeaponKills[attacker][i] % GetConVarInt(cvarweapondomreq) == 0 && WeaponKills[attacker][i] != 0)
		{
			reward = FindWeaponReward(WeaponName);
			total = reward * WeaponKills[attacker][i];
			if(ATMaccount[teamid] > total && cashreceived[i] == false)
			{
				
				ATMaccount[attacker] = ATMaccount[attacker] + total;
				ATMaccount[teamid] = ATMaccount[teamid] - total;
				PrintToChatAll("[SM] %t", "weapon_domination", AttackerName, WeaponKills[attacker][i], WeaponName, total, TeamName);
				cashreceived[i] = true;
			}
			else if(ATMaccount[teamid] <= total)
			{
				ATMaccount[attacker] = ATMaccount[attacker] + ATMaccount[teamid];
				PrintHintTextToAll("[SM] %t", "weapon_domination", AttackerName, WeaponKills[attacker][i], WeaponName, ATMaccount[teamid], TeamName);
				ATMaccount[teamid] = GetConVarInt(cvarteamacct);
				PrintCenterTextAll("%t", "bankrupt_team", AttackerName, TeamName);
				for(new a = 1; a <= maxclients; a++)
				{
					if(IsClientInGame(a))
					{
						if(ClientTeam == GetClientTeam(a))
							PrintToChat(a, "%t", "teamcash_reset");
					}
				}
				CreateTimer(1.0,RespawnReward, AttackerTeam,TIMER_FLAG_NO_MAPCHANGE);
			}
		}
		else if(WeaponKills[attacker][i] > 0)
		{
			for(new b = 0; b < 28; b++)
			{
				if(WeaponKills[attacker][i] > 0 && WeaponKills[victim][b] > 0)
				{
					WeaponKills[victim][b] = 0;
					cashreceived[victim] = false;
				}
			}
		}
	}
}

public TeamDominationCheck()
{
	new maxclients = GetMaxClients();
	new teamid;
	new CT_count, T_count;
	for(new a = 1; a <= maxclients; a++)
	{
		for(new b = 1; b <= maxclients; b++)
		{
			if(IsClientInGame(a) && IsClientInGame(b))
			{
				teamid = GetClientTeam(b);
				if(teamid == TEAM_T)
				{
					if(KillCount[a][b] >= 5)
						T_count = T_count + 1;
				}
				else if(teamid == TEAM_CT)
				{
					if(KillCount[a][b] >= 5)
						CT_count = CT_count + 1;
				}
			}
		}
	}
	new clientsinteam;
	
	clientsinteam = GetMaxClientsOnTeam(TEAM_T);
	if(clientsinteam <= 6 && !TeamDomination[1])
	{
		if(T_count >= 3 && TeamDomination[0] == false)
		{
			if(!TeamDomination_ModeChecked)
			{
				TeamDomination_Mode = GetRandomInt(0, 3);
				TeamDomination_ModeChecked = true;
				if(TeamDomination_Mode == 1)
					DominationDmg[0] = true;
			}
			lastcheck_T = T_count;
			TeamDomination[0] = true;
			PrintToChatAll("\x05%t", "T_domination_m0");
			g_TimeLeft_T = GetConVarInt(cvarteamdomtime);
			CreateTimer(1.0,TimedTeamDomination, TEAM_T,TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		}
		else if(T_count % 3 == 0 && T_count != 3 && T_count != 0 && TeamDomination[0])
		{
			if(lastcheck_T < T_count)
			{
				lastcheck_T = T_count;
				g_TimeLeft_T = g_TimeLeft_T + GetConVarInt(cvarteamdomtime);
				PrintToChatAll("\x05%t", "T_domination_extend", GetConVarInt(cvarteamdomtime));
			}
			else if(lastcheck_T > T_count)
			{
				g_TimeLeft_T = 1;
			}				
		}
		else if(lastcheck_T > T_count && TeamDomination[0])
		{
			g_TimeLeft_T = 1;
		}
	}
	clientsinteam = GetMaxClientsOnTeam(TEAM_CT);
	if(clientsinteam <= 6 && !TeamDomination[0])
	{
		if(CT_count >= 3 && TeamDomination[1] == false)
		{
			if(!TeamDomination_ModeChecked)
			{
				TeamDomination_Mode = GetRandomInt(0, 3);
				TeamDomination_ModeChecked = true;
				if(TeamDomination_Mode == 1)
					DominationDmg[1] = true;
			}
			TeamDomination[1] = true;
			PrintToChatAll("\x06%t", "CT_domination");
			
			g_TimeLeft_CT = GetConVarInt(cvarteamdomtime);
			CreateTimer(1.0,TimedTeamDomination, TEAM_CT,TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		}
		else if(CT_count % 3 == 0 && CT_count != 3 && CT_count != 0 && TeamDomination[1])
		{
			if(lastcheck_CT < CT_count)
			{
				lastcheck_CT = CT_count;
				g_TimeLeft_CT = g_TimeLeft_CT + GetConVarInt(cvarteamdomtime);
				PrintToChatAll("\x06%t", "CT_domination_extend", GetConVarInt(cvarteamdomtime));
			}
			else if(lastcheck_CT > CT_count)
			{
				g_TimeLeft_CT = 1;
			}
		}
		else if(lastcheck_CT > CT_count && TeamDomination[1])
		{
			g_TimeLeft_CT = 1;
		}
	}
	
	clientsinteam = GetMaxClientsOnTeam(TEAM_T);
	if(clientsinteam > 6 && !TeamDomination[1])
	{
		if(T_count >= (clientsinteam/2) && TeamDomination[0] == false)
		{
			if(!TeamDomination_ModeChecked)
			{
				TeamDomination_Mode = GetRandomInt(0, 3);
				TeamDomination_ModeChecked = true;
				if(TeamDomination_Mode == 1)
					DominationDmg[0] = true;
			}
			TeamDomination[0] = true;
			PrintToChatAll("\x05%t", "T_domination");
			g_TimeLeft_T = GetConVarInt(cvarteamdomtime);
			CreateTimer(1.0,TimedTeamDomination, TEAM_T,TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		}
		else if(T_count % (clientsinteam/2) == 0 && T_count != (clientsinteam/2) && T_count != 0 && TeamDomination[0])
		{
			if(lastcheck_T < T_count)
			{
				g_TimeLeft_T = g_TimeLeft_T + GetConVarInt(cvarteamdomtime);
				PrintToChatAll("\x05%t", "T_domination_extend", GetConVarInt(cvarteamdomtime));
			}
		}
		else if(lastcheck_T > T_count && TeamDomination[0])
		{
			g_TimeLeft_T = 1;
		}
	}
	clientsinteam = GetMaxClientsOnTeam(TEAM_CT);
	if(clientsinteam > 6 && !TeamDomination[0])
	{
		if(CT_count >= (clientsinteam/2) && TeamDomination[1] == false)
		{
			if(!TeamDomination_ModeChecked)
			{
				TeamDomination_Mode = GetRandomInt(0, 3);
				TeamDomination_ModeChecked = true;
				if(TeamDomination_Mode == 1)
					DominationDmg[0] = true;
			}
			TeamDomination[1] = true;
			PrintToChatAll("\x06%t", "CT_domination");
			g_TimeLeft_CT = GetConVarInt(cvarteamdomtime);
			CreateTimer(1.0,TimedTeamDomination, TEAM_CT,TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		}
		else if(CT_count % (clientsinteam/2) == 0 && CT_count != (clientsinteam/2) && CT_count != 0 && TeamDomination[1])
		{
			if(lastcheck_CT < CT_count)
			{
				lastcheck_CT = CT_count;
				g_TimeLeft_CT = g_TimeLeft_CT + GetConVarInt(cvarteamdomtime);
				PrintToChatAll("\x06%t", "CT_domination_extend", GetConVarInt(cvarteamdomtime));
			}
		}
		else if(lastcheck_CT > CT_count && TeamDomination[1])
		{
			g_TimeLeft_CT = 1;
		}
	}
}

public ManageTeamDomination(attacker, victim, cash)
{
	new leftovers;
	new String: AttackerName[64], String:TeamName[64];
	new ClientTeam = GetClientTeam(victim);
	new maxclients = GetMaxClients();
	
	GetClientName(attacker, AttackerName, sizeof(AttackerName));
	if(TeamDomination[0]) // terrorists
	{
		if(ATMaccount[victim] > cash)
			ATMaccount[victim] = ATMaccount[victim] - cash;
		else if(ATMaccount[victim] <= cash)
		{
			leftovers = cash - ATMaccount[victim];
			if(ATMaccount[CT_acct] > leftovers)
			{
				ATMaccount[CT_acct] = ATMaccount[CT_acct] - leftovers;
				ATMaccount[victim] = 0;
			}
			else
			{
				Format(TeamName, sizeof(TeamName), "Counter-Terrorist team");
				PrintCenterTextAll("%t", "bankrupt_team", AttackerName, TeamName);
				bankrupt = true;
				for(new a = 1; a <= maxclients; a++)
				{
					if(IsClientInGame(a))
					{
						if(ClientTeam == GetClientTeam(a))
							PrintToChat(a, "%t", "teamcash_reset");
					}
				}
			}
		}
	}
	else if(TeamDomination[1]) // counter-terrorists
	{
		if(ATMaccount[victim] > cash)
			ATMaccount[victim] = ATMaccount[victim] - cash;
		else if(ATMaccount[victim] <= cash)
		{
			leftovers = cash - ATMaccount[victim];
			if(ATMaccount[CT_acct] > leftovers)
			{
				ATMaccount[CT_acct] = ATMaccount[CT_acct] - leftovers;
				ATMaccount[victim] = 0;
			}
			else
			{
				Format(TeamName, sizeof(TeamName), "Terrorist team");
				PrintCenterTextAll("%t", "bankrupt_team", AttackerName, TeamName);
				bankrupt = true;
				for(new a = 1; a <= maxclients; a++)
				{
					if(IsClientInGame(a))
					{
						if(ClientTeam == GetClientTeam(a))
							PrintToChat(a, "%t", "teamcash_reset");
					}
				}
			}
		}
	}
}

public Action:RespawnReward(Handle:timer, any:teamid)
{
	new maxclients = GetMaxClients();
	for (new i = 1; i <= maxclients; i++)
	{
		if(IsClientInGame(i))
		{
			if(GetClientTeam(i) == teamid)
			{
				RespawnCount[i] = RespawnCount[i] + 1;
				DisplayInfo(i, 0);
			}	
		}
	}
	return Plugin_Stop;
}

public AddLife(client)
{
	RespawnCount[client] = RespawnCount[client] + 1;
	PrintToChat(client, "[SM] %t", "add_life");
	DisplayInfo(client, 0);
}

public OnClientPutInServer(client)
{
	g_iHooks[client] = Hacks_Hook(client, HACKS_HTYPE_WEAPON_CANUSE, Weapon_CanUse, false);
	if(client != 0 && latespawn)
	{
		RespawnCount[client] = 3;
	}
	else if(client != 0 && !latespawn)
	{
		RespawnCount[client] = 5;
	}
	
	ATMaccount[client] = 0;
	DominationCount[client] = 0;
	PlayerisWaiting[client] = false;
	DominationCompare[client] = 0;
	WithdrawCount[client] = 0;
	HeadshotCount[client] = 0;
	buymenudisplay[client] = true;
	buymenucont[client] = true;
	healthmenu[client] = false;
	firstjoin[client] = true;
	ClientCredits[client] = 0;
	new maxclients = GetMaxClients();
	for(new a = 1; a <= maxclients; a++)
	{
		KillCount[client][a] = 0;
		if(a < 28)
		{
			WeaponKills[client][a] = 0;
		}
		if(a <= 8)
		{
			PlayerItems[client][a-1][0] = -1;
			PlayerItems[client][a-1][1] = 0;
		}
	}
}

public OnClientDisconnect(client)
{
	Hacks_Unhook(g_iHooks[client]);
	ATMaccount[client] = 0;
	DominationCount[client] = 0;
	PlayerisWaiting[client] = false;
	DominationCompare[client] = 0;
	WithdrawCount[client] = 0;
	HeadshotCount[client] = 0;
	buymenudisplay[client] = true;
	buymenucont[client] = false;
	healthmenu[client] = false;
	new maxclients = GetMaxClients();
	for(new a = 1; a <= maxclients; a++)
	{
		KillCount[client][a] = 0;
		if(a < 28)
		{
			WeaponKills[client][a] = 0;
		}
		if(a <= 8)
		{
			PlayerItems[client][a-1][0] = -1;
			PlayerItems[client][a-1][1] = 0;
		}
	}
}

public Action:TimedHealthRegen(Handle:timer, any:victim)
{
	if(!IsClientInGame(victim))
		return Plugin_Stop;
	
	new VictimHealth = GetClientHealth(victim);
	
	if(IsPlayerAlive(victim) && VictimHealth < 100)
	{
		SetClientHealth(victim, VictimHealth+1);
	}
	else
	{
		PlayerHealthChecked[victim] = false;
		return Plugin_Stop;
	}
	
	return Plugin_Continue;
}

public Action:OnPlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	new VictimHealth = GetClientHealth(victim);
	new VictimTeam = GetClientTeam(victim);
	new damage = GetEventInt(event, "dmg_health");
	
	if(DominationDmg[0] && TeamDomination[0] && TeamDomination_Mode == 1)
	{
		new extradamage = damage;
		if(VictimHealth - (damage + extradamage) != 0)
			SetClientHealth(victim, VictimHealth - (damage + extradamage));
	}
	if(DominationDmg[1] && TeamDomination[1] && TeamDomination_Mode == 1)
	{
		new extradamage = damage;
		if(VictimHealth - (damage + extradamage) != 0)
			SetClientHealth(victim, VictimHealth - (damage + extradamage));
	}
	
	if(IsPlayerAlive(victim) && PlayerHealthChecked[victim] == false)
	{
		if(TeamDomination[0] && TeamDomination_Mode == 3)
		{
			PlayerHealthChecked[victim] = true;
			if(VictimTeam == TEAM_T)
			{
				CreateTimer(1.5,TimedHealthRegen, victim,TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
			}
		}
		else if(TeamDomination[1] && TeamDomination_Mode == 3)
		{
			PlayerHealthChecked[victim] = true;
			if(VictimTeam == TEAM_CT)
			{
				CreateTimer(1.5,TimedHealthRegen, victim,TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
			}
		}
	}
	
}

public Action:BackpackTimer(Handle:timer, any:client)
{
	//new Float:spawnprotTime = GetConVarFloat(cvarspawnprotect);
	//PrintToConsole(client, "[SM] Player tripped backpack timer");
	SetupBackPack(client);
	CreateTimer(4.0,PreSpawn, client,TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
	PrintHintText(client, "%t", "Player_Spawn");
	return Plugin_Stop;
}

public Action:OnPlayerChangeTeam(Handle:event,const String:name[],bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event,"userid")); // Get clients index
	new team = GetEventInt(event, "team");
	new Float:respawntime = GetConVarFloat(cvarrespawntime);
	if(client != 0 && GetConVarBool(cvarpluginstatus))
	{
		if(IsClientInGame(client) && !IsPlayerAlive(client) && team > 1)
		{
			if(RespawnCount[client] > 0)
			{
				CreateTimer(respawntime,PlayerRespawn, client,TIMER_FLAG_NO_MAPCHANGE);
			}			
			PrintToChat(client, "[SM] %t", "info_chat");
			PrintToChat(client, "[SM] %t", "respawn_chat");
		}
	}
	return Plugin_Continue;
}
public Action:OnPlayerSpawn(Handle:event,const String:name[],bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event,"userid")); // Get clients index
	
	if(client != 0 && GetConVarBool(cvarpluginstatus) && !IsFakeClient(client))
	{
		new team = GetClientTeam(client);
		if((team == TEAM_CT || team == TEAM_T) && IsPlayerAlive(client))
		{
			//PrintToConsole(client, "[SM] Player Has Spawned");
			PlayerisProtected[client] = false;
			CreateTimer(0.6,BackpackTimer, client,TIMER_FLAG_NO_MAPCHANGE);
			if(buymenudisplay[client])
				BuyMenu_control(client, 0);
			
			SetEntityRenderFx(client, RENDERFX_FADE_FAST);	
			SetEntProp(client, Prop_Data, "m_takedamage", 0, 1);
			PlayerisWaiting[client] = false;
			ManageAccounts(client);
		}
		if(GetConVarBool(cvarcustomspawn) && spawnfile_exist && spawnlist_exist)
		{
			SetSpawn(client);
		}
	}
	return Plugin_Continue;
}


/* 
public Action:Command_testDom(client, args)
{
if (args < 2)
{
ReplyToCommand(client, "[SM] Usage: testDom <userid> <userid>");
return Plugin_Handled;	
}	

new String:Target[64], String:Target2[64];
GetCmdArg(1, Target, sizeof(Target));
GetCmdArg(2, Target2, sizeof(Target2));
new tclient = GetClientOfUserId(StringToInt(Target));
new tclient2 = GetClientOfUserId(StringToInt(Target2));
new String:clientName[64], String: clientName2[64];
GetClientName(tclient, clientName, sizeof(clientName));
GetClientName(tclient2, clientName2, sizeof(clientName2));

PrintToConsole(client, "%s has killed %s %d times in a row.", clientName, clientName2, KillCount[tclient2][tclient]);

return Plugin_Handled;
}
*/

public Action:RoundFreezeEndEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
	latespawn = false;
	if(!GetConVarBool(cvarpluginstatus))
	{
		return Plugin_Continue;
	}
	PrintToChatAll("[SM] %t", "Domination_Deathmatch");
	CreateTimer(60.0,PlayerLateSpawn,TIMER_FLAG_NO_MAPCHANGE);
	for (new i = 1; i <= MaxClients; i++)
	{
		// if player is actually playing the game, tell them how many lives they have.
		if(IsClientInGame(i) && GetClientTeam(i) > 1)
		{
			if(RespawnCount[i] < GetConVarInt(cvarrespawncount))
			{
				RespawnCount[i] = GetConVarInt(cvarrespawncount);
			}
			PrintToChat(i, "[SM] \x02%t\x02", "currlives", RespawnCount[i]);
		}
	}
	return Plugin_Continue;
}

public Action:OnRoundEnd(Handle:event,const String:name[],bool:dontBroadcast)
{
	new reason = GetEventInt(event, "reason");
	if(!GetConVarBool(cvarpluginstatus))
	{
		return Plugin_Continue;
	}
	
	if(reason == bomb_exploded)
	{  /* 
		ATMaccount[CT_acct] = ATMaccount[CT_acct] + 1000;
		ATMaccount[CT_acct] = ATMaccount[T_acct] - 1000;
		PrintToChatAll("\x01\x02%t", "ctm_win" */
		CreateTimer(7.0,RespawnReward, TEAM_T,TIMER_FLAG_NO_MAPCHANGE);
		PrintHintTextToAll("[SM] %t", "bomb_detonate");
	}
	if(reason == bomb_defused)
	{
		CreateTimer(7.0,RespawnReward, TEAM_CT,TIMER_FLAG_NO_MAPCHANGE);
		PrintHintTextToAll("[SM] %t", "bomb_defuse");
	}
	for (new i = 1; i <= MaxClients; i++)
	{
		NewItem[i] = false;
		PlayerisProtected[i] = false;
	}
	
	new T_Count = GetTeamClientCount(TEAM_T);
	new CT_Count = GetTeamClientCount(TEAM_CT);
	new total, bool: CT_majority = false;
	
	if(CT_Count > T_Count)
	{
		total = CT_Count-T_Count;
		CT_majority = true;
	}
	else if(CT_Count < T_Count)
	{
		total = T_Count-CT_Count;
		CT_majority = false;
	}
	else
	total = 0;
	
	
	if(total > 1)
	{
		new total2;
		if(total % 2 == 0)
			total2 = total/2;
		
		for(new i = 1; i <= MaxClients; i++)
		{
			if(CT_majority && total2 > 0)
			{
				if(total % 2 == 0)
				{
					if(GetClientTeam(TEAM_CT))
					{
						total2--;
						CS_SwitchTeam(i, TEAM_T);
					}
				}
				else
				{
					if(GetClientTeam(TEAM_CT))
					{
						if(total2 > 1)
						{
							total2--;
							CS_SwitchTeam(i, TEAM_T);
						}
						else
						total2 = 0;
					}
				}
			}
			else if(!CT_majority && total2 > 0)
			{
				if(total % 2 == 0)
				{
					if(GetClientTeam(TEAM_T))
					{
						total2--;
						CS_SwitchTeam(i, TEAM_CT);
					}
				}
				else
				{
					if(GetClientTeam(TEAM_T))
					{
						if(total2 > 1)
						{
							total2--;
							CS_SwitchTeam(i, TEAM_CT);
						}
						else
						total2 = 0;
					}
				}
			}
		}
	}
	
	return Plugin_Continue;
}

public ChatRespawn(client)
{
	if(!IsPlayerAlive(client))
	{
		if(RespawnCount[client] > 0)
		{
			RespawnCount[client] = RespawnCount[client] - 1;
			CreateTimer(1.5,PlayerRespawn, client,TIMER_FLAG_NO_MAPCHANGE);
		}
		else
		PrintToChat(client, "[SM] %t", "currlives", RespawnCount[client]);
	}
	else
	PrintToChat(client, "[SM] %t", "not_dead");
}

public Action:OnPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new headshotreq = GetConVarInt(cvarheadshotdom);
	new Float:respawntime = GetConVarFloat(cvarrespawntime);
	// get player userid
	new userid = GetEventInt(event, "userid");
	new userid2 = GetEventInt(event, "attacker");
	// get players entity ids
	new victim = GetClientOfUserId(userid);
	new attacker = GetClientOfUserId(userid2);
	new AttackerCash = GetClientMoney(attacker);
	new headshotbonus = GetConVarInt(cvarheadshotbonus);
	new reward;
	new bool:headshot = GetEventBool(event, "headshot");
	new String:AttackerName[64], String:VictimName[64];
	decl String:weaponName[128];
	new bool: teamdead = false;
	
	GetClientName(attacker, AttackerName, sizeof(AttackerName));
	GetClientName(victim, VictimName, sizeof(VictimName));
	
	if(!GetConVarBool(cvarpluginstatus))
	{
		return Plugin_Continue;
	}
	
	if(attacker != 0 && IsClientInGame(attacker))
	{
		// get player's teams
		new victimTeam = GetClientTeam(victim);
		new attackerTeam = GetClientTeam(attacker);
		
		if(victimTeam != attackerTeam)
		{
			GetEventString(event,"weapon",weaponName,128);
			AddWeaponKill(attacker, weaponName);
			reward = FindWeaponReward(weaponName);
			
			if(headshot)
			{
				if(!TeamDomination[0] && !TeamDomination[1])
					SetClientMoney(attacker, (AttackerCash - 300) + (reward + headshotbonus));
				
				PrintToConsole(attacker, "You were awarded $%d with a headshot bonus of $%d.", reward, headshotbonus);
				if(attackerTeam == TEAM_T)
				{
					ATMaccount[T_acct] = ATMaccount[T_acct] + reward + headshotbonus;
				}
				else if(attackerTeam == TEAM_CT)
				{
					ATMaccount[CT_acct] = ATMaccount[CT_acct] + reward + headshotbonus;
				}
				TeamDominationCheck();
				if(TeamDomination[0] || TeamDomination[1] && TeamDomination_Mode == 0)
					ManageTeamDomination(attacker, victim, (reward + headshotbonus));
				HeadshotCount[attacker] = HeadshotCount[attacker] + 1;
				HeadshotCount[victim] = 0;
				if(HeadshotCount[attacker] >= headshotreq)
				{
					PrintHintTextToAll("%t", "headshot_reward", AttackerName, HeadshotCount[attacker]);
					AddLife(attacker);
				}
				if(TeamDomination[0] && attackerTeam == TEAM_T)
				{
					if(RespawnCount[victim] > 0)
					{
						RespawnCount[attacker]++;
						RespawnCount[victim]--;
						PrintToChat(attacker, "[SM] %t", "steal_life", VictimName);
					}
				}
				else if(TeamDomination[1] && attackerTeam == TEAM_CT)
				{
					if(RespawnCount[victim] > 0)
					{
						RespawnCount[attacker]++;
						RespawnCount[victim]--;
						PrintToChat(attacker, "[SM] %t", "steal_life", VictimName);
					}
				}
			}
			else
			{
				HeadshotCount[attacker] = 0;
				if(!TeamDomination[0] && !TeamDomination[1])
					SetClientMoney(attacker, (AttackerCash - 300) + reward);
				PrintToConsole(attacker, "You were awarded $%d.", reward);
				if(attackerTeam == TEAM_T)
				{
					ATMaccount[T_acct] = ATMaccount[T_acct] + reward;
				}
				else if(attackerTeam == TEAM_CT)
				{
					ATMaccount[CT_acct] = ATMaccount[CT_acct] + reward;
				}
				TeamDominationCheck();
				if(TeamDomination[0] || TeamDomination[1] && TeamDomination_Mode == 0)
					ManageTeamDomination(attacker, victim, reward);
			}
			for(new i = 1; i <= GetMaxClients(); i++)
			{
				if(IsClientInGame(i))
				{
					if(victimTeam == GetClientTeam(i))
					{
						if(IsPlayerAlive(i))
						{
							teamdead = false;
							break;
						}							
						else
						teamdead = true;
					}
				}
			}
			
		}		
		
		if(attacker != 0 && victim != 0 && IsClientInGame(attacker) && IsClientInGame(victim))
		{	
			DominationReward(attacker, victim);
			WeaponDominationCheck(attacker, victim, weaponName);
			ManageAccounts(attacker);
			ManageAccounts(victim);
			ManageTeamAccounts(attacker, victim);
			CashForDead(attacker, reward/4);
			
			if(TeamDomination[0] && !TeamDomination[1] && TeamDomination_Mode == 2)
			{
				if(victimTeam == TEAM_CT && GetTeamClientCount(TEAM_CT) > 1)
				{
					CS_SwitchTeam(victim, TEAM_T);
				}
				else
				g_TimeLeft_T = 1;
			}
			else if(!TeamDomination[0] && TeamDomination[1] && TeamDomination_Mode == 2)
			{
				if(victimTeam == TEAM_T&& GetTeamClientCount(TEAM_T) > 1)
				{
					CS_SwitchTeam(victim, TEAM_CT);
				}
				else
				g_TimeLeft_CT = 1;
			}
			
			CreateTimer(1.0, Remove_Corpse, victim, TIMER_FLAG_NO_MAPCHANGE);
			
			if(!AutomaticHealth[attacker] && !IsFakeClient(attacker))
			{
				if(GetClientHealth(attacker) < 90)
					BuyHealthMenu_control(attacker, 0);
			}
			else
			{
				CreateTimer(3.0, ManageClientHealth, attacker, TIMER_FLAG_NO_MAPCHANGE);
			}
		}
	}
	if(IsClientInGame(victim))
	{
		if(RespawnCount[victim] > 0 && !teamdead)
		{
			NewItem[victim] = false;
			RespawnCount[victim] = RespawnCount[victim] - 1;
			DisplayInfo(victim, 0);
			CreateTimer(respawntime,PlayerRespawn, victim,TIMER_FLAG_NO_MAPCHANGE);
		}
		else if(RespawnCount[victim] <= 0)
		{
			extraBuyMenu_control(victim, 0);
		}
	}
	
	return Plugin_Continue;
}

public ManageAccounts(client)
{
	new extracash, reqcash, withdrawcash;
	
	if(client != 0 && IsClientInGame(client))
	{
		new ClientCash = GetClientMoney(client);
		if(ClientCash > 10000)
		{
			extracash = ClientCash - 10000;
			ATMaccount[client] += extracash;
			PrintToConsole(client, "[ATM] %t", "deposit_money", extracash);
			SetClientMoney(client, 10000);
		}
		if(ATMaccount[client] != 0)
		{
			if(ClientCash < 10000)
			{
				if(ClientCash + ATMaccount[client] < 10000)
				{
					SetClientMoney(client, ClientCash + ATMaccount[client]);
					ATMaccount[client] = 0;
				}
				else
				{
					reqcash = 10000 - ClientCash;
					if(reqcash < ATMaccount[client])
					{
						ATMaccount[client] = ATMaccount[client] - reqcash;
						withdrawcash = reqcash;
						SetClientMoney(client, ClientCash+withdrawcash);
					}
					else
					{	
						withdrawcash = ATMaccount[client];
						SetClientMoney(client, ClientCash+withdrawcash);
						ATMaccount[client] = 0;
					}
				}
				PrintToConsole(client, "[ATM] %t", "withdraw_money", withdrawcash);
			}
		}			
	}
}

public ManageTeamAccounts(attacker, client)
{
	if(client != 0 && IsClientInGame(attacker) && IsClientInGame(client))
	{
		new maxclients = GetMaxClients();
		new ClientCash = GetClientMoney(client);
		new ClientTeam = GetClientTeam(client);
		new AttackerTeam = GetClientTeam(attacker);
		new withdrawcash = GetConVarInt(cvarmaxwithdraw);
		new teamid;
		new String:AttackerName[255];
		new String:TeamName[64];
		GetClientName(attacker, AttackerName, sizeof(AttackerName));
		
		if(ClientTeam == TEAM_T)
		{
			teamid = T_acct;
			Format(TeamName, sizeof(TeamName), "Terrorist team");
		}
		else if(ClientTeam == TEAM_CT)
		{
			teamid = CT_acct;
			Format(TeamName, sizeof(TeamName), "Counter-Terrorist team");
		}
		if(ATMaccount[teamid] != 0)
		{
			if(ClientCash < 800 && client != 0)
			{
				
				if(ClientCash + ATMaccount[teamid] < withdrawcash)
				{
					SetClientMoney(client, ClientCash + ATMaccount[teamid]);
					ATMaccount[teamid] = GetConVarInt(cvarteamacct);
					PrintCenterTextAll("%t", "bankrupt_team", AttackerName, TeamName);
					for(new i = 1; i <= maxclients; i++)
					{
						if(IsClientInGame(i))
						{
							if(ClientTeam == GetClientTeam(i))
								PrintToChat(i, "%t", "teamcash_reset");
						}
					}
					CreateTimer(1.0,RespawnReward, AttackerTeam,TIMER_FLAG_NO_MAPCHANGE);
				}
				else if(ATMaccount[teamid] > GetConVarInt(cvarteamacct))
				{
					SetClientMoney(client, ClientCash + withdrawcash);
					ATMaccount[teamid] = ATMaccount[teamid] - withdrawcash;
					/*
					reqcash = 800 - ClientCash;
					if(reqcash < ATMaccount[teamid])
					{
					ATMaccount[teamid] = ATMaccount[teamid] - reqcash;
					withdrawcash = reqcash;
					SetClientMoney(client, ClientCash+withdrawcash);
					}
					else
					{	
					withdrawcash = ATMaccount[teamid];
					SetClientMoney(client, ClientCash+withdrawcash);
					ATMaccount[teamid] = GetConVarInt(cvarteamacct);
					PrintCenterTextAll("%t", "bankrupt_team", AttackerName, TeamName);
					for(new i = 1; i <= maxclients; i++)
					{
					if(IsClientInGame(i))
					{
					if(ClientTeam == GetClientTeam(i))
						PrintToChat(i, "%t", "teamcash_reset");
					}
					}
					AddLife(attacker);
					}
					*/
				}
				else if(ATMaccount[teamid] <= GetConVarInt(cvarteamacct) && WithdrawCount[client] < 4)
				{
					SetClientMoney(client, ClientCash + withdrawcash);
					ATMaccount[teamid] = ATMaccount[teamid] - withdrawcash;
					WithdrawCount[client] = WithdrawCount[client] + 1;
				}
				
				PrintToChat(client, "[SM] %t", "wallet_update");
				
			}	
		}	
	}
}

/*
* ManageClientHealth
* 
* Manages Client's health, heals client for the right amt of $$$
*/
public Action:ManageClientHealth(Handle: timer, any:client)
{
	if(!IsClientInGame(client))
	{
		return Plugin_Handled;
	}
	else if(!IsPlayerAlive(client))
	{
		return Plugin_Handled;
	}
	else if(client < 1)
	{
		LogError("[SM] Warning: Invalid client index %d received at function ManageClientHealth!", client);
	}
	new ClientHealth = GetClientHealth(client);
	new ClientCash = GetClientMoney(client);
	if(ClientCash >= 2000 && ClientHealth < 100)
	{
		if(ClientHealth >= 75 && ClientHealth < 100)
		{
			SetClientMoney(client, ClientCash - 500);
			SetClientHealth(client, 100);
		}
		else if(ClientHealth < 75 && ClientHealth >= 50)
		{
			SetClientMoney(client, ClientCash - 1000);
			SetClientHealth(client, 100);
		}
		else if(ClientHealth < 50 && ClientHealth >= 25)
		{
			SetClientMoney(client, ClientCash - 1500);
			SetClientHealth(client, 100);
		}
		else if(ClientHealth < 25)
		{
			SetClientMoney(client, ClientCash - 2000);
			SetClientHealth(client, 100);
		}
	}
	else if(ClientCash >= 1500 && ClientCash < 2000 && ClientHealth < 100)
	{
		if(ClientHealth >= 75 && ClientHealth < 100)
		{
			SetClientMoney(client, ClientCash - 500);
			SetClientHealth(client, 100);
		}
		else if(ClientHealth < 75 && ClientHealth >= 50)
		{
			SetClientMoney(client, ClientCash - 1000);
			SetClientHealth(client, 100);
		}
		else if(ClientHealth < 50 && ClientHealth >= 25)
		{
			SetClientMoney(client, ClientCash - 1500);
			SetClientHealth(client, 100);
		}
		else if(ClientHealth < 25)
		{
			SetClientMoney(client, ClientCash - 1500);
			SetClientHealth(client, ClientHealth+75);
		}
	}
	else if(ClientCash >= 1000 && ClientCash < 1500 && ClientHealth < 100)
	{
		if(ClientHealth >= 75 && ClientHealth < 100)
		{
			SetClientMoney(client, ClientCash - 500);
			SetClientHealth(client, 100);
		}
		else if(ClientHealth < 75 && ClientHealth >= 50)
		{
			SetClientMoney(client, ClientCash - 1000);
			SetClientHealth(client, 100);
		}
		else if(ClientHealth < 50)
		{
			SetClientMoney(client, ClientCash - 1000);
			SetClientHealth(client, ClientHealth+50);
		}
	}
	else if(ClientCash >= 500 && ClientCash < 1000 && ClientHealth < 100)
	{
		if(ClientHealth >= 75 && ClientHealth < 100)
		{
			SetClientMoney(client, ClientCash - 500);
			SetClientHealth(client, 100);
		}
		else if(ClientHealth < 75)
		{
			SetClientMoney(client, ClientCash - 500);
			SetClientHealth(client, ClientHealth+25);
		}
	}
	return Plugin_Stop;
}


public Action:PlayerLateSpawn(Handle:timer)
{
	latespawn = true;
	return Plugin_Stop;
}

public Action:PlayerRespawn(Handle:timer, any:index)
{
	if(IsClientInGame(index))
	{
		if(!IsPlayerAlive(index) && GetClientTeam(index) > 1)
		{
			CS_RespawnPlayer(index);
			//PrintToChat(index, "[SM] %t", "lives_left", RespawnCount[index]);
		}
	}
	return Plugin_Stop;
}

public Action:Remove_Corpse(Handle:timer, any:client)
{
	new Body_Offset, Body_Ragdoll;
	if(IsClientInGame(client))
	{
		Body_Offset = FindSendPropOffs("CCSPlayer", "m_hRagdoll");
		Body_Ragdoll = GetEntDataEnt2(client, Body_Offset);
		if(Body_Ragdoll != -1)
		{
			RemoveEdict(Body_Ragdoll);
		}
		else
		LogError("[SM] Cannot Find Ragdoll.");
	}
	else
	LogMessage("[SM] Remove_Corpse: Player is not in game");
	return Plugin_Stop;
}

public PlayerProt(client)
{
	if(client != 0 && IsClientInGame(client))
	{
		PlayerisProtected[client] = false;
		//if(!PlayerisProtected[client])
		//PrintToConsole(client, "[SM] Player is now unprotected");
		UnloadBackPack(client);
		SetEntProp(client, Prop_Data, "m_takedamage", 2, 1);
		SetEntData(client, g_offsCollisionGroup, 5, 4, true);
		SetEntityRenderFx(client, RENDERFX_NONE);
	}
}

public Action:Command_dmweapon(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_dmweapon <weapon> <cash>");
		return Plugin_Handled;
	}
	new String:weapon[64];
	new String:tmpc[30];
	new cash;
	GetCmdArg(1, weapon, sizeof(weapon));
	GetCmdArg(2, tmpc,sizeof(tmpc));
	cash = StringToInt(tmpc);
	SetWeaponReward(client, weapon, cash);
	return Plugin_Handled;
}

public Action:Command_ItemCost(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Set the cost of an item. Use -1 to disable weapon. Usage: sm_itemcost <item> <cost>");
		return Plugin_Handled;
	}
	new String:item[64];
	new String:tmpc[30];
	new cost;
	GetCmdArg(1, item, sizeof(item));
	GetCmdArg(2, tmpc,sizeof(tmpc));
	cost = StringToInt(tmpc);
	if(cost >= -1)
		SetItemCost(client, item, cost);
	else
	ReplyToCommand(client, "[SM] Error, Use values -1 or greater to set cost.");
	return Plugin_Handled;
}

public Action:Command_Say(client,args)
{
	decl String:speech[128];
	
	GetCmdArgString(speech,sizeof(speech));
	if(client != 0 && GetConVarBool(cvarpluginstatus))
	{
		new startidx = 0;
		if (speech[0] == '"')
		{
			startidx = 1;
			// Strip the ending quote, if there is one
			new len = strlen(speech);
			if (speech[len-1] == '"')
			{
				speech[len-1] = '\0';
			}
		}
		if(strcmp(speech[startidx],"!buylife",false) == 0 && RespawnCount[client] == 0)
		{
			extraBuyMenu_control(client, 0);
			return Plugin_Handled;
		}
		else if(strcmp(speech[startidx],"!info",false) == 0)
		{
			DisplayInfo(client, 0);
			return Plugin_Handled;
		}
		else if(strcmp(speech[startidx],"!spawn",false) == 0)
		{
			ChatRespawn(client);
			return Plugin_Handled;
		}
		else if(StrContains(speech[startidx], "respawn", false) != -1 && StrContains(speech[startidx], "how") != -1)
		{
			PrintToChat(client, "[SM] %t", "respawn_chat");
		}
		else if(strcmp(speech[startidx],"help",false) == 0)
		{
			PrintToChat(client, "[SM] %t", "info_chat");
			PrintToChat(client, "[SM] %t", "respawn_chat");
			PrintToChat(client, "[SM] %t",  "buymenu_chat");
			PrintToChat(client, "[SM] %t",  "buybind_chat");
			PrintToChat(client, "[SM] %t",  "rebuy_chat");
			PrintToChat(client, "[SM] %t",  "backpack_chat");
		}
		else if(strcmp(speech[startidx], "buy", false) == 0)
		{
			new team = GetClientTeam(client);
			if(team == TEAM_CT || team == TEAM_T)
			{
				BuyMenu_control(client, args);
			}
			return Plugin_Handled;
		}
	}
	
	
	return Plugin_Continue;
	
}


/*
* Domination reward function,
* Steals $1000 or all of cash
* each bonus kill awards $500 to attacker 
* 
* Attacker - entity id of attacker
* victim - entity id of victim
* 
* only called on player death.
*/

public DominationReward(attacker, victim)
{
	new maxclients = GetMaxClients();
	new String: AttackerName[255], String: VictimName[255];
	GetClientName(attacker, AttackerName, sizeof(AttackerName));
	GetClientName(victim, VictimName, sizeof(VictimName));
	new AttackerCash = GetClientMoney(attacker);
	new VictimCash = GetClientMoney(victim);
	new VictimTeam = GetClientTeam(victim);
	new String:TeamName[64];
	new VictimCashGive;
	new domination = GetConVarInt(cvardomination);
	new dominationcash = GetConVarInt(cvardominationcash);
	new dominationcashbonus = GetConVarInt(cvardominationcashbonus);
	
	KillCount[victim][attacker] = KillCount[victim][attacker] + 1;
	if(KillCount[victim][attacker] == domination && attacker != 0)
	{
		if(VictimCash <= dominationcash)
		{
			VictimCashGive = VictimCash;
			SetClientMoney(attacker, AttackerCash+VictimCash);
			SetClientMoney(victim, 0);
			
		}
		if(VictimCash > dominationcash)
		{
			SetClientMoney(attacker, AttackerCash + (VictimCash - dominationcash));
			SetClientMoney(victim, VictimCash - dominationcash);
			VictimCashGive = dominationcash;
		}
		DominationCount[attacker] = DominationCount[attacker] + 1;
		PrintCenterTextAll("%t", "player_dominate", AttackerName, VictimName);
		
		if(DominationCount[attacker] == 1)
			PrintToChatAll("\x01\x03%t", "player_dominate", AttackerName, VictimName);
		
		PrintHintTextToAll("\x01\x03%t", "player_dominate_reward", AttackerName, VictimCashGive, VictimName);
		
		if(DominationCount[attacker] > 1)
		{
			PrintToChatAll("\x01\x03%t", "player_dominate_multi", AttackerName, DominationCount[attacker]);
			ManageTeamAccounts(attacker, victim);
		}
	}	
	if(KillCount[victim][attacker] > domination && attacker != 0)
	{
		SetClientMoney(attacker, AttackerCash+dominationcashbonus);
		PrintCenterTextAll("%t", "player_dominate2", AttackerName, VictimName, KillCount[victim][attacker]);
		PrintToChatAll("\x01\x03%t\x01\x03", "player_dominate2", AttackerName, VictimName, KillCount[victim][attacker]);
		PrintToChat(attacker, "\x01\x03%t\x01\x03", "dominate_bonus", dominationcashbonus, VictimName);
	}
	
	else if(KillCount[victim][attacker] > 0 && KillCount[attacker][victim] > 0 && attacker != 0)
	{
		if(KillCount[attacker][victim] >= domination)
		{
			PrintCenterTextAll("%t", "player_dominate_end", AttackerName, VictimName);
			ClientCredits[attacker] += 3;
			PrintToChat(attacker, "[SM] %t", "recieve_credits", VictimName);
			if(DominationCount[victim] > 0)
			{
				DominationCount[victim] = DominationCount[victim] - 1;
				DominationCompare[victim] = DominationCount[victim];
			}
		}
		KillCount[attacker][victim] = 0;
	}
	// multiple domination reward
	new teamid, multidom;
	
	if(VictimTeam == TEAM_T)
	{
		teamid = T_acct;
		Format(TeamName, sizeof(TeamName), "Terrorist team");
	}
	else if(VictimTeam == TEAM_CT)
	{
		teamid = CT_acct;
		Format(TeamName, sizeof(TeamName), "Counter-Terrorist team");
	}
	
	if(DominationCount[attacker] > DominationCompare[attacker] && DominationCount[attacker] > 1)
	{
		DominationCompare[attacker] = DominationCount[attacker];
		if(ATMaccount[teamid] > DominationCount[attacker] * 1000)
		{
			multidom = DominationCount[attacker] * 1000;
			SetClientMoney(attacker, AttackerCash + multidom);
			ATMaccount[teamid] = ATMaccount[teamid] - multidom;
			AddLife(attacker);
			PrintToChatAll("\x01\x02%t", "player_multidomreward", AttackerName, multidom, TeamName);
		}
		else if(ATMaccount[teamid] <= DominationCount[attacker] * 1000) 
		{
			multidom = ATMaccount[teamid];
			SetClientMoney(attacker, AttackerCash + ATMaccount[teamid]);
			ATMaccount[teamid] = GetConVarInt(cvarteamacct);
			PrintCenterTextAll("%t", "bankrupt_team", AttackerName, TeamName);
			for(new i = 1; i <= maxclients; i++)
			{
				if(IsClientInGame(i))
				{
					if(VictimTeam == GetClientTeam(i))
						PrintToChat(i, "%t", "teamcash_reset");
				}
			}
			AddLife(attacker);
			PrintToChatAll("\x01\x02%t", "player_multidomreward", AttackerName, multidom, TeamName);
		}
		
		
	}
}



public extraBuyMenu(Handle:menu, MenuAction:action, param1, param2)
{
	/* If an option was selected, tell the client about the item. */
	new lifecost = GetConVarInt(cvarextralifecost);
	new lifeTeamSwitch= GetConVarInt(cvarlifeteamSwCost);
	if (action == MenuAction_Select)
	{
		if(param2 == 0)
		{
			if(GetClientMoney(param1) < lifecost)
			{
				PrintToChat(param1, "[SM] %t", "money");
				PlayerisWaiting[param1] = true;
			}
			
			if(GetClientMoney(param1) >= lifecost)
			{
				SetClientMoney(param1, GetClientMoney(param1) - lifecost);
				CreateTimer(0.5,PlayerRespawn, param1,TIMER_FLAG_NO_MAPCHANGE);
			}
		}
		if(param2 == 1)
		{
			if(GetClientMoney(param1) < lifeTeamSwitch)
			{
				PrintToChat(param1, "[SM] %t", "money");
				PlayerisWaiting[param1] = true;
			}
			
			if(GetClientMoney(param1) >= lifeTeamSwitch)
			{
				SetClientMoney(param1, GetClientMoney(param1) - lifeTeamSwitch);
				if(GetClientTeam(param1) == TEAM_T)
					CS_SwitchTeam(param1, TEAM_CT);
				else
				CS_SwitchTeam(param1, TEAM_T);
				
				RespawnCount[param1] = 4;
				CreateTimer(0.5,PlayerRespawn, param1,TIMER_FLAG_NO_MAPCHANGE);
			}
		}
		if(param2 == 2)
		{
			PrintToChat(param1, "[SM] %t", "buy_life_chat");
			PlayerisWaiting[param1] = true;
		}
	}
	
	/* If the menu has ended, destroy it */
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public Action:extraBuyMenu_control(client, args)
{
	new String: buffer[64];
	new String: buffer2[64];
	new String: buffer3[64];
	new lifecost = GetConVarInt(cvarextralifecost);
	new lifeTeamSwitch = GetConVarInt(cvarlifeteamSwCost);
	new Handle:menu = CreateMenu(extraBuyMenu);
	SetMenuTitle(menu, "%t", "buy_life");
	Format(buffer, sizeof(buffer), "%T", "life_cost", LANG_SERVER, lifecost);
	Format(buffer2, sizeof(buffer2), "%T", "life_teamswitch", LANG_SERVER, lifeTeamSwitch);
	Format(buffer3, sizeof(buffer3), "%T", "life_c4d", LANG_SERVER);
	AddMenuItem(menu, buffer, buffer);
	AddMenuItem(menu, buffer2, buffer2);
	AddMenuItem(menu, buffer3, buffer3);
	SetMenuExitButton(menu, false);
	DisplayMenu(menu, client, 20);
	
	return Plugin_Handled;
}	

public BuyHealthMenu(Handle:menu, MenuAction:action, param1, param2)
{
	/* If an option was selected, tell the client about the item. */
	if (action == MenuAction_Select)
	{
		new clienthealth = GetClientHealth(param1);
		if(param2 == 0)
		{
			if(GetClientMoney(param1) < 500)
			{
				PrintToChat(param1, "[SM] %t", "money");
			}
			
			if(GetClientMoney(param1) >= 500)
			{
				SetClientMoney(param1, GetClientMoney(param1) - 500);
				if(clienthealth <= 75)
					SetClientHealth(param1, clienthealth + 25);
				else
				SetClientHealth(param1, 100);
			}
		}
		else if(param2 == 1)
		{
			if(GetClientMoney(param1) < 1000)
			{
				PrintToChat(param1, "[SM] %t", "money");
			}
			
			if(GetClientMoney(param1) >= 1000)
			{
				SetClientMoney(param1, GetClientMoney(param1) - 1000);
				if(clienthealth <= 50)
					SetClientHealth(param1, clienthealth + 50);
				else
				SetClientHealth(param1, 100);
			}
		}
		else if(param2 == 2)
		{
			if(GetClientMoney(param1) < 1500)
			{
				PrintToChat(param1, "[SM] %t", "money");
			}
			
			if(GetClientMoney(param1) >= 1500)
			{
				SetClientMoney(param1, GetClientMoney(param1) - 1500);
				if(clienthealth <= 25)
					SetClientHealth(param1, clienthealth + 75);
				else
				SetClientHealth(param1, 100);
			}
		}
		else if(param2 == 3)
		{
			if(GetClientMoney(param1) < 2000)
			{
				PrintToChat(param1, "[SM] %t", "money");
			}
			
			if(GetClientMoney(param1) >= 2000)
			{
				SetClientMoney(param1, GetClientMoney(param1) - 2000);
				SetClientHealth(param1, 100);
			}
		}
		
		else if(param2 == 4)
		{
			if(AutomaticHealth[param1] == false)
			{
				AutomaticHealth[param1] = true;
				CreateTimer(0.5, ManageClientHealth, param1, TIMER_FLAG_NO_MAPCHANGE);
			}
			else
			AutomaticHealth[param1] = false;
		}
		else if(param2 == 5)
		{
			if(healthmenu[param1])
				healthmenu[param1] = false;
			else
			{
				healthmenu[param1] = true;
				BuyHealthMenu_control(param1, 0);
			}
		}
	}
	
	else if(action == MenuAction_Cancel)
	{
		if(param2 == MenuCancel_Exit || param2 == MenuCancel_Timeout)
		{
			PrintToChat(param1, "[SM] %t",  "buymenu_chat");
		}
	}
	
	/* If the menu has ended, destroy it */
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

/*
* Buy health menu
* lets player buy health for set amount but does not allow past 100 hp
* choices 25, 50, 75, full
* 25 hp - $500
* 50 hp - $1000
* 75 hp - $1500
* full hp - $2000
*/
public Action:BuyHealthMenu_control(client, args)
{
	new String: buffer[64];
	new String: buffer2[32];
	new Handle:menu = CreateMenu(BuyHealthMenu);
	SetMenuTitle(menu, "%t", "buy_health");
	AddMenuItem(menu, "$500 - 25 hp", "$500 - 25 hp");
	AddMenuItem(menu, "$1000 - 50 hp", "$1000 - 50 hp");
	AddMenuItem(menu, "$1500 - 75 hp", "$1500 - 75 hp");
	AddMenuItem(menu, "$2000 - 100 hp", "$2000 - 100 hp");
	if(AutomaticHealth[client])
		Format(buffer2, sizeof(buffer2), "%T", "autohealth_disable", LANG_SERVER);
	else
	Format(buffer2, sizeof(buffer2), "%T", "autohealth_enable", LANG_SERVER);
	
	if(healthmenu[client])
		Format(buffer, sizeof(buffer), "%T", "healthmenu_show", LANG_SERVER);
	else
	Format(buffer, sizeof(buffer), "%T", "healthmenu_hide", LANG_SERVER);
	
	AddMenuItem(menu, buffer2, buffer2);	
	AddMenuItem(menu, buffer, buffer);
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 20);
}

public Info_Panel(Handle:menu, MenuAction:action, param1, param2)
{
	action = MenuAction_Select;
}

public Action:DisplayInfo(client, args)
{
	new Float:respawntime = GetConVarFloat(cvarrespawntime);
	new ClientTeam = GetClientTeam(client);
	new String:buffer[32], String:buffer2[64], String:buffer3[32], String:buffer4[32];
	new String:buffer5[64], String:buffer6[32];
	new String:TeamName[32];
	new Handle:panel = CreatePanel();
	new time = FloatToInt(respawntime);
	if(time == 0)
		return Plugin_Handled;
	Format(buffer, sizeof(buffer), "%T", "lives_menu", LANG_SERVER, RespawnCount[client]);
	Format(buffer2, sizeof(buffer2), "%T", "dom_menu", LANG_SERVER, DominationCount[client]);
	Format(buffer3, sizeof(buffer3), "%T", "close_menu", LANG_SERVER);
	Format(buffer4, sizeof(buffer4), "%T", "account_balance", LANG_SERVER, ATMaccount[client]);
	if(ClientTeam == TEAM_T)
	{
		Format(TeamName, sizeof(TeamName), "Terrorist");
		Format(buffer5, sizeof(buffer5), "%T", "team_account", LANG_SERVER, TeamName, ATMaccount[T_acct]); 
	}
	else if(ClientTeam == TEAM_CT)
	{
		Format(TeamName, sizeof(TeamName), "Counter-Terrorist");
		Format(buffer5, sizeof(buffer5), "%T", "team_account", LANG_SERVER, TeamName, ATMaccount[CT_acct]);
	}
	Format(buffer6, sizeof(buffer6), "%T", "credits", LANG_SERVER, ClientCredits[client]);
	
	SetPanelTitle(panel, buffer);
	DrawPanelItem(panel, buffer2);
	DrawPanelItem(panel, buffer4);
	DrawPanelItem(panel, buffer5);
	DrawPanelItem(panel, buffer3);
	DrawPanelItem(panel, buffer6);
	
	SendPanelToClient(panel, client, Info_Panel, time-1);
	
	CloseHandle(panel);
	
	return Plugin_Handled;
}

public ResetRebuy(client)
{
	LastPrimaryWeapon[client] = -1;
	LastSecondaryWeapon[client]= -1;
	for(new i = 0; i < 7; i++)
	{
		LastEquipmentItem[client][i] = 0;
	}
}


public Equip_Menu(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		new ClientTeam = GetClientTeam(param1);
		new ClientCash = GetClientMoney(param1);
		new helmet = FindSendPropOffs("CCSPlayer", "m_bHasHelmet");
		new armor = FindSendPropOffs("CCSPlayer", "m_ArmorValue");
		if(ClientTeam == TEAM_T)
		{
			if(param2 == 0 && ClientCash >= kevlar && kevlar != -1)
			{
				SetEntProp(param1, Prop_Send, "m_ArmorValue", 100, 1);
				SetClientMoney(param1, ClientCash - kevlar);
				if(!NewItem[param1])
				{
					NewItem[param1] = true;
					ResetRebuy(param1);
				}
				LastEquipmentItem[param1][0] = 1;
			}
			else if(param2 == 1 && ClientCash >= kevlarhelmet && kevlarhelmet != -1)
			{
				if(GetEntData(param1, helmet) == 1 && GetEntData(param1, armor) == 100)
				{
					PrintCenterText(param1, "You already have a kevlar and helmet!");
				}
				else if(GetEntData(param1, armor) == 100 && GetEntData(param1, helmet) == 0)
				{
					SetEntProp(param1, Prop_Send, "m_bHasHelmet", 1, 1);
					SetClientMoney(param1, ClientCash - helmet_cost);
				}
				else if(GetEntData(param1, helmet) == 0 && GetEntData(param1, armor) < 100)
				{
					SetEntProp(param1, Prop_Send, "m_ArmorValue", 100, 1);
					SetEntProp(param1, Prop_Send, "m_bHasHelmet", 1, 1);
					SetClientMoney(param1, ClientCash - kevlarhelmet);
				}
				else if(GetEntData(param1, helmet) == 1 && GetEntData(param1, armor) < 100)
				{
					SetEntProp(param1, Prop_Send, "m_ArmorValue", 100, 1);
					SetClientMoney(param1, ClientCash - kevlar);
				}
				if(!NewItem[param1])
				{
					NewItem[param1] = true;
					ResetRebuy(param1);
				}
				LastEquipmentItem[param1][1] = 1;
			}
			else if(param2 == 2 && ClientCash >= flashbang_cost && flashbang_cost != -1)
			{
				if(PlayerisProtected[param1])
				{
					PrintToChat(param1, "[SM] %t", "bought_item", "Flashbang Grenade");
					PlayerItems[param1][3][0] = GetWeaponidByName("weapon_flashbang");
					PlayerItems[param1][3][1]++;
				}
				else
				GivePlayerItem(param1, "weapon_flashbang");
				
				SetClientMoney(param1, ClientCash - flashbang_cost);
				if(!NewItem[param1])
				{
					NewItem[param1] = true;
					ResetRebuy(param1);
				}
				LastEquipmentItem[param1][2] = LastEquipmentItem[param1][2] + 1;
			}
			else if(param2 == 3 && ClientCash >= hegrenade_cost && hegrenade_cost != -1)
			{
				if(PlayerisProtected[param1])
				{
					PrintToChat(param1, "[SM] %t", "bought_item", "HE Grenade");
					PlayerItems[param1][4][0] = GetWeaponidByName("weapon_hegrenade");
					PlayerItems[param1][4][1]++;
				}
				else
				GivePlayerItem(param1, "weapon_hegrenade");
				
				SetClientMoney(param1, ClientCash - hegrenade_cost);
				if(!NewItem[param1])
				{
					NewItem[param1] = true;
					ResetRebuy(param1);
				}
				LastEquipmentItem[param1][3] = LastEquipmentItem[param1][3] + 1;
			}
			else if(param2 == 4 && ClientCash >= smokegrenade_cost && smokegrenade_cost != -1)
			{
				if(PlayerisProtected[param1])
				{
					PrintToChat(param1, "[SM] %t", "bought_item", "Smoke Grenade");
					PlayerItems[param1][5][0] = GetWeaponidByName("weapon_smokegrenade");
					PlayerItems[param1][5][1]++;
				}
				else
				GivePlayerItem(param1, "weapon_smokegrenade");
				
				SetClientMoney(param1, ClientCash - smokegrenade_cost);
				if(!NewItem[param1])
				{
					NewItem[param1] = true;
					ResetRebuy(param1);
				}
				LastEquipmentItem[param1][4] = LastEquipmentItem[param1][4] + 1;
			}
			else if(param2 == 5 && ClientCash >= nvgoggles && nvgoggles != -1)
			{
				SetEntProp(param1, Prop_Send, "m_bHasNightVision", 1, 1);
				SetClientMoney(param1, ClientCash - nvgoggles);
				if(!NewItem[param1])
				{
					NewItem[param1] = true;
					ResetRebuy(param1);
				}
				LastEquipmentItem[param1][5] = 1; 
			}
			else if(param2 == 0 && ClientCredits[param1] > 0 && kevlar != -1)
			{
				SetEntProp(param1, Prop_Send, "m_ArmorValue", 100, 1);
				ClientCredits[param1]--;
				if(!NewItem[param1])
				{
					NewItem[param1] = true;
					ResetRebuy(param1);
				}
				LastEquipmentItem[param1][0] = 1;
			}
			else if(param2 == 1 && ClientCredits[param1] > 0 && kevlarhelmet != -1)
			{
				if(GetEntData(param1, helmet) == 1 && GetEntData(param1, armor) == 100)
				{
					PrintCenterText(param1, "You already have a kevlar and helmet!");
				}
				else if(GetEntData(param1, armor) == 100 && GetEntData(param1, helmet) == 0)
				{
					SetEntProp(param1, Prop_Send, "m_bHasHelmet", 1, 1);
					ClientCredits[param1]--;
				}
				else if(GetEntData(param1, helmet) == 0 && GetEntData(param1, armor) < 100)
				{
					SetEntProp(param1, Prop_Send, "m_ArmorValue", 100, 1);
					SetEntProp(param1, Prop_Send, "m_bHasHelmet", 1, 1);
					ClientCredits[param1]--;
				}
				else if(GetEntData(param1, helmet) == 1 && GetEntData(param1, armor) < 100)
				{
					SetEntProp(param1, Prop_Send, "m_ArmorValue", 100, 1);
					ClientCredits[param1]--;
				}
				if(!NewItem[param1])
				{
					NewItem[param1] = true;
					ResetRebuy(param1);
				}
				LastEquipmentItem[param1][1] = 1;
			}
			else if(param2 == 2 && ClientCredits[param1] > 0 && flashbang_cost != -1)
			{
				if(PlayerisProtected[param1])
				{
					PrintToChat(param1, "[SM] %t", "bought_item", "Flashbang Grenade");
					PlayerItems[param1][3][0] = GetWeaponidByName("weapon_flashbang");
					PlayerItems[param1][3][1]++;
				}
				else
				GivePlayerItem(param1, "weapon_flashbang");
				
				ClientCredits[param1]--;
				if(!NewItem[param1])
				{
					NewItem[param1] = true;
					ResetRebuy(param1);
				}
				LastEquipmentItem[param1][2] = LastEquipmentItem[param1][2] + 1;
			}
			else if(param2 == 3 && ClientCredits[param1] > 0 && hegrenade_cost != -1)
			{
				if(PlayerisProtected[param1])
				{
					PrintToChat(param1, "[SM] %t", "bought_item", "HE Grenade");
					PlayerItems[param1][4][0] = GetWeaponidByName("weapon_hegrenade");
					PlayerItems[param1][4][1]++;
				}
				else
				GivePlayerItem(param1, "weapon_hegrenade");
				
				ClientCredits[param1]--;
				if(!NewItem[param1])
				{
					NewItem[param1] = true;
					ResetRebuy(param1);
				}
				LastEquipmentItem[param1][3] = LastEquipmentItem[param1][3] + 1;
			}
			else if(param2 == 4 && ClientCredits[param1] > 0 && smokegrenade_cost != -1)
			{
				if(PlayerisProtected[param1])
				{
					PrintToChat(param1, "[SM] %t", "bought_item", "Smoke Grenade");
					PlayerItems[param1][5][0] = GetWeaponidByName("weapon_smokegrenade");
					PlayerItems[param1][5][1]++;
				}
				else
				GivePlayerItem(param1, "weapon_smokegrenade");
				
				ClientCredits[param1]--;
				if(!NewItem[param1])
				{
					NewItem[param1] = true;
					ResetRebuy(param1);
				}
				LastEquipmentItem[param1][4] = LastEquipmentItem[param1][4] + 1;
			}
			else if(param2 == 5 && ClientCredits[param1] > 0 && nvgoggles != -1)
			{
				SetEntProp(param1, Prop_Send, "m_bHasNightVision", 1, 1);
				SetClientMoney(param1, ClientCash - 1250);
				if(!NewItem[param1])
				{
					NewItem[param1] = true;
					ResetRebuy(param1);
				}
				LastEquipmentItem[param1][5] = 1; 
			}
			else
			PrintCenterText(param1, "%t", "money");
			
			if(buymenucont[param1])
				Buy_Equipment_Control(param1, 0);
		}
		else if(ClientTeam == TEAM_CT)
		{
			if(param2 == 0 && ClientCash >= kevlar && kevlar != -1)
			{
				SetEntProp(param1, Prop_Send, "m_ArmorValue", 100, 1);
				SetClientMoney(param1, ClientCash - kevlar);
				if(!NewItem[param1])
				{
					NewItem[param1] = true;
					ResetRebuy(param1);
				}
				LastEquipmentItem[param1][0] = 1;
			}
			else if(param2 == 1 && ClientCash >= kevlarhelmet && kevlarhelmet != -1)
			{
				if(GetEntData(param1, helmet) == 1 && GetEntData(param1, armor) == 100)
				{
					PrintCenterText(param1, "You already have a kevlar and helmet!");
				}
				else if(GetEntData(param1, armor) == 100 && GetEntData(param1, helmet) == 0)
				{
					SetEntProp(param1, Prop_Send, "m_bHasHelmet", 1, 1);
					SetClientMoney(param1, ClientCash - helmet_cost);
				}
				else if(GetEntData(param1, helmet) == 0 && GetEntData(param1, armor) < 100)
				{
					SetEntProp(param1, Prop_Send, "m_ArmorValue", 100, 1);
					SetEntProp(param1, Prop_Send, "m_bHasHelmet", 1, 1);
					SetClientMoney(param1, ClientCash - kevlarhelmet);
				}
				else if(GetEntData(param1, helmet) == 1 && GetEntData(param1, armor) < 100)
				{
					SetEntProp(param1, Prop_Send, "m_ArmorValue", 100, 1);
					SetClientMoney(param1, ClientCash - kevlar);
				}
				if(!NewItem[param1])
				{
					NewItem[param1] = true;
					ResetRebuy(param1);
				}
				LastEquipmentItem[param1][1] = 1;
			}
			else if(param2 == 2 && ClientCash >= flashbang_cost && flashbang_cost != -1)
			{
				if(PlayerisProtected[param1])
				{
					PrintToChat(param1, "[SM] %t", "bought_item", "Flashbang Grenade");
					PlayerItems[param1][3][0] = GetWeaponidByName("weapon_flashbang");
					PlayerItems[param1][3][1]++;
				}
				else
				GivePlayerItem(param1, "weapon_flashbang");
				
				SetClientMoney(param1, ClientCash - flashbang_cost);
				if(!NewItem[param1])
				{
					NewItem[param1] = true;
					ResetRebuy(param1);
				}
				LastEquipmentItem[param1][2] = LastEquipmentItem[param1][2] + 1;
			}
			else if(param2 == 3 && ClientCash >= hegrenade_cost && hegrenade_cost != -1)
			{
				if(PlayerisProtected[param1])
				{
					PrintToChat(param1, "[SM] %t", "bought_item", "HE Grenade");
					PlayerItems[param1][4][0] = GetWeaponidByName("weapon_hegrenade");
					PlayerItems[param1][4][1]++;
				}
				else
				GivePlayerItem(param1, "weapon_hegrenade");
				
				SetClientMoney(param1, ClientCash - hegrenade_cost);
				if(!NewItem[param1])
				{
					NewItem[param1] = true;
					ResetRebuy(param1);
				}
				LastEquipmentItem[param1][3] = LastEquipmentItem[param1][3] + 1;
			}
			else if(param2 == 4 && ClientCash >= smokegrenade_cost && smokegrenade_cost != -1)
			{
				if(PlayerisProtected[param1])
				{
					PrintToChat(param1, "[SM] %t", "bought_item", "Smoke Grenade");
					PlayerItems[param1][5][0] = GetWeaponidByName("weapon_smokegrenade");
					PlayerItems[param1][5][1]++;
				}
				else
				GivePlayerItem(param1, "weapon_smokegrenade");
				
				SetClientMoney(param1, ClientCash - smokegrenade_cost);
				if(!NewItem[param1])
				{
					NewItem[param1] = true;
					ResetRebuy(param1);
				}
				LastEquipmentItem[param1][4] = LastEquipmentItem[param1][4] + 1;
			}
			else if(param2 == 5 && ClientCash >= defusekit)
			{
				SetEntProp(param1, Prop_Send, "m_bHasDefuser", 1, 1);
				SetClientMoney(param1, ClientCash - defusekit && defusekit != -1);
				if(!NewItem[param1])
				{
					NewItem[param1] = true;
					ResetRebuy(param1);
				}
				LastEquipmentItem[param1][5] = 1;
				
			}
			else if(param2 == 6 && ClientCash >= nvgoggles && nvgoggles != -1)
			{
				SetEntProp(param1, Prop_Send, "m_bHasNightVision", 1, 1);
				SetClientMoney(param1, ClientCash - 1250);
				if(!NewItem[param1])
				{
					NewItem[param1] = true;
					ResetRebuy(param1);
				}
				LastEquipmentItem[param1][6] = 1;
			}
			else if(param2 == 0 && ClientCredits[param1] > 0 && kevlar != -1)
			{
				SetEntProp(param1, Prop_Send, "m_ArmorValue", 100, 1);
				SetClientMoney(param1, ClientCash - nvgoggles);
				if(!NewItem[param1])
				{
					NewItem[param1] = true;
					ResetRebuy(param1);
				}
				LastEquipmentItem[param1][0] = 1;
			}
			else if(param2 == 1 && ClientCredits[param1] > 0 && kevlarhelmet != -1)
			{
				if(GetEntData(param1, helmet) == 1 && GetEntData(param1, armor) == 100)
				{
					PrintCenterText(param1, "You already have a kevlar and helmet!");
				}
				else if(GetEntData(param1, armor) == 100 && GetEntData(param1, helmet) == 0)
				{
					SetEntProp(param1, Prop_Send, "m_bHasHelmet", 1, 1);
					ClientCredits[param1]--;
				}
				else if(GetEntData(param1, helmet) == 0 && GetEntData(param1, armor) < 100)
				{
					SetEntProp(param1, Prop_Send, "m_ArmorValue", 100, 1);
					SetEntProp(param1, Prop_Send, "m_bHasHelmet", 1, 1);
					ClientCredits[param1]--;
				}
				else if(GetEntData(param1, helmet) == 1 && GetEntData(param1, armor) < 100)
				{
					SetEntProp(param1, Prop_Send, "m_ArmorValue", 100, 1);
					ClientCredits[param1]--;
				}
				if(!NewItem[param1])
				{
					NewItem[param1] = true;
					ResetRebuy(param1);
				}
				LastEquipmentItem[param1][1] = 1;
			}
			else if(param2 == 2 && ClientCredits[param1] > 0 && flashbang_cost != -1)
			{
				if(PlayerisProtected[param1])
				{
					PrintToChat(param1, "[SM] %t", "bought_item", "Flashbang Grenade");
					PlayerItems[param1][3][0] = GetWeaponidByName("weapon_flashbang");
					PlayerItems[param1][3][1]++;
				}
				else
				GivePlayerItem(param1, "weapon_flashbang");
				
				ClientCredits[param1]--;
				if(!NewItem[param1])
				{
					NewItem[param1] = true;
					ResetRebuy(param1);
				}
				LastEquipmentItem[param1][2] = LastEquipmentItem[param1][2] + 1;
			}
			else if(param2 == 3 && ClientCredits[param1] > 0 && hegrenade_cost != -1)
			{
				if(PlayerisProtected[param1])
				{
					PrintToChat(param1, "[SM] %t", "bought_item", "HE Grenade");
					PlayerItems[param1][4][0] = GetWeaponidByName("weapon_hegrenade");
					PlayerItems[param1][4][1]++;
				}
				else
				GivePlayerItem(param1, "weapon_hegrenade");
				
				ClientCredits[param1]--;
				if(!NewItem[param1])
				{
					NewItem[param1] = true;
					ResetRebuy(param1);
				}
				LastEquipmentItem[param1][3] = LastEquipmentItem[param1][3] + 1;
			}
			else if(param2 == 4 && ClientCredits[param1] > 0 && smokegrenade_cost != -1)
			{
				if(PlayerisProtected[param1])
				{
					PrintToChat(param1, "[SM] %t", "bought_item", "Smoke Grenade");
					PlayerItems[param1][5][0] = GetWeaponidByName("weapon_smokegrenade");
					PlayerItems[param1][5][1]++;
				}
				else
				GivePlayerItem(param1, "weapon_smokegrenade");
				
				ClientCredits[param1]--;
				if(!NewItem[param1])
				{
					NewItem[param1] = true;
					ResetRebuy(param1);
				}
				LastEquipmentItem[param1][4] = LastEquipmentItem[param1][4] + 1;
			}
			else if(param2 == 5 && ClientCredits[param1] > 0 && defusekit != -1)
			{
				SetEntProp(param1, Prop_Send, "m_bHasDefuser", 1, 1);
				ClientCredits[param1]--;
				if(!NewItem[param1])
				{
					NewItem[param1] = true;
					ResetRebuy(param1);
				}
				LastEquipmentItem[param1][5] = 1;
				
			}
			else if(param2 == 6 && ClientCredits[param1] > 0 && nvgoggles != -1)
			{
				SetEntProp(param1, Prop_Send, "m_bHasNightVision", 1, 1);
				ClientCredits[param1]--;
				if(!NewItem[param1])
				{
					NewItem[param1] = true;
					ResetRebuy(param1);
				}
				LastEquipmentItem[param1][6] = 1;
			}
			else
			PrintCenterText(param1, "%t", "money");
			
			if(buymenucont[param1])
				Buy_Equipment_Control(param1, 0);
			
		}
		if(firstjoin[param1])
		{
			firstjoin[param1] = false;
			PrintToChat(param1, "[SM] %t",  "buymenu_chat");
			PrintToChat(param1, "[SM] %t",  "buybind_chat");
		}
	}
	if(action == MenuAction_Cancel)
	{
		if(param2 == MenuCancel_Exit || param2 == MenuCancel_Timeout)
		{
			PrintToChat(param1, "[SM] %t",  "buymenu_chat");
		}
	}
	if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}



public Buy_Equipment_Control(client, args)
{
	new String:buffer[32], String:buffer2[32], String:buffer3[32], String:buffer4[32], String:buffer5[32],
	String:buffer6[32], String:buffer7[32], String:buffer8[32];
	new ClientTeam = GetClientTeam(client);
	new Handle:menu = CreateMenu(Equip_Menu);
	Format(buffer, sizeof(buffer), "%T", "equip_menu", LANG_SERVER);
	
	if(kevlar != -1)
		Format(buffer2, sizeof(buffer2), "kevlar: $%d", kevlar);
	else
	Format(buffer2, sizeof(buffer2), "kevlar: %T", "restrict", LANG_SERVER);
	if(kevlarhelmet != -1)
		Format(buffer3, sizeof(buffer3), "kevlar & helmet: $%d", kevlarhelmet);
	else
	Format(buffer3, sizeof(buffer3), "kevlar & helmet: %T", "restrict", LANG_SERVER);
	if(flashbang_cost != -1)
		Format(buffer4, sizeof(buffer4), "flashbang: $%d", flashbang_cost);
	else
	Format(buffer4, sizeof(buffer4), "flashbang: %T", "restrict", LANG_SERVER);
	if(hegrenade_cost != -1)
		Format(buffer5, sizeof(buffer5), "HEgrenade: $%d", hegrenade_cost);
	else
	Format(buffer5, sizeof(buffer5), "HEgrenade: %T", "restrict", LANG_SERVER);
	if(smokegrenade_cost != -1)
		Format(buffer6, sizeof(buffer6), "smokegrenade: $%d", smokegrenade_cost);
	else
	Format(buffer6, sizeof(buffer6), "smokegrenade: $%d", smokegrenade_cost);
	if(defusekit != -1)
		Format(buffer7, sizeof(buffer7), "defuse kit: %T", "restrict", LANG_SERVER);
	if(nvgoggles != -1)
		Format(buffer8, sizeof(buffer8), "nightvision goggles: $%d", nvgoggles);
	else
	Format(buffer8, sizeof(buffer8), "nightvision goggles: %T", "restrict", LANG_SERVER);
	
	SetMenuTitle(menu, buffer);
	if(ClientTeam == TEAM_T)
	{
		AddMenuItem(menu, buffer2, buffer2);
		AddMenuItem(menu, buffer3, buffer3);
		AddMenuItem(menu, buffer4, buffer4);
		AddMenuItem(menu, buffer5, buffer5);
		AddMenuItem(menu, buffer6, buffer6);
		AddMenuItem(menu, buffer8, buffer8);
	}
	else if(ClientTeam == TEAM_CT)
	{
		AddMenuItem(menu, buffer2, buffer2);
		AddMenuItem(menu, buffer3, buffer3);
		AddMenuItem(menu, buffer4, buffer4);
		AddMenuItem(menu, buffer5, buffer5);
		AddMenuItem(menu, buffer6, buffer6);
		AddMenuItem(menu, buffer7, buffer7);
		AddMenuItem(menu, buffer8, buffer8);
	}
	
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
	
}	

public GunsMenu(Handle:menu, MenuAction:action, param1, param2)
{
	/* If an option was selected, tell the client about the item. */
	if (action == MenuAction_Select)
	{
		new weaponid = GetPlayerWeaponSlot(param1, 0);
		new String:weaponname[32];
		new ClientCash = GetClientMoney(param1);
		if(param2 == 0 && ClientCash >= m3_cost && m3_cost != -1)
		{			
			if(weaponid != -1)
			{
				
				GetEdictClassname(weaponid, weaponname, sizeof(weaponname));
				if(!StrEqual(weaponname, "weapon_m3", false))
					RemovePlayerItem(param1, weaponid);
				else
				PrintCenterText(param1, "%t", "item_owned");
				
			}
			if(GetWeaponidByName("weapon_m3") != PlayerItems[param1][0][0])
			{
				if(PlayerisProtected[param1])
				{
					PrintToChat(param1, "[SM] %t", "bought_item", "shotgun");
					PlayerItems[param1][0][0] = GetWeaponidByName("weapon_m3");
					PlayerItems[param1][0][1] = 1;
				}
				else if(!StrEqual(weaponname, "weapon_m3", false))
				{
					SetClientMoney(param1, ClientCash - m3_cost);
					GivePlayerItem(param1, "weapon_m3");
					GivePlayerItem(param1, weaponname);
				
					if(!NewItem[param1])
					{
						NewItem[param1] = true;
						ResetRebuy(param1);
					}
					LastPrimaryWeapon[param1] = 0;
				}
			}
			else
			PrintCenterText(param1, "%t", "item_owned");
		}
		else if(param2 == 1 && ClientCash >= xm1014_cost && xm1014_cost != -1)
		{			
			if(weaponid != -1)
			{
				
				GetEdictClassname(weaponid, weaponname, sizeof(weaponname));
				if(!StrEqual(weaponname, "weapon_xm1014", false))
					RemovePlayerItem(param1, weaponid);
				else
				PrintCenterText(param1, "%t", "item_owned");
			}
			
			if(GetWeaponidByName("weapon_xm1014") != PlayerItems[param1][0][0])
			{
				if(PlayerisProtected[param1])
				{
					PrintToChat(param1, "[SM] %t", "bought_item", "auto shotgun");
					PlayerItems[param1][0][0] = GetWeaponidByName("weapon_xm1014");
					PlayerItems[param1][0][1] = 1;
				}
				
				else if(!StrEqual(weaponname, "weapon_xm1014", false))
				{
					SetClientMoney(param1, ClientCash - xm1014_cost);
					GivePlayerItem(param1, "weapon_xm1014");
					GivePlayerItem(param1, weaponname);
					
					if(!NewItem[param1])
					{
						NewItem[param1] = true;
						ResetRebuy(param1);
					}
					LastPrimaryWeapon[param1] = 1;
				}
			}
			else
			PrintCenterText(param1, "%t", "item_owned");
		}
		else if(param2 == 2 && ClientCash >= tmp_cost && tmp_cost != -1)
		{			
			if(weaponid != -1)
			{
				
				GetEdictClassname(weaponid, weaponname, sizeof(weaponname));
				if(!StrEqual(weaponname, "weapon_tmp", false))
					RemovePlayerItem(param1, weaponid);
				else
				PrintCenterText(param1, "%t", "item_owned");
				
			}
			
			if(GetWeaponidByName("weapon_tmp") != PlayerItems[param1][0][0])
			{
				if(PlayerisProtected[param1])
				{
					PrintToChat(param1, "[SM] %t", "bought_item", "tmp");
					PlayerItems[param1][0][0] = GetWeaponidByName("weapon_tmp");
					PlayerItems[param1][0][1] = 1;
				}

				else if(!StrEqual(weaponname, "weapon_tmp", false))
				{
					SetClientMoney(param1, ClientCash - tmp_cost);
					GivePlayerItem(param1, "weapon_tmp");
					GivePlayerItem(param1, weaponname);
					
					if(!NewItem[param1])
					{
						NewItem[param1] = true;
						ResetRebuy(param1);
					}
					LastPrimaryWeapon[param1] = 2;
				}
			}
			else
			PrintCenterText(param1, "%t", "item_owned");
		}
		else if(param2 == 3 && ClientCash >= mac10_cost && mac10_cost != -1)
		{			
			if(weaponid != -1)
			{
				
				GetEdictClassname(weaponid, weaponname, sizeof(weaponname));
				if(!StrEqual(weaponname, "weapon_mac10", false))
					RemovePlayerItem(param1, weaponid);
				else
				PrintCenterText(param1, "%t", "item_owned");
				
			}
			
			if(GetWeaponidByName("weapon_mac10") != PlayerItems[param1][0][0])
			{
				if(PlayerisProtected[param1])
				{
					PrintToChat(param1, "[SM] %t", "bought_item", "mac10");
					PlayerItems[param1][0][0] = GetWeaponidByName("weapon_mac10");
					PlayerItems[param1][0][1] = 1;
				}
				
				else if(!StrEqual(weaponname, "weapon_mac10", false))
				{
					SetClientMoney(param1, ClientCash - mac10_cost);
					GivePlayerItem(param1, "weapon_mac10");
					GivePlayerItem(param1, weaponname);
					
					if(!NewItem[param1])
					{
						NewItem[param1] = true;
						ResetRebuy(param1);
					}
					LastPrimaryWeapon[param1] = 3;
				}
			}
			else
			PrintCenterText(param1, "%t", "item_owned");
		}
		else if(param2 == 4 && ClientCash >= mp5navy_cost && mp5navy_cost != -1)
		{
			if(weaponid != -1)
			{
				
				
				GetEdictClassname(weaponid, weaponname, sizeof(weaponname));
				if(!StrEqual(weaponname, "weapon_mp5navy", false))
					RemovePlayerItem(param1, weaponid);
				else
				PrintCenterText(param1, "%t", "item_owned");
				
			}
			
			if(GetWeaponidByName("weapon_mp5navy") != PlayerItems[param1][0][0])
			{
				if(PlayerisProtected[param1])
				{
					PrintToChat(param1, "[SM] %t", "bought_item", "mp5navy");
					PlayerItems[param1][0][0] = GetWeaponidByName("weapon_mp5navy");
					PlayerItems[param1][0][1] = 1;
				}
				
				else if(!StrEqual(weaponname, "weapon_mp5navy", false))
				{
					SetClientMoney(param1, ClientCash - mp5navy_cost);
					GivePlayerItem(param1, "weapon_mp5navy");
					GivePlayerItem(param1, weaponname);
					
					if(!NewItem[param1])
					{
						NewItem[param1] = true;
						ResetRebuy(param1);
					}
					LastPrimaryWeapon[param1] = 4;
				}
			}
			else
			PrintCenterText(param1, "%t", "item_owned");
		}
		else if(param2 == 5 && ClientCash >= ump45_cost && ump45_cost != -1)
		{
			if(weaponid != -1)
			{
				
				GetEdictClassname(weaponid, weaponname, sizeof(weaponname));
				if(!StrEqual(weaponname, "weapon_ump45", false))
					RemovePlayerItem(param1, weaponid);
				else
				PrintCenterText(param1, "%t", "item_owned");
				
			}
			
			if(GetWeaponidByName("weapon_ump45") != PlayerItems[param1][0][0])
			{
				if(PlayerisProtected[param1])
				{
					PrintToChat(param1, "[SM] %t", "bought_item", "ump45");
					PlayerItems[param1][0][0] = GetWeaponidByName("weapon_ump45");
					PlayerItems[param1][0][1] = 1;
				}

				
				else if(!StrEqual(weaponname, "weapon_ump45", false))
				{
					SetClientMoney(param1, ClientCash - ump45_cost);
					GivePlayerItem(param1, "weapon_ump45");
					GivePlayerItem(param1, weaponname);
					
					if(!NewItem[param1])
					{
						NewItem[param1] = true;
						ResetRebuy(param1);
					}
					LastPrimaryWeapon[param1] = 5;
				}
			}
			else
			PrintCenterText(param1, "%t", "item_owned");
		}
		else if(param2 == 6 && ClientCash >= p90_cost && p90_cost != -1)
		{
			if(weaponid != -1)
			{
				
				GetEdictClassname(weaponid, weaponname, sizeof(weaponname));
				if(!StrEqual(weaponname, "weapon_p90", false))
					RemovePlayerItem(param1, weaponid);
				else
				PrintCenterText(param1, "%t", "item_owned");
				
			}
			
			if(GetWeaponidByName("weapon_p90") != PlayerItems[param1][0][0])
			{
				if(PlayerisProtected[param1])
				{
					PrintToChat(param1, "[SM] %t", "bought_item", "p90");
					PlayerItems[param1][0][0] = GetWeaponidByName("weapon_p90");
					PlayerItems[param1][0][1] = 1;
				}
				
				else if(!StrEqual(weaponname, "weapon_p90", false))
				{
					SetClientMoney(param1, ClientCash - p90_cost);
					GivePlayerItem(param1, "weapon_p90");
					GivePlayerItem(param1, weaponname);
					
					if(!NewItem[param1])
					{
						NewItem[param1] = true;
						ResetRebuy(param1);
					}
					LastPrimaryWeapon[param1] = 6;
				}
			}
			else
			PrintCenterText(param1, "%t", "item_owned");
		}
		else if(param2 == 7 && ClientCash >= galil_cost && galil_cost != -1)
		{
			if(weaponid != -1)
			{
				
				GetEdictClassname(weaponid, weaponname, sizeof(weaponname));
				if(!StrEqual(weaponname, "weapon_galil", false))
					RemovePlayerItem(param1, weaponid);
				else
				PrintCenterText(param1, "%t", "item_owned");
				
			}
			
			if(GetWeaponidByName("weapon_galil") != PlayerItems[param1][0][0])
			{
				if(PlayerisProtected[param1])
				{
					PrintToChat(param1, "[SM] %t", "bought_item", "galil");
					PlayerItems[param1][0][0] = GetWeaponidByName("weapon_galil");
					PlayerItems[param1][0][1] = 1;
				}
				
				else if(!StrEqual(weaponname, "weapon_galil", false))
				{
					SetClientMoney(param1, ClientCash - galil_cost);
					GivePlayerItem(param1, "weapon_galil");
					GivePlayerItem(param1, weaponname);
					
					if(!NewItem[param1])
					{
						NewItem[param1] = true;
						ResetRebuy(param1);
					}
					LastPrimaryWeapon[param1] = 7;
				}
			}
			else
			PrintCenterText(param1, "%t", "item_owned");
		}
		else if(param2 == 8 && ClientCash >= famas_cost && famas_cost != -1)
		{
			if(weaponid != -1)
			{
				
				GetEdictClassname(weaponid, weaponname, sizeof(weaponname));
				if(!StrEqual(weaponname, "weapon_famas", false))
					RemovePlayerItem(param1, weaponid);
				else
				PrintCenterText(param1, "%t", "item_owned");
				
			}
			
			if(GetWeaponidByName("weapon_famas") != PlayerItems[param1][0][0])
			{
				if(PlayerisProtected[param1])
				{
					PrintToChat(param1, "[SM] %t", "bought_item", "famas");
					PlayerItems[param1][0][0] = GetWeaponidByName("weapon_famas");
					PlayerItems[param1][0][1] = 1;
				}
				
				else if(!StrEqual(weaponname, "weapon_famas", false))
				{
					SetClientMoney(param1, ClientCash - famas_cost);
					GivePlayerItem(param1, "weapon_famas");
					GivePlayerItem(param1, weaponname);
					
					if(!NewItem[param1])
					{
						NewItem[param1] = true;
						ResetRebuy(param1);
					}
					LastPrimaryWeapon[param1] = 8;
				}
			}
			else
			PrintCenterText(param1, "%t", "item_owned");
		}
		else if(param2 == 9 && ClientCash >= ak47_cost && ak47_cost != -1)
		{
			if(weaponid != -1)
			{
				
				GetEdictClassname(weaponid, weaponname, sizeof(weaponname));
				if(!StrEqual(weaponname, "weapon_ak47", false))
					RemovePlayerItem(param1, weaponid);
				else
				PrintCenterText(param1, "%t", "item_owned");
				
			}
			
			if(GetWeaponidByName("weapon_ak47") != PlayerItems[param1][0][0])
			{
				if(PlayerisProtected[param1])
				{
					PrintToChat(param1, "[SM] %t", "bought_item", "ak47");
					PlayerItems[param1][0][0] = GetWeaponidByName("weapon_ak47");
					PlayerItems[param1][0][1] = 1;
				}
				
				else if(!StrEqual(weaponname, "weapon_ak47", false))
				{
					SetClientMoney(param1, ClientCash - ak47_cost);
					GivePlayerItem(param1, "weapon_ak47");
					GivePlayerItem(param1, weaponname);
					
					if(!NewItem[param1])
					{
						NewItem[param1] = true;
						ResetRebuy(param1);
					}
					LastPrimaryWeapon[param1] = 9;
				}
			}
			else
			PrintCenterText(param1, "%t", "item_owned");
		}
		else if(param2 == 10 && ClientCash >= scout_cost && scout_cost != -1)
		{
			if(weaponid != -1)
			{
				
				GetEdictClassname(weaponid, weaponname, sizeof(weaponname));
				if(!StrEqual(weaponname, "weapon_scout", false))
					RemovePlayerItem(param1, weaponid);
				else
				PrintCenterText(param1, "%t", "item_owned");
				
			}
			
			if(GetWeaponidByName("weapon_scout") != PlayerItems[param1][0][0])
			{
				if(PlayerisProtected[param1])
				{
					PrintToChat(param1, "[SM] %t", "bought_item", "scout");
					PlayerItems[param1][0][0] = GetWeaponidByName("weapon_scout");
					PlayerItems[param1][0][1] = 1;
				}
				
				else if(!StrEqual(weaponname, "weapon_scout", false))
				{
					SetClientMoney(param1, ClientCash - scout_cost);
					GivePlayerItem(param1, "weapon_scout");
					GivePlayerItem(param1, weaponname);
					
					if(!NewItem[param1])
					{
						NewItem[param1] = true;
						ResetRebuy(param1);
					}
					LastPrimaryWeapon[param1] = 10;
				}
			}
			else
			PrintCenterText(param1, "%t", "item_owned");
		}
		else if(param2 == 11 && ClientCash >= m4a1_cost && m4a1_cost != -1)
		{
			if(weaponid != -1)
			{
				
				GetEdictClassname(weaponid, weaponname, sizeof(weaponname));
				if(!StrEqual(weaponname, "weapon_m4a1", false))
					RemovePlayerItem(param1, weaponid);
				else
				PrintCenterText(param1, "%t", "item_owned");
				
			}
			
			if(GetWeaponidByName("weapon_m4a1") != PlayerItems[param1][0][0])
			{
				if(PlayerisProtected[param1])
				{
					PrintToChat(param1, "[SM] %t", "bought_item", "m4a1");
					PlayerItems[param1][0][0] = GetWeaponidByName("weapon_m4a1");
					PlayerItems[param1][0][1] = 1;
				}
				
				else if(!StrEqual(weaponname, "weapon_m4a1", false))
				{
					SetClientMoney(param1, ClientCash - m4a1_cost);
					GivePlayerItem(param1, "weapon_m4a1");
					GivePlayerItem(param1, weaponname);
					
					if(!NewItem[param1])
					{
						NewItem[param1] = true;
						ResetRebuy(param1);
					}
					LastPrimaryWeapon[param1] = 11;
				}
			}
			else
			PrintCenterText(param1, "%t", "item_owned");
		}
		else if(param2 == 12 && ClientCash >= aug_cost && aug_cost != -1)
		{
			if(weaponid != -1)
			{
				
				GetEdictClassname(weaponid, weaponname, sizeof(weaponname));
				if(!StrEqual(weaponname, "weapon_aug", false))
					RemovePlayerItem(param1, weaponid);
				else
				PrintCenterText(param1, "%t", "item_owned");
			}
			
			if(GetWeaponidByName("weapon_aug") != PlayerItems[param1][0][0])
			{
				if(PlayerisProtected[param1])
				{
					PrintToChat(param1, "[SM] %t", "bought_item", "aug");
					PlayerItems[param1][0][0] = GetWeaponidByName("weapon_aug");
					PlayerItems[param1][0][1] = 1;
				}
				
				else if(!StrEqual(weaponname, "weapon_aug", false))
				{
					SetClientMoney(param1, ClientCash - aug_cost);
					GivePlayerItem(param1, "weapon_aug");
					GivePlayerItem(param1, weaponname);
					
					if(!NewItem[param1])
					{
						NewItem[param1] = true;
						ResetRebuy(param1);
					}
					LastPrimaryWeapon[param1] = 12;
				}
			}
			else
			PrintCenterText(param1, "%t", "item_owned");
		}
		else if(param2 == 13 && ClientCash >= sg552_cost && sg552_cost != -1)
		{
			if(weaponid != -1)
			{
				
				GetEdictClassname(weaponid, weaponname, sizeof(weaponname));
				if(!StrEqual(weaponname, "weapon_sg552", false))
					RemovePlayerItem(param1, weaponid);
				else
				PrintCenterText(param1, "%t", "item_owned");
				
			}
			
			if(GetWeaponidByName("weapon_sg552") != PlayerItems[param1][0][0])
			{
				if(PlayerisProtected[param1])
				{
					PrintToChat(param1, "[SM] %t", "bought_item", "sg552");
					PlayerItems[param1][0][0] = GetWeaponidByName("weapon_sg552");
					PlayerItems[param1][0][1] = 1;
				}
				
				else if(!StrEqual(weaponname, "weapon_sg552", false))
				{
					SetClientMoney(param1, ClientCash - sg552_cost);
					GivePlayerItem(param1, "weapon_sg552");
					GivePlayerItem(param1, weaponname);
					
					if(!NewItem[param1])
					{
						NewItem[param1] = true;
						ResetRebuy(param1);
					}
					LastPrimaryWeapon[param1] = 13;
				}
			}
			else
			PrintCenterText(param1, "%t", "item_owned");
		}
		else if(param2 == 14 && ClientCash >= sg550_cost && sg550_cost != -1)
		{
			if(weaponid != -1)
			{
				
				GetEdictClassname(weaponid, weaponname, sizeof(weaponname));
				if(!StrEqual(weaponname, "weapon_sg550", false))
					RemovePlayerItem(param1, weaponid);
				else
				PrintCenterText(param1, "%t", "item_owned");
				
			}
			
			if(GetWeaponidByName("weapon_sg550") != PlayerItems[param1][0][0])
			{
				if(PlayerisProtected[param1])
				{
					PrintToChat(param1, "[SM] %t", "bought_item", "sg550");
					PlayerItems[param1][0][0] = GetWeaponidByName("weapon_sg550");
					PlayerItems[param1][0][1] = 1;
				}
				
				else if(!StrEqual(weaponname, "weapon_sg550", false))
				{
					SetClientMoney(param1, ClientCash - sg550_cost);
					GivePlayerItem(param1, "weapon_sg550");
					GivePlayerItem(param1, weaponname);
					
					if(!NewItem[param1])
					{
						NewItem[param1] = true;
						ResetRebuy(param1);
					}
					LastPrimaryWeapon[param1] = 14;
				}
			}
			else
			PrintCenterText(param1, "%t", "item_owned");
		}
		else if(param2 == 15 && ClientCash >= awp_cost && awp_cost != -1)
		{
			if(weaponid != -1)
			{
				
				GetEdictClassname(weaponid, weaponname, sizeof(weaponname));
				if(!StrEqual(weaponname, "weapon_awp", false))
					RemovePlayerItem(param1, weaponid);
				else
				PrintCenterText(param1, "%t", "item_owned");
				
			}
			
			if(GetWeaponidByName("weapon_awp") != PlayerItems[param1][0][0])
			{
				if(PlayerisProtected[param1])
				{
					PrintToChat(param1, "[SM] %t", "bought_item", "awp");
					PlayerItems[param1][0][0] = GetWeaponidByName("weapon_awp");
					PlayerItems[param1][0][1] = 1;
				}
				
				else if(!StrEqual(weaponname, "weapon_awp", false))
				{
					SetClientMoney(param1, ClientCash - awp_cost);
					GivePlayerItem(param1, "weapon_awp");
					GivePlayerItem(param1, weaponname);
					
					if(!NewItem[param1])
					{
						NewItem[param1] = true;
						ResetRebuy(param1);
					}
					LastPrimaryWeapon[param1] = 15;
				}
			}
			else
			PrintCenterText(param1, "%t", "item_owned");
		}
		else if(param2 == 16 && ClientCash >= g3sg1_cost && g3sg1_cost != -1)
		{
			if(weaponid != -1)
			{
				
				GetEdictClassname(weaponid, weaponname, sizeof(weaponname));
				if(!StrEqual(weaponname, "weapon_g3sg1", false))
					RemovePlayerItem(param1, weaponid);
				else
				PrintCenterText(param1, "%t", "item_owned");
				
			}
			
			if(GetWeaponidByName("weapon_g3sg1") != PlayerItems[param1][0][0])
			{
				if(PlayerisProtected[param1])
				{
					PrintToChat(param1, "[SM] %t", "bought_item", "g3sg1");
					PlayerItems[param1][0][0] = GetWeaponidByName("weapon_g3sg1");
					PlayerItems[param1][0][1] = 1;
				}
				
				else if(!StrEqual(weaponname, "weapon_g3sg1", false))
				{
					SetClientMoney(param1, ClientCash - g3sg1_cost);
					GivePlayerItem(param1, "weapon_g3sg1");
					GivePlayerItem(param1, weaponname);
					
					if(!NewItem[param1])
					{
						NewItem[param1] = true;
						ResetRebuy(param1);
					}
					LastPrimaryWeapon[param1] = 16;
				}
			}
			else
			PrintCenterText(param1, "%t", "item_owned");
		}
		else if(param2 == 17 && ClientCash >= m249_cost && m249_cost != -1)
		{			
			if(weaponid != -1)
			{
				
				GetEdictClassname(weaponid, weaponname, sizeof(weaponname));
				if(!StrEqual(weaponname, "weapon_m249", false))
					RemovePlayerItem(param1, weaponid);
				else
				PrintCenterText(param1, "%t", "item_owned");
				
			}
			
			if(GetWeaponidByName("weapon_m249") != PlayerItems[param1][0][0])
			{
				if(PlayerisProtected[param1])
				{
					PrintToChat(param1, "[SM] %t", "bought_item", "m249");
					PlayerItems[param1][0][0] = GetWeaponidByName("weapon_m249");
					PlayerItems[param1][0][1] = 1;
				}
				
				else if(!StrEqual(weaponname, "weapon_m249", false))
				{
					SetClientMoney(param1, ClientCash - m249_cost);
					GivePlayerItem(param1, "weapon_m249");
					GivePlayerItem(param1, weaponname);
					
					if(!NewItem[param1])
					{
						NewItem[param1] = true;
						ResetRebuy(param1);
					}
					LastPrimaryWeapon[param1] = 17;
				}
			}
			else
			PrintCenterText(param1, "%t", "item_owned");
		}
		else if(param2 == 0 && ClientCredits[param1] > 0 && m3_cost != -1)
		{
			if(weaponid != -1)
			{
				
				GetEdictClassname(weaponid, weaponname, sizeof(weaponname));
				if(!StrEqual(weaponname, "weapon_m3", false))
					RemovePlayerItem(param1, weaponid);
				else
				PrintCenterText(param1, "%t", "item_owned");
			}
			
			if(GetWeaponidByName("weapon_m3") != PlayerItems[param1][0][0])
			{
				if(PlayerisProtected[param1])
				{
					PrintToChat(param1, "[SM] %t", "bought_item", "shotgun");
					PlayerItems[param1][0][0] = GetWeaponidByName("weapon_m3");
					PlayerItems[param1][0][1] = 1;
				}
				
				else if(!StrEqual(weaponname, "weapon_m3", false))
				{
					ClientCredits[param1]--;
					GivePlayerItem(param1, "weapon_m3");
					GivePlayerItem(param1, weaponname);
					
					if(!NewItem[param1])
					{
						NewItem[param1] = true;
						ResetRebuy(param1);
					}
					LastPrimaryWeapon[param1] = 0;
				}
			}
			else
			PrintCenterText(param1, "%t", "item_owned");
		}
		else if(param2 == 1 && ClientCredits[param1] > 0 && xm1014_cost != -1)
		{			
			if(weaponid != -1)
			{
				
				GetEdictClassname(weaponid, weaponname, sizeof(weaponname));
				if(!StrEqual(weaponname, "weapon_xm1014", false))
					RemovePlayerItem(param1, weaponid);
				else
				PrintCenterText(param1, "%t", "item_owned");
			}
			
			if(GetWeaponidByName("weapon_xm1014") != PlayerItems[param1][0][0])
			{
				if(PlayerisProtected[param1])
				{
					PrintToChat(param1, "[SM] %t", "bought_item", "auto shotgun");
					PlayerItems[param1][0][0] = GetWeaponidByName("weapon_xm1014");
					PlayerItems[param1][0][1] = 1;
				}
				
				else if(!StrEqual(weaponname, "weapon_xm1014", false))
				{
					ClientCredits[param1]--;
					GivePlayerItem(param1, "weapon_xm1014");
					GivePlayerItem(param1, weaponname);
					
					if(!NewItem[param1])
					{
						NewItem[param1] = true;
						ResetRebuy(param1);
					}
					LastPrimaryWeapon[param1] = 1;
				}
			}
			else
			PrintCenterText(param1, "%t", "item_owned");
		}
		else if(param2 == 2 && ClientCredits[param1] > 0 && tmp_cost != -1)
		{			
			if(weaponid != -1)
			{
				
				GetEdictClassname(weaponid, weaponname, sizeof(weaponname));
				if(!StrEqual(weaponname, "weapon_tmp", false))
					RemovePlayerItem(param1, weaponid);
				else
				PrintCenterText(param1, "%t", "item_owned");
				
			}
			
			if(GetWeaponidByName("weapon_tmp") != PlayerItems[param1][0][0])
			{
				if(PlayerisProtected[param1])
				{
					PrintToChat(param1, "[SM] %t", "bought_item", "tmp");
					PlayerItems[param1][0][0] = GetWeaponidByName("weapon_tmp");
					PlayerItems[param1][0][1] = 1;
				}
				
				else if(!StrEqual(weaponname, "weapon_tmp", false))
				{
					ClientCredits[param1]--;
					GivePlayerItem(param1, "weapon_tmp");
					GivePlayerItem(param1, weaponname);
					
					if(!NewItem[param1])
					{
						NewItem[param1] = true;
						ResetRebuy(param1);
					}
					LastPrimaryWeapon[param1] = 2;
				}
			}
			else
			PrintCenterText(param1, "%t", "item_owned");
		}
		else if(param2 == 3 && ClientCredits[param1] > 0)
		{			
			if(weaponid != -1)
			{
				
				GetEdictClassname(weaponid, weaponname, sizeof(weaponname));
				if(!StrEqual(weaponname, "weapon_mac10", false))
					RemovePlayerItem(param1, weaponid);
				else
				PrintCenterText(param1, "%t", "item_owned");
				
			}
			
			if(GetWeaponidByName("weapon_mac10") != PlayerItems[param1][0][0])
			{
				if(PlayerisProtected[param1])
				{
					PrintToChat(param1, "[SM] %t", "bought_item", "mac10");
					PlayerItems[param1][0][0] = GetWeaponidByName("weapon_mac10");
					PlayerItems[param1][0][1] = 1;
				}
				
				else if(!StrEqual(weaponname, "weapon_mac10", false))
				{
					ClientCredits[param1]--;
					GivePlayerItem(param1, "weapon_mac10");
					GivePlayerItem(param1, weaponname);
					
					if(!NewItem[param1])
					{
						NewItem[param1] = true;
						ResetRebuy(param1);
					}
					LastPrimaryWeapon[param1] = 3;
				}
			}
			else
			PrintCenterText(param1, "%t", "item_owned");
		}
		else if(param2 == 4 && ClientCredits[param1] > 0 && mp5navy_cost != -1)
		{
			if(weaponid != -1)
			{
				
				
				GetEdictClassname(weaponid, weaponname, sizeof(weaponname));
				if(!StrEqual(weaponname, "weapon_mp5navy", false))
					RemovePlayerItem(param1, weaponid);
				else
				PrintCenterText(param1, "%t", "item_owned");
				
			}
			
			if(GetWeaponidByName("weapon_mp5navy") != PlayerItems[param1][0][0])
			{
				if(PlayerisProtected[param1])
				{
					PrintToChat(param1, "[SM] %t", "bought_item", "mp5navy");
					PlayerItems[param1][0][0] = GetWeaponidByName("weapon_mp5navy");
					PlayerItems[param1][0][1] = 1;
				}
				
				else if(!StrEqual(weaponname, "weapon_mp5navy", false))
				{
					ClientCredits[param1]--;
					GivePlayerItem(param1, "weapon_mp5navy");
					GivePlayerItem(param1, weaponname);
					
					if(!NewItem[param1])
					{
						NewItem[param1] = true;
						ResetRebuy(param1);
					}
					LastPrimaryWeapon[param1] = 4;
				}
			}
			else
			PrintCenterText(param1, "%t", "item_owned");
		}
		else if(param2 == 5 && ClientCredits[param1] > 0 && ump45_cost != -1)
		{
			if(weaponid != -1)
			{
				
				GetEdictClassname(weaponid, weaponname, sizeof(weaponname));
				if(!StrEqual(weaponname, "weapon_ump45", false))
					RemovePlayerItem(param1, weaponid);
				else
				PrintCenterText(param1, "%t", "item_owned");
				
			}
			
			if(GetWeaponidByName("weapon_ump45") != PlayerItems[param1][0][0])
			{
				if(PlayerisProtected[param1])
				{
					PrintToChat(param1, "[SM] %t", "bought_item", "ump45");
					PlayerItems[param1][0][0] = GetWeaponidByName("weapon_ump45");
					PlayerItems[param1][0][1] = 1;
				}
				
				else if(!StrEqual(weaponname, "weapon_ump45", false))
				{
					ClientCredits[param1]--;
					GivePlayerItem(param1, "weapon_ump45");
					GivePlayerItem(param1, weaponname);
					
					if(!NewItem[param1])
					{
						NewItem[param1] = true;
						ResetRebuy(param1);
					}
					LastPrimaryWeapon[param1] = 5;
				}
			}
			else
			PrintCenterText(param1, "%t", "item_owned");
		}
		else if(param2 == 6 && ClientCredits[param1] > 0 && p90_cost != -1)
		{
			if(weaponid != -1)
			{
				
				GetEdictClassname(weaponid, weaponname, sizeof(weaponname));
				if(!StrEqual(weaponname, "weapon_p90", false))
					RemovePlayerItem(param1, weaponid);
				else
				PrintCenterText(param1, "%t", "item_owned");
				
			}
			
			if(GetWeaponidByName("weapon_p90") != PlayerItems[param1][0][0])
			{
				if(PlayerisProtected[param1])
				{
					PrintToChat(param1, "[SM] %t", "bought_item", "p90");
					PlayerItems[param1][0][0] = GetWeaponidByName("weapon_p90");
					PlayerItems[param1][0][1] = 1;
				}
				
				else if(!StrEqual(weaponname, "weapon_p90", false))
				{
					ClientCredits[param1]--;
					GivePlayerItem(param1, "weapon_p90");
					GivePlayerItem(param1, weaponname);
					
					if(!NewItem[param1])
					{
						NewItem[param1] = true;
						ResetRebuy(param1);
					}
					LastPrimaryWeapon[param1] = 6;
				}
			}
			else
			PrintCenterText(param1, "%t", "item_owned");
		}
		else if(param2 == 7 && ClientCredits[param1] > 0 && galil_cost != -1)
		{
			if(weaponid != -1)
			{
				
				GetEdictClassname(weaponid, weaponname, sizeof(weaponname));
				if(!StrEqual(weaponname, "weapon_galil", false))
					RemovePlayerItem(param1, weaponid);
				else
				PrintCenterText(param1, "%t", "item_owned");
				
			}
			
			if(GetWeaponidByName("weapon_galil") != PlayerItems[param1][0][0])
			{
				if(PlayerisProtected[param1])
				{
					PrintToChat(param1, "[SM] %t", "bought_item", "galil");
					PlayerItems[param1][0][0] = GetWeaponidByName("weapon_galil");
					PlayerItems[param1][0][1] = 1;
				}
				
				else if(!StrEqual(weaponname, "weapon_galil", false))
				{
					ClientCredits[param1]--;
					GivePlayerItem(param1, "weapon_galil");
					GivePlayerItem(param1, weaponname);
					
					if(!NewItem[param1])
					{
						NewItem[param1] = true;
						ResetRebuy(param1);
					}
					LastPrimaryWeapon[param1] = 7;
				}
			}
			else
			PrintCenterText(param1, "%t", "item_owned");
		}
		else if(param2 == 8 && ClientCredits[param1] > 0 && famas_cost != -1)
		{
			if(weaponid != -1)
			{
				
				GetEdictClassname(weaponid, weaponname, sizeof(weaponname));
				if(!StrEqual(weaponname, "weapon_famas", false))
					RemovePlayerItem(param1, weaponid);
				else
				PrintCenterText(param1, "%t", "item_owned");
				
			}
			
			if(GetWeaponidByName("weapon_famas") != PlayerItems[param1][0][0])
			{
				if(PlayerisProtected[param1])
				{
					PrintToChat(param1, "[SM] %t", "bought_item", "famas");
					PlayerItems[param1][0][0] = GetWeaponidByName("weapon_famas");
					PlayerItems[param1][0][1] = 1;
				}
				
				else if(!StrEqual(weaponname, "weapon_famas", false))
				{
					ClientCredits[param1]--;
					GivePlayerItem(param1, "weapon_famas");
					GivePlayerItem(param1, weaponname);
					
					if(!NewItem[param1])
					{
						NewItem[param1] = true;
						ResetRebuy(param1);
					}
					LastPrimaryWeapon[param1] = 8;
				}
			}
			else
			PrintCenterText(param1, "%t", "item_owned");
		}
		else if(param2 == 9 && ClientCredits[param1] > 0 && ak47_cost != -1)
		{
			if(weaponid != -1)
			{
				
				GetEdictClassname(weaponid, weaponname, sizeof(weaponname));
				if(!StrEqual(weaponname, "weapon_ak47", false))
					RemovePlayerItem(param1, weaponid);
				else
				PrintCenterText(param1, "%t", "item_owned");
				
			}
			
			if(GetWeaponidByName("weapon_ak47") != PlayerItems[param1][0][0])
			{
				if(PlayerisProtected[param1])
				{
					PrintToChat(param1, "[SM] %t", "bought_item", "ak47");
					PlayerItems[param1][0][0] = GetWeaponidByName("weapon_ak47");
					PlayerItems[param1][0][1] = 1;
				}
				
				else if(!StrEqual(weaponname, "weapon_ak47", false))
				{
					ClientCredits[param1]--;
					GivePlayerItem(param1, "weapon_ak47");
					GivePlayerItem(param1, weaponname);
					
					if(!NewItem[param1])
					{
						NewItem[param1] = true;
						ResetRebuy(param1);
					}
					LastPrimaryWeapon[param1] = 9;
				}
			}
			else
			PrintCenterText(param1, "%t", "item_owned");
		}
		else if(param2 == 10 && ClientCredits[param1] > 0 && scout_cost != -1)
		{
			if(weaponid != -1)
			{
				
				GetEdictClassname(weaponid, weaponname, sizeof(weaponname));
				if(!StrEqual(weaponname, "weapon_scout", false))
					RemovePlayerItem(param1, weaponid);
				else
				PrintCenterText(param1, "%t", "item_owned");
				
			}
			
			if(GetWeaponidByName("weapon_scout") != PlayerItems[param1][0][0])
			{
				if(PlayerisProtected[param1])
				{
					PrintToChat(param1, "[SM] %t", "bought_item", "scout");
					PlayerItems[param1][0][0] = GetWeaponidByName("weapon_scout");
					PlayerItems[param1][0][1] = 1;
				}
				
				else if(!StrEqual(weaponname, "weapon_scout", false))
				{
					ClientCredits[param1]--;
					GivePlayerItem(param1, "weapon_scout");
					GivePlayerItem(param1, weaponname);
					
					if(!NewItem[param1])
					{
						NewItem[param1] = true;
						ResetRebuy(param1);
					}
					LastPrimaryWeapon[param1] = 10;
				}
			}
			else
			PrintCenterText(param1, "%t", "item_owned");
		}
		else if(param2 == 11 && ClientCredits[param1] > 0 && m4a1_cost != -1)
		{
			if(weaponid != -1)
			{
				
				GetEdictClassname(weaponid, weaponname, sizeof(weaponname));
				if(!StrEqual(weaponname, "weapon_m4a1", false))
					RemovePlayerItem(param1, weaponid);
				else
				PrintCenterText(param1, "%t", "item_owned");
				
			}
			
			if(GetWeaponidByName("weapon_m4a1") != PlayerItems[param1][0][0])
			{
				if(PlayerisProtected[param1])
				{
					PrintToChat(param1, "[SM] %t", "bought_item", "m4a1");
					PlayerItems[param1][0][0] = GetWeaponidByName("weapon_m4a1");
					PlayerItems[param1][0][1] = 1;
				}
				
				else if(!StrEqual(weaponname, "weapon_m4a1", false))
				{
					ClientCredits[param1]--;
					GivePlayerItem(param1, "weapon_m4a1");
					GivePlayerItem(param1, weaponname);
					
					if(!NewItem[param1])
					{
						NewItem[param1] = true;
						ResetRebuy(param1);
					}
					LastPrimaryWeapon[param1] = 11;
				}
			}
			else
			PrintCenterText(param1, "%t", "item_owned");
		}
		else if(param2 == 12 && ClientCredits[param1] > 0 && aug_cost != -1)
		{
			if(weaponid != -1)
			{
				
				GetEdictClassname(weaponid, weaponname, sizeof(weaponname));
				if(!StrEqual(weaponname, "weapon_aug", false))
					RemovePlayerItem(param1, weaponid);
				else
				PrintCenterText(param1, "%t", "item_owned");
			}
			
			if(GetWeaponidByName("weapon_aug") != PlayerItems[param1][0][0])
			{
				if(PlayerisProtected[param1])
				{
					PrintToChat(param1, "[SM] %t", "bought_item", "aug");
					PlayerItems[param1][0][0] = GetWeaponidByName("weapon_aug");
					PlayerItems[param1][0][1] = 1;
				}
				
				else if(!StrEqual(weaponname, "weapon_aug", false))
				{
					ClientCredits[param1]--;
					GivePlayerItem(param1, "weapon_aug");
					GivePlayerItem(param1, weaponname);
					
					if(!NewItem[param1])
					{
						NewItem[param1] = true;
						ResetRebuy(param1);
					}
					LastPrimaryWeapon[param1] = 12;
				}
			}
			else
			PrintCenterText(param1, "%t", "item_owned");
		}
		else if(param2 == 13 && ClientCredits[param1] > 0 && sg552_cost != -1)
		{
			if(weaponid != -1)
			{
				
				GetEdictClassname(weaponid, weaponname, sizeof(weaponname));
				if(!StrEqual(weaponname, "weapon_sg552", false))
					RemovePlayerItem(param1, weaponid);
				else
				PrintCenterText(param1, "%t", "item_owned");
				
			}
			
			if(GetWeaponidByName("weapon_sg552") != PlayerItems[param1][0][0])
			{
				if(PlayerisProtected[param1])
				{
					PrintToChat(param1, "[SM] %t", "bought_item", "sg552");
					PlayerItems[param1][0][0] = GetWeaponidByName("weapon_sg552");
					PlayerItems[param1][0][1] = 1;
				}
				
				else if(!StrEqual(weaponname, "weapon_sg552", false))
				{
					ClientCredits[param1]--;
					GivePlayerItem(param1, "weapon_sg552");
					GivePlayerItem(param1, weaponname);
					
					if(!NewItem[param1])
					{
						NewItem[param1] = true;
						ResetRebuy(param1);
					}
					LastPrimaryWeapon[param1] = 13;
				}
			}
			else
			PrintCenterText(param1, "%t", "item_owned");
		}
		else if(param2 == 14 && ClientCredits[param1] > 0 && sg550_cost != -1)
		{
			if(weaponid != -1)
			{
				
				GetEdictClassname(weaponid, weaponname, sizeof(weaponname));
				if(!StrEqual(weaponname, "weapon_sg550", false))
					RemovePlayerItem(param1, weaponid);
				else
				PrintCenterText(param1, "%t", "item_owned");
				
			}
			
			if(GetWeaponidByName("weapon_sg550") != PlayerItems[param1][0][0])
			{
				if(PlayerisProtected[param1])
				{
					PrintToChat(param1, "[SM] %t", "bought_item", "sg550");
					PlayerItems[param1][0][0] = GetWeaponidByName("weapon_sg550");
					PlayerItems[param1][0][1] = 1;
				}
				
				else if(!StrEqual(weaponname, "weapon_sg550", false))
				{
					ClientCredits[param1]--;
					GivePlayerItem(param1, "weapon_sg550");
					GivePlayerItem(param1, weaponname);
					
					if(!NewItem[param1])
					{
						NewItem[param1] = true;
						ResetRebuy(param1);
					}
					LastPrimaryWeapon[param1] = 14;
				}
			}
			else
			PrintCenterText(param1, "%t", "item_owned");
		}
		else if(param2 == 15 && ClientCredits[param1] > 0 && awp_cost != -1)
		{
			if(weaponid != -1)
			{
				
				GetEdictClassname(weaponid, weaponname, sizeof(weaponname));
				if(!StrEqual(weaponname, "weapon_awp", false))
					RemovePlayerItem(param1, weaponid);
				else
				PrintCenterText(param1, "%t", "item_owned");
				
			}
			
			if(GetWeaponidByName("weapon_awp") != PlayerItems[param1][0][0])
			{
				if(PlayerisProtected[param1])
				{
					PrintToChat(param1, "[SM] %t", "bought_item", "awp");
					PlayerItems[param1][0][0] = GetWeaponidByName("weapon_awp");
					PlayerItems[param1][0][1] = 1;
				}
				
				else if(!StrEqual(weaponname, "weapon_awp", false))
				{
					ClientCredits[param1]--;
					GivePlayerItem(param1, "weapon_awp");
					GivePlayerItem(param1, weaponname);
					
					if(!NewItem[param1])
					{
						NewItem[param1] = true;
						ResetRebuy(param1);
					}
					LastPrimaryWeapon[param1] = 15;
				}
			}
			else
			PrintCenterText(param1, "%t", "item_owned");
		}
		else if(param2 == 16 && ClientCredits[param1] > 0 && g3sg1 != -1)
		{
			if(weaponid != -1)
			{
				
				GetEdictClassname(weaponid, weaponname, sizeof(weaponname));
				if(!StrEqual(weaponname, "weapon_g3sg1", false))
					RemovePlayerItem(param1, weaponid);
				else
				PrintCenterText(param1, "%t", "item_owned");
				
			}
			
			if(GetWeaponidByName("weapon_g3sg1") != PlayerItems[param1][0][0])
			{
				if(PlayerisProtected[param1])
				{
					PrintToChat(param1, "[SM] %t", "bought_item", "g3sg1");
					PlayerItems[param1][0][0] = GetWeaponidByName("weapon_g3sg1");
					PlayerItems[param1][0][1] = 1;
				}
				
				else if(!StrEqual(weaponname, "weapon_g3sg1", false))
				{
					ClientCredits[param1]--;
					GivePlayerItem(param1, "weapon_g3sg1");
					GivePlayerItem(param1, weaponname);
					
					if(!NewItem[param1])
					{
						NewItem[param1] = true;
						ResetRebuy(param1);
					}
					LastPrimaryWeapon[param1] = 16;
				}
			}
			else
			PrintCenterText(param1, "%t", "item_owned");
		}
		else if(param2 == 17 && ClientCredits[param1] > 0 && m249_cost != -1)
		{			
			if(weaponid != -1)
			{
				
				GetEdictClassname(weaponid, weaponname, sizeof(weaponname));
				if(!StrEqual(weaponname, "weapon_m249", false))
					RemovePlayerItem(param1, weaponid);
				else
				PrintCenterText(param1, "%t", "item_owned");
				
			}
			
			if(GetWeaponidByName("weapon_m249") != PlayerItems[param1][0][0])
			{
				if(PlayerisProtected[param1])
				{
					PrintToChat(param1, "[SM] %t", "bought_item", "m249");
					PlayerItems[param1][0][0] = GetWeaponidByName("weapon_m249");
					PlayerItems[param1][0][1] = 1;
				}
				
				else if(!StrEqual(weaponname, "weapon_m249", false))
				{
					ClientCredits[param1]--;
					GivePlayerItem(param1, "weapon_m249");
					GivePlayerItem(param1, weaponname);
					
					if(!NewItem[param1])
					{
						NewItem[param1] = true;
						ResetRebuy(param1);
					}
					LastPrimaryWeapon[param1] = 17;
				}
			}
			else
			PrintCenterText(param1, "%t", "item_owned");
		}
		else
		PrintCenterText(param1, "%t", "money");
		ManageAccounts(param1);
		if(buymenucont[param1] && ClientCash >= 650)
		{
			Buy_Equipment_Control(param1, 0);
		}
		if(firstjoin[param1])
		{
			firstjoin[param1] = false;
			PrintToChat(param1, "[SM] %t",  "buymenu_chat");
			PrintToChat(param1, "[SM] %t",  "buybind_chat");
		}
	}
	if(action == MenuAction_Cancel)
	{
		new ClientCash = GetClientMoney(param1);
		if(param2 == MenuCancel_Exit && buymenucont[param1] && ClientCash >= 650)
		{
			Buy_Equipment_Control(param1, 0);
		}
		
		if(param2 == MenuCancel_Exit || param2 == MenuCancel_Timeout)
		{
			PrintToChat(param1, "[SM] %t",  "buymenu_chat");
		}
	}
	if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}




public Action:Buy_Guns_Control(client, args)
{
	new String:buffer[32], String:buffer2[32], String:buffer3[32], String:buffer4[32], String:buffer5[32],
	String:buffer6[32], String:buffer7[32], String:buffer8[32], String:buffer9[32], String:buffer10[32], 
	String:buffer11[32], String:buffer12[32], String:buffer13[32], String:buffer14[32], String:buffer15[32], 
	String:buffer16[32], String:buffer17[32], String:buffer18[32], String:buffer19[32];
	
	new Handle:menu = CreateMenu(GunsMenu);
	Format(buffer, sizeof(buffer), "%T", "primary_gunmenu", LANG_SERVER);
	if(m3_cost != -1)
		Format(buffer2, sizeof(buffer2), "shotgun: $%d", m3_cost);
	else
	Format(buffer2, sizeof(buffer2), "shotgun: %T", "restrict", LANG_SERVER);
	if(xm1014_cost != -1)
		Format(buffer3, sizeof(buffer3), "auto shotgun: $%d", xm1014_cost);
	else
	Format(buffer3, sizeof(buffer3), "auto shotgun: %T", "restrict", LANG_SERVER);
	if(tmp_cost != -1)
		Format(buffer4, sizeof(buffer4), "tmp: $%d", tmp_cost);
	else
	Format(buffer4, sizeof(buffer4), "tmp: %T", "restrict", LANG_SERVER);
	if(mac10_cost != -1)
		Format(buffer5, sizeof(buffer5), "mac10: $%d", mac10_cost);
	else
	Format(buffer5, sizeof(buffer5), "mac10: %T", "restrict", LANG_SERVER);
	if(mp5navy_cost != -1)
		Format(buffer6, sizeof(buffer6), "mp5navy: $%d", mp5navy_cost);
	else
	Format(buffer6, sizeof(buffer6), "mp5navy: %T", "restrict", LANG_SERVER);
	if(ump45_cost != -1)
		Format(buffer7, sizeof(buffer7), "ump45: $%d", ump45_cost);
	else
	Format(buffer7, sizeof(buffer7), "ump45: %T", "restrict", LANG_SERVER);
	if(p90_cost != -1)
		Format(buffer8, sizeof(buffer8), "p90: $%d", p90_cost);
	else
	Format(buffer8, sizeof(buffer8), "p90: %T", "restrict", LANG_SERVER);
	if(galil_cost != -1)
		Format(buffer9, sizeof(buffer9), "galil: $%d", galil_cost);
	else
	Format(buffer9, sizeof(buffer9), "galil: %T", "restrict", LANG_SERVER);
	if(famas_cost != -1)
		Format(buffer10, sizeof(buffer10), "famas: $%d", famas_cost);
	else
	Format(buffer10, sizeof(buffer10), "famas: %T", "restrict", LANG_SERVER);
	if(ak47_cost != -1)
		Format(buffer11, sizeof(buffer11), "ak-47: $%d", ak47_cost);
	else
	Format(buffer11, sizeof(buffer11), "ak-47: %T", "restrict", LANG_SERVER);
	if(scout_cost != -1)
		Format(buffer12, sizeof(buffer12), "scout: $%d", scout_cost);
	else
	Format(buffer12, sizeof(buffer12), "scout: %T", "restrict", LANG_SERVER);
	if(m4a1_cost != -1)
		Format(buffer13, sizeof(buffer13), "m4a1: $%d", m4a1_cost);
	else
	Format(buffer13, sizeof(buffer13), "m4a1: %T", "restrict", LANG_SERVER);
	if(aug_cost != -1)
		Format(buffer14, sizeof(buffer14), "aug: $%d", aug_cost);
	else
	Format(buffer14, sizeof(buffer14), "aug: %T", "restrict", LANG_SERVER);
	if(sg552_cost != -1)
		Format(buffer15, sizeof(buffer15), "sg552: $%d", sg552_cost);
	else
	Format(buffer15, sizeof(buffer15), "sg552: %T", "restrict", LANG_SERVER);
	if(sg550_cost != -1)
		Format(buffer16, sizeof(buffer16), "sg550: $%d", sg550_cost);
	else
	Format(buffer16, sizeof(buffer16), "sg550: %T", "restrict", LANG_SERVER);
	if(awp_cost != -1)
		Format(buffer17, sizeof(buffer17), "awp: $%d", awp_cost);
	else
	Format(buffer17, sizeof(buffer17), "awp: %T", "restrict", LANG_SERVER);
	if(g3sg1_cost != -1)
		Format(buffer18, sizeof(buffer18), "g3sg1: $%d", g3sg1_cost);
	else
	Format(buffer18, sizeof(buffer18), "g3sg1: %T", "restrict", LANG_SERVER);
	if(m249_cost != -1)
		Format(buffer19, sizeof(buffer19), "m249: $%d", m249_cost);
	else
	Format(buffer19, sizeof(buffer19), "m249: %T", "restrict", LANG_SERVER);
	
	SetMenuTitle(menu, buffer);
	AddMenuItem(menu, buffer2, buffer2);
	AddMenuItem(menu, buffer3, buffer3);
	AddMenuItem(menu, buffer4, buffer4);
	AddMenuItem(menu, buffer5, buffer5);
	AddMenuItem(menu, buffer6, buffer6);
	AddMenuItem(menu, buffer7, buffer7);
	AddMenuItem(menu, buffer8, buffer8);
	AddMenuItem(menu, buffer9, buffer9);
	AddMenuItem(menu, buffer10, buffer10);
	AddMenuItem(menu, buffer11, buffer11);
	AddMenuItem(menu, buffer12, buffer12);
	AddMenuItem(menu, buffer13, buffer13);
	AddMenuItem(menu, buffer14, buffer14);
	AddMenuItem(menu, buffer15, buffer15);
	AddMenuItem(menu, buffer16, buffer16);
	AddMenuItem(menu, buffer17, buffer17);
	AddMenuItem(menu, buffer18, buffer18);
	AddMenuItem(menu, buffer19, buffer19);
	
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public Pistols_Menu(Handle:menu, MenuAction:action, param1, param2)
{
	if(action == MenuAction_Select)
	{
		new weaponid = GetPlayerWeaponSlot(param1, 1);
		new String:weaponname[32];
		new ClientCash = GetClientMoney(param1);
		if(param2 == 0 && ClientCash >= glock_cost && glock_cost != -1)
		{
			if(weaponid != -1)
			{
				
				GetEdictClassname(weaponid, weaponname, sizeof(weaponname));
				if(!StrEqual(weaponname, "weapon_glock", false))
					RemovePlayerItem(param1, weaponid);
				else
				PrintCenterText(param1, "%t", "item_owned");
				
			}
			if(GetWeaponidByName("weapon_glock") != PlayerItems[param1][1][0])
			{
				if(PlayerisProtected[param1])
				{
					PrintToChat(param1, "[SM] %t", "bought_item", "glock");
					PlayerItems[param1][1][0] = GetWeaponidByName("weapon_glock");
					PlayerItems[param1][1][1] = 1;
				}
				
				else if(!StrEqual(weaponname, "weapon_glock", false))
				{
					SetClientMoney(param1, ClientCash - glock_cost);
					GivePlayerItem(param1, "weapon_glock");
					GivePlayerItem(param1, weaponname);
				
					if(!NewItem[param1])
					{
						NewItem[param1] = true;
						ResetRebuy(param1);
					}
					LastSecondaryWeapon[param1] = 0;
				}
			}
			else
			PrintCenterText(param1, "%t", "item_owned");
		}
		else if(param2 == 1 && ClientCash >= usp_cost && usp_cost != -1)
		{
			if(weaponid != -1)
			{
				
				GetEdictClassname(weaponid, weaponname, sizeof(weaponname));
				if(!StrEqual(weaponname, "weapon_usp", false))
					RemovePlayerItem(param1, weaponid);
				else
				PrintCenterText(param1, "%t", "item_owned");
				
			}
			if(GetWeaponidByName("weapon_usp") != PlayerItems[param1][1][0])
			{			
				if(PlayerisProtected[param1])
				{
					PrintToChat(param1, "[SM] %t", "bought_item", "usp");
					PlayerItems[param1][1][0] = GetWeaponidByName("weapon_usp");
					PlayerItems[param1][1][1] = 1;
				}
				
				else if(!StrEqual(weaponname, "weapon_usp", false))
				{
					SetClientMoney(param1, ClientCash - usp_cost);
					GivePlayerItem(param1, "weapon_usp");
					GivePlayerItem(param1, weaponname);
				
					if(!NewItem[param1])
					{
						NewItem[param1] = true;
						ResetRebuy(param1);
					}
					LastSecondaryWeapon[param1] = 1;
				}
			}
			else
			PrintCenterText(param1, "%t", "item_owned");
		}
		else if(param2 == 2 && ClientCash >= p228_cost && p228_cost != -1)
		{
			if(weaponid != -1)
			{
				
				GetEdictClassname(weaponid, weaponname, sizeof(weaponname));
				if(!StrEqual(weaponname, "weapon_p228", false))
					RemovePlayerItem(param1, weaponid);
				else
				PrintCenterText(param1, "%t", "item_owned");
				
			}
			
			if(GetWeaponidByName("weapon_p228") != PlayerItems[param1][1][0])
			{
				if(PlayerisProtected[param1])
				{
					PrintToChat(param1, "[SM] %t", "bought_item", "p228");
					PlayerItems[param1][1][0] = GetWeaponidByName("weapon_p228");
					PlayerItems[param1][1][1] = 1;
				}
				
				else if(!StrEqual(weaponname, "weapon_p228", false))
				{
					SetClientMoney(param1, ClientCash - p228_cost);
					GivePlayerItem(param1, "weapon_p228");
					GivePlayerItem(param1, weaponname);
				
					if(!NewItem[param1])
					{
						NewItem[param1] = true;
						ResetRebuy(param1);
					}
					LastSecondaryWeapon[param1] = 2;
				}
			}
			else
			PrintCenterText(param1, "%t", "item_owned");
		}
		else if(param2 == 3 && ClientCash >= deagle_cost && deagle_cost != -1)
		{
			if(weaponid != -1)
			{
				
				GetEdictClassname(weaponid, weaponname, sizeof(weaponname));
				if(!StrEqual(weaponname, "weapon_deagle", false))
					RemovePlayerItem(param1, weaponid);
				else
				PrintCenterText(param1, "%t", "item_owned");
				
			}
			
			if(GetWeaponidByName("weapon_deagle") != PlayerItems[param1][1][0])
			{
				if(PlayerisProtected[param1])
				{
					PrintToChat(param1, "[SM] %t", "bought_item", "desert eagle");
					PlayerItems[param1][1][0] = GetWeaponidByName("weapon_deagle");
					PlayerItems[param1][1][1] = 1;
				}
				
				else if(!StrEqual(weaponname, "weapon_deagle", false))
				{
					SetClientMoney(param1, ClientCash - deagle_cost);
					GivePlayerItem(param1, "weapon_deagle");
					GivePlayerItem(param1, weaponname);
				
					if(!NewItem[param1])
					{
						NewItem[param1] = true;
						ResetRebuy(param1);
					}
					LastSecondaryWeapon[param1] = 3;
				}
			}
			else
			PrintCenterText(param1, "%t", "item_owned");
		}
		else if(param2 == 4 && ClientCash >= fiveseven_cost && fiveseven_cost != -1)
		{
			if(weaponid != -1)
			{
				
				GetEdictClassname(weaponid, weaponname, sizeof(weaponname));
				if(!StrEqual(weaponname, "weapon_fiveseven", false))
					RemovePlayerItem(param1, weaponid);
				else
				PrintCenterText(param1, "%t", "item_owned");
				
			}
			
			if(GetWeaponidByName("weapon_fiveseven") != PlayerItems[param1][1][0])
			{
				if(PlayerisProtected[param1])
				{
					PrintToChat(param1, "[SM] %t", "bought_item", "fiveseven");
					PlayerItems[param1][1][0] = GetWeaponidByName("weapon_fiveseven");
					PlayerItems[param1][1][1] = 1;
				}
				
				else if(!StrEqual(weaponname, "weapon_fiveseven", false))
				{
					SetClientMoney(param1, ClientCash - fiveseven_cost);
					GivePlayerItem(param1, "weapon_fiveseven");
					GivePlayerItem(param1, weaponname);
				
					if(!NewItem[param1])
					{
						NewItem[param1] = true;
						ResetRebuy(param1);
					}
					LastSecondaryWeapon[param1] = 4;
				}
			}
			else
			PrintCenterText(param1, "%t", "item_owned");
		}
		else if(param2 == 5 && ClientCash >= elite_cost && elite_cost != -1)
		{
			if(weaponid != -1)
			{
				
				GetEdictClassname(weaponid, weaponname, sizeof(weaponname));
				if(!StrEqual(weaponname, "weapon_elite", false))
					RemovePlayerItem(param1, weaponid);
				else
				PrintCenterText(param1, "%t", "item_owned");
				
			}
			
			if(GetWeaponidByName("weapon_elite") != PlayerItems[param1][1][0])
			{
				if(PlayerisProtected[param1])
				{
					PrintToChat(param1, "[SM] %t", "bought_item", "dual Bereta elites");
					PlayerItems[param1][1][0] = GetWeaponidByName("weapon_elite");
					PlayerItems[param1][1][1] = 1;
				}
				
				else if(!StrEqual(weaponname, "weapon_elite", false))
				{
					SetClientMoney(param1, ClientCash - elite_cost);
					GivePlayerItem(param1, "weapon_elite");
					GivePlayerItem(param1, weaponname);
				
					if(!NewItem[param1])
					{
						NewItem[param1] = true;
						ResetRebuy(param1);
					}
					LastSecondaryWeapon[param1] = 5;
				}
			}
			else
			PrintCenterText(param1, "%t", "item_owned");
		}
		else if(param2 == 0 && ClientCredits[param1] > 0 && glock_cost != -1)
		{
			if(weaponid != -1)
			{
				
				GetEdictClassname(weaponid, weaponname, sizeof(weaponname));
				if(!StrEqual(weaponname, "weapon_glock", false))
					RemovePlayerItem(param1, weaponid);
				else
				PrintCenterText(param1, "%t", "item_owned");
				
			}
			
			if(GetWeaponidByName("weapon_glock") != PlayerItems[param1][1][0])
			{
				if(PlayerisProtected[param1])
				{
					PrintToChat(param1, "[SM] %t", "bought_item", "glock");
					PlayerItems[param1][1][0] = GetWeaponidByName("weapon_glock");
					PlayerItems[param1][1][1] = 1;
				}
				
				else if(!StrEqual(weaponname, "weapon_glock", false))
				{
					ClientCredits[param1]--;
					GivePlayerItem(param1, "weapon_glock");
					GivePlayerItem(param1, weaponname);
				
					if(!NewItem[param1])
					{
						NewItem[param1] = true;
						ResetRebuy(param1);
					}
					LastSecondaryWeapon[param1] = 0;
				}
			}
			else
			PrintCenterText(param1, "%t", "item_owned");
		}
		else if(param2 == 1 && ClientCredits[param1] > 0 && usp_cost != -1)
		{
			if(weaponid != -1)
			{
				
				GetEdictClassname(weaponid, weaponname, sizeof(weaponname));
				if(!StrEqual(weaponname, "weapon_usp", false))
					RemovePlayerItem(param1, weaponid);
				else
				PrintCenterText(param1, "%t", "item_owned");
				
			}
			if(GetWeaponidByName("weapon_usp") != PlayerItems[param1][1][0])
			{
				if(PlayerisProtected[param1])
				{
					PrintToChat(param1, "[SM] %t", "bought_item", "usp");
					PlayerItems[param1][1][0] = GetWeaponidByName("weapon_usp");
					PlayerItems[param1][1][1] = 1;
				}
				
				else if(!StrEqual(weaponname, "weapon_usp", false))
				{
					ClientCredits[param1]--;
					GivePlayerItem(param1, "weapon_usp");
					GivePlayerItem(param1, weaponname);
				
					if(!NewItem[param1])
					{
						NewItem[param1] = true;
						ResetRebuy(param1);
					}
					LastSecondaryWeapon[param1] = 1;
				}
			}
			else
			PrintCenterText(param1, "%t", "item_owned");
		}
		else if(param2 == 2 && ClientCredits[param1] > 0 && p228_cost != -1)
		{
			if(weaponid != -1)
			{
				
				GetEdictClassname(weaponid, weaponname, sizeof(weaponname));
				if(!StrEqual(weaponname, "weapon_p228", false))
					RemovePlayerItem(param1, weaponid);
				else
				PrintCenterText(param1, "%t", "item_owned");
				
			}
			if(GetWeaponidByName("weapon_p228") != PlayerItems[param1][1][0])
			{
				if(PlayerisProtected[param1])
				{
					PrintToChat(param1, "[SM] %t", "bought_item", "p228");
					PlayerItems[param1][1][0] = GetWeaponidByName("weapon_p228");
					PlayerItems[param1][1][1] = 1;
				}
				
				else if(!StrEqual(weaponname, "weapon_p228", false))
				{
					ClientCredits[param1]--;
					GivePlayerItem(param1, "weapon_p228");
					GivePlayerItem(param1, weaponname);
				
					if(!NewItem[param1])
					{
						NewItem[param1] = true;
						ResetRebuy(param1);
					}
					LastSecondaryWeapon[param1] = 2;
				}
			}
			else
			PrintCenterText(param1, "%t", "item_owned");
		}
		else if(param2 == 3 && ClientCredits[param1] > 0 && deagle_cost != -1)
		{
			if(weaponid != -1)
			{
				
				GetEdictClassname(weaponid, weaponname, sizeof(weaponname));
				if(!StrEqual(weaponname, "weapon_deagle", false))
					RemovePlayerItem(param1, weaponid);
				else
				PrintCenterText(param1, "%t", "item_owned");
				
			}
			
			if(GetWeaponidByName("weapon_deagle") != PlayerItems[param1][1][0])
			{
				if(PlayerisProtected[param1])
				{
					PrintToChat(param1, "[SM] %t", "bought_item", "desert eagle");
					PlayerItems[param1][1][0] = GetWeaponidByName("weapon_deagle");
					PlayerItems[param1][1][1] = 1;
				}
				
				else if(!StrEqual(weaponname, "weapon_deagle", false))
				{
					ClientCredits[param1]--;
					GivePlayerItem(param1, "weapon_deagle");
					GivePlayerItem(param1, weaponname);
					
					if(!NewItem[param1])
					{
						NewItem[param1] = true;
						ResetRebuy(param1);
					}
					LastSecondaryWeapon[param1] = 3;
				}
			}
			else
			PrintCenterText(param1, "%t", "item_owned");
		}
		else if(param2 == 4 && ClientCredits[param1] > 0 && fiveseven_cost != -1)
		{
			if(weaponid != -1)
			{
				
				GetEdictClassname(weaponid, weaponname, sizeof(weaponname));
				if(!StrEqual(weaponname, "weapon_fiveseven", false))
					RemovePlayerItem(param1, weaponid);
				else
				PrintCenterText(param1, "%t", "item_owned");
				
			}
			
			if(GetWeaponidByName("weapon_fiveseven") != PlayerItems[param1][1][0])
			{
				if(PlayerisProtected[param1])
				{
					PrintToChat(param1, "[SM] %t", "bought_item", "fiveseven");
					PlayerItems[param1][1][0] = GetWeaponidByName("weapon_fiveseven");
					PlayerItems[param1][1][1] = 1;
				}
				
				else if(!StrEqual(weaponname, "weapon_fiveseven", false))
				{
					ClientCredits[param1]--;
					GivePlayerItem(param1, "weapon_fiveseven");
					GivePlayerItem(param1, weaponname);
				
					if(!NewItem[param1])
					{
						NewItem[param1] = true;
						ResetRebuy(param1);
					}
					LastSecondaryWeapon[param1] = 4;
				}
			}
			else
			PrintCenterText(param1, "%t", "item_owned");
		}
		else if(param2 == 5 && ClientCredits[param1] > 0 && elite_cost != -1)
		{
			if(weaponid != -1)
			{
				
				GetEdictClassname(weaponid, weaponname, sizeof(weaponname));
				if(!StrEqual(weaponname, "weapon_elite", false))
					RemovePlayerItem(param1, weaponid);
				else
				PrintCenterText(param1, "%t", "item_owned");
				
			}
			
			if(GetWeaponidByName("weapon_elite") != PlayerItems[param1][1][0])
			{
				if(PlayerisProtected[param1])
				{
					PrintToChat(param1, "[SM] %t", "bought_item", "dual Bereta elites");
					PlayerItems[param1][1][0] = GetWeaponidByName("weapon_elite");
					PlayerItems[param1][1][1] = 1;
				}
				
				else if(!StrEqual(weaponname, "weapon_elite", false))
				{
					ClientCredits[param1]--;
					GivePlayerItem(param1, "weapon_elite");
					GivePlayerItem(param1, weaponname);
				
					if(!NewItem[param1])
					{
						NewItem[param1] = true;
						ResetRebuy(param1);
					}
					LastSecondaryWeapon[param1] = 5;
				}
			}
			else
			PrintCenterText(param1, "%t", "item_owned");
		}
		else
		PrintCenterText(param1, "%t", "money");
		
		if(buymenucont[param1] && ClientCash >= 1250)
		{
			Buy_Guns_Control(param1, 0);
		}
		ManageAccounts(param1);
		
		if(firstjoin[param1])
		{
			firstjoin[param1] = false;
			PrintToChat(param1, "[SM] %t",  "buymenu_chat");
			PrintToChat(param1, "[SM] %t",  "buybind_chat");
		}
	}
	if(action == MenuAction_Cancel)
	{
		new ClientCash = GetClientMoney(param1);
		if(param2 == MenuCancel_Exit && buymenucont[param1] && ClientCash >= 1250)
		{
			Buy_Guns_Control(param1, 0);
		}
		else if(param2 == MenuCancel_Exit && buymenucont[param1] && ClientCash >= 650)
		{
			Buy_Equipment_Control(param1, 0);
		}
		else if(param2 == MenuCancel_Exit || param2 == MenuCancel_Timeout)
		{
			PrintToChat(param1, "[SM] %t",  "buymenu_chat");
		}
	}
	if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}


public Action:Buy_Pistols_Control(client, args)
{
	new String:buffer[32], String:buffer2[32], String:buffer3[32], String:buffer4[32], String:buffer5[32],
	String:buffer6[32], String:buffer7[32];
	
	new Handle:menu = CreateMenu(Pistols_Menu);
	Format(buffer, sizeof(buffer), "%T", "pistol_menu", LANG_SERVER);
	if(glock_cost != -1)
		Format(buffer2, sizeof(buffer2), "glock: $%d", glock_cost);
	else
	Format(buffer2, sizeof(buffer2), "glock: %T", "restrict", LANG_SERVER);
	if(usp_cost != -1)
		Format(buffer3, sizeof(buffer3), "usp: $%d", usp_cost);
	else
	Format(buffer3, sizeof(buffer3), "usp: %T", "restrict", LANG_SERVER);
	if(p228_cost != -1)
		Format(buffer4, sizeof(buffer4), "p228: $%d", p228_cost);
	else
	Format(buffer4, sizeof(buffer4), "p228: %T", "restrict", LANG_SERVER);
	if(deagle_cost != -1)
		Format(buffer5, sizeof(buffer5), "deagle: $%d", deagle_cost);
	else
	Format(buffer5, sizeof(buffer5), "deagle: %T", "restrict", LANG_SERVER);
	if(fiveseven_cost != -1)
		Format(buffer6, sizeof(buffer6), "FiveSeven: $%d", fiveseven_cost);
	else
	Format(buffer6, sizeof(buffer6), "FiveSeven: %T", "restrict", LANG_SERVER);
	if(elite_cost != -1)
		Format(buffer7, sizeof(buffer7), "elites: $%d", elite_cost);
	else
	Format(buffer7, sizeof(buffer7), "elites: %T", "restrict", LANG_SERVER);
	
	SetMenuTitle(menu, buffer);
	AddMenuItem(menu, buffer2, buffer2);
	AddMenuItem(menu, buffer3, buffer3);
	AddMenuItem(menu, buffer4, buffer4);
	AddMenuItem(menu, buffer5, buffer5);
	AddMenuItem(menu, buffer6, buffer6);
	AddMenuItem(menu, buffer7, buffer7);
	
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public RebuyPrimary(param1, param2)
{
	if (param2 != -1)
	{
		new weaponid = GetPlayerWeaponSlot(param1, 0);
		new String:weaponname[32];
		new ClientCash = GetClientMoney(param1);
		if(param2 == 0 && ClientCash >= m3_cost && m3_cost != -1)
		{			
			if(weaponid != -1)
			{
				
				GetEdictClassname(weaponid, weaponname, sizeof(weaponname));
				if(!StrEqual(weaponname, "weapon_m3", false))
					RemovePlayerItem(param1, weaponid);
				else
				PrintCenterText(param1, "%t", "item_owned");
			}
			
			if(GetWeaponidByName("weapon_m3") != PlayerItems[param1][0][0])
			{
				if(PlayerisProtected[param1])
				{
					PrintToChat(param1, "[SM] %t", "bought_item", "shotgun");
					PlayerItems[param1][0][0] = GetWeaponidByName("weapon_m3");
					PlayerItems[param1][0][1] = 1;
				}
				
				else if(!StrEqual(weaponname, "weapon_m3", false))
				{
					SetClientMoney(param1, ClientCash - m3_cost);
					GivePlayerItem(param1, "weapon_m3");
					GivePlayerItem(param1, weaponname);
					LastPrimaryWeapon[param1] = 0;
				}
			}
			else
			PrintCenterText(param1, "%t", "item_owned");
		}
		else if(param2 == 1 && ClientCash >= xm1014_cost && xm1014_cost != -1)
		{			
			if(weaponid != -1)
			{
				
				GetEdictClassname(weaponid, weaponname, sizeof(weaponname));
				if(!StrEqual(weaponname, "weapon_xm1014", false))
					RemovePlayerItem(param1, weaponid);
				else
				PrintCenterText(param1, "%t", "item_owned");
			}
			
			if(GetWeaponidByName("weapon_xm1014") != PlayerItems[param1][0][0])
			{
				if(PlayerisProtected[param1])
				{
					PrintToChat(param1, "[SM] %t", "bought_item", "auto shotgun");
					PlayerItems[param1][0][0] = GetWeaponidByName("weapon_xm1014");
					PlayerItems[param1][0][1] = 1;
				}
				
				else if(!StrEqual(weaponname, "weapon_xm1014", false))
				{
					SetClientMoney(param1, ClientCash - xm1014_cost);
					GivePlayerItem(param1, "weapon_xm1014");
					GivePlayerItem(param1, weaponname);
					LastPrimaryWeapon[param1] = 1;
				}
			}
			else
			PrintCenterText(param1, "%t", "item_owned");
		}
		else if(param2 == 2 && ClientCash >= tmp_cost && tmp_cost != -1)
		{			
			if(weaponid != -1)
			{
				
				GetEdictClassname(weaponid, weaponname, sizeof(weaponname));
				if(!StrEqual(weaponname, "weapon_tmp", false))
					RemovePlayerItem(param1, weaponid);
				else
				PrintCenterText(param1, "%t", "item_owned");
				
			}
			
			if(GetWeaponidByName("weapon_tmp") != PlayerItems[param1][0][0])
			{
				if(PlayerisProtected[param1])
				{
					PrintToChat(param1, "[SM] %t", "bought_item", "tmp");
					PlayerItems[param1][0][0] = GetWeaponidByName("weapon_tmp");
					PlayerItems[param1][0][1] = 1;
				}
				
				else if(!StrEqual(weaponname, "weapon_tmp", false))
				{
					SetClientMoney(param1, ClientCash - tmp_cost);
					GivePlayerItem(param1, "weapon_tmp");
					GivePlayerItem(param1, weaponname);
					LastPrimaryWeapon[param1] = 2;
				}
			}
			else
			PrintCenterText(param1, "%t", "item_owned");
		}
		else if(param2 == 3 && ClientCash >= mac10_cost && mac10_cost != -1)
		{			
			if(weaponid != -1)
			{
				
				GetEdictClassname(weaponid, weaponname, sizeof(weaponname));
				if(!StrEqual(weaponname, "weapon_mac10", false))
					RemovePlayerItem(param1, weaponid);
				else
				PrintCenterText(param1, "%t", "item_owned");
				
			}
			
			if(GetWeaponidByName("weapon_mac10") != PlayerItems[param1][0][0])
			{
				if(PlayerisProtected[param1])
				{
					PrintToChat(param1, "[SM] %t", "bought_item", "mac10");
					PlayerItems[param1][0][0] = GetWeaponidByName("weapon_mac10");
					PlayerItems[param1][0][1] = 1;
				}
				
				else if(!StrEqual(weaponname, "weapon_mac10", false))
				{
					SetClientMoney(param1, ClientCash - mac10_cost);
					GivePlayerItem(param1, "weapon_mac10");
					GivePlayerItem(param1, weaponname);
					LastPrimaryWeapon[param1] = 3;
				}
			}
			else
			PrintCenterText(param1, "%t", "item_owned");
			
		}
		else if(param2 == 4 && ClientCash >= mp5navy_cost && mp5navy_cost != -1)
		{
			if(weaponid != -1)
			{
				
				
				GetEdictClassname(weaponid, weaponname, sizeof(weaponname));
				if(!StrEqual(weaponname, "weapon_mp5navy", false))
					RemovePlayerItem(param1, weaponid);
				else
				PrintCenterText(param1, "%t", "item_owned");
				
			}
			
			if(GetWeaponidByName("weapon_mp5navy") != PlayerItems[param1][0][0])
			{
				if(PlayerisProtected[param1])
				{
					PrintToChat(param1, "[SM] %t", "bought_item", "mp5navy");
					PlayerItems[param1][0][0] = GetWeaponidByName("weapon_mp5navy");
					PlayerItems[param1][0][1] = 1;
				}
				
				else if(!StrEqual(weaponname, "weapon_mp5navy", false))
				{
					SetClientMoney(param1, ClientCash - mp5navy_cost);
					GivePlayerItem(param1, "weapon_mp5navy");
					GivePlayerItem(param1, weaponname);
					LastPrimaryWeapon[param1] = 4;
				}
			}
			else
			PrintCenterText(param1, "%t", "item_owned");
		}
		else if(param2 == 5 && ClientCash >= ump45_cost && ump45_cost != -1)
		{
			if(weaponid != -1)
			{
				
				GetEdictClassname(weaponid, weaponname, sizeof(weaponname));
				if(!StrEqual(weaponname, "weapon_ump45", false))
					RemovePlayerItem(param1, weaponid);
				else
				PrintCenterText(param1, "%t", "item_owned");
				
			}
			
			if(GetWeaponidByName("weapon_ump45") != PlayerItems[param1][0][0])
			{
				if(PlayerisProtected[param1])
				{
					PrintToChat(param1, "[SM] %t", "bought_item", "ump45");
					PlayerItems[param1][0][0] = GetWeaponidByName("weapon_ump45");
					PlayerItems[param1][0][1] = 1;
				}
				
				else if(!StrEqual(weaponname, "weapon_ump45", false))
				{
					SetClientMoney(param1, ClientCash - ump45_cost);
					GivePlayerItem(param1, "weapon_ump45");
					GivePlayerItem(param1, weaponname);
					LastPrimaryWeapon[param1] = 5;
				}
			}
			else
			PrintCenterText(param1, "%t", "item_owned");
		}
		else if(param2 == 6 && ClientCash >= p90_cost && p90_cost != -1)
		{
			if(weaponid != -1)
			{
				
				GetEdictClassname(weaponid, weaponname, sizeof(weaponname));
				if(!StrEqual(weaponname, "weapon_p90", false))
					RemovePlayerItem(param1, weaponid);
				else
				PrintCenterText(param1, "%t", "item_owned");
				
			}
			
			if(GetWeaponidByName("weapon_p90") != PlayerItems[param1][0][0])
			{
				if(PlayerisProtected[param1])
				{
					PrintToChat(param1, "[SM] %t", "bought_item", "p90");
					PlayerItems[param1][0][0] = GetWeaponidByName("weapon_p90");
					PlayerItems[param1][0][1] = 1;
				}
				
				else if(!StrEqual(weaponname, "weapon_p90", false))
				{
					SetClientMoney(param1, ClientCash - p90_cost);
					GivePlayerItem(param1, "weapon_p90");
					GivePlayerItem(param1, weaponname);
					LastPrimaryWeapon[param1] = 6;
				}
			}
			else
			PrintCenterText(param1, "%t", "item_owned");
		}
		else if(param2 == 7 && ClientCash >= galil_cost && galil_cost != -1)
		{
			if(weaponid != -1)
			{
				
				GetEdictClassname(weaponid, weaponname, sizeof(weaponname));
				if(!StrEqual(weaponname, "weapon_galil", false))
					RemovePlayerItem(param1, weaponid);
				else
				PrintCenterText(param1, "%t", "item_owned");
				
			}
			
			if(GetWeaponidByName("weapon_galil") != PlayerItems[param1][0][0])
			{
				if(PlayerisProtected[param1])
				{
					PrintToChat(param1, "[SM] %t", "bought_item", "galil");
					PlayerItems[param1][0][0] = GetWeaponidByName("weapon_galil");
					PlayerItems[param1][0][1] = 1;
				}
				
				else if(!StrEqual(weaponname, "weapon_galil", false))
				{
					SetClientMoney(param1, ClientCash - galil_cost);
					GivePlayerItem(param1, "weapon_galil");
					GivePlayerItem(param1, weaponname);
					LastPrimaryWeapon[param1] = 7;	
				}
			}
			else
			PrintCenterText(param1, "%t", "item_owned");
		}
		else if(param2 == 8 && ClientCash >= famas_cost && famas_cost != -1)
		{
			if(weaponid != -1)
			{
				
				GetEdictClassname(weaponid, weaponname, sizeof(weaponname));
				if(!StrEqual(weaponname, "weapon_famas", false))
					RemovePlayerItem(param1, weaponid);
				else
				PrintCenterText(param1, "%t", "item_owned");
				
			}
			
			if(GetWeaponidByName("weapon_famas") != PlayerItems[param1][0][0])
			{
				if(PlayerisProtected[param1])
				{
					PrintToChat(param1, "[SM] %t", "bought_item", "famas");
					PlayerItems[param1][0][0] = GetWeaponidByName("weapon_famas");
					PlayerItems[param1][0][1] = 1;
				}
				
				else if(!StrEqual(weaponname, "weapon_famas", false))
				{
					SetClientMoney(param1, ClientCash - famas_cost);
					GivePlayerItem(param1, "weapon_famas");
					GivePlayerItem(param1, weaponname);
					LastPrimaryWeapon[param1] = 8;	
				}
			}
			else
			PrintCenterText(param1, "%t", "item_owned");
		}
		else if(param2 == 9 && ClientCash >= ak47_cost && ak47_cost != -1)
		{
			if(weaponid != -1)
			{
				
				GetEdictClassname(weaponid, weaponname, sizeof(weaponname));
				if(!StrEqual(weaponname, "weapon_ak47", false))
					RemovePlayerItem(param1, weaponid);
				else
				PrintCenterText(param1, "%t", "item_owned");
				
			}
			if(GetWeaponidByName("weapon_ak47") != PlayerItems[param1][0][0])
			{
				if(PlayerisProtected[param1])
				{
					PrintToChat(param1, "[SM] %t", "bought_item", "ak47");
					PlayerItems[param1][0][0] = GetWeaponidByName("weapon_ak47");
					PlayerItems[param1][0][1] = 1;
				}
				
				else if(!StrEqual(weaponname, "weapon_ak47", false))
				{
					SetClientMoney(param1, ClientCash - ak47_cost);
					GivePlayerItem(param1, "weapon_ak47");
					GivePlayerItem(param1, weaponname);
					LastPrimaryWeapon[param1] = 9;	
				}
			}
			else
			PrintCenterText(param1, "%t", "item_owned");
		}
		else if(param2 == 10 && ClientCash >= scout_cost && scout_cost != -1)
		{
			if(weaponid != -1)
			{
				
				GetEdictClassname(weaponid, weaponname, sizeof(weaponname));
				if(!StrEqual(weaponname, "weapon_scout", false))
					RemovePlayerItem(param1, weaponid);
				else
				PrintCenterText(param1, "%t", "item_owned");
				
			}
			if(GetWeaponidByName("weapon_scout") != PlayerItems[param1][0][0])
			{
				if(PlayerisProtected[param1])
				{
					PrintToChat(param1, "[SM] %t", "bought_item", "scout");
					PlayerItems[param1][0][0] = GetWeaponidByName("weapon_scout");
					PlayerItems[param1][0][1] = 1;
				}
				
				else if(!StrEqual(weaponname, "weapon_scout", false))
				{
					SetClientMoney(param1, ClientCash - scout_cost);
					GivePlayerItem(param1, "weapon_scout");
					GivePlayerItem(param1, weaponname);
					LastPrimaryWeapon[param1] = 10;	
				}
			}
			else
			PrintCenterText(param1, "%t", "item_owned");
		}
		else if(param2 == 11 && ClientCash >= m4a1_cost && m4a1_cost != -1)
		{
			if(weaponid != -1)
			{
				
				GetEdictClassname(weaponid, weaponname, sizeof(weaponname));
				if(!StrEqual(weaponname, "weapon_m4a1", false))
					RemovePlayerItem(param1, weaponid);
				else
				PrintCenterText(param1, "%t", "item_owned");
				
			}
			if(GetWeaponidByName("weapon_m4a1") != PlayerItems[param1][0][0])
			{
				if(PlayerisProtected[param1])
				{
					PrintToChat(param1, "[SM] %t", "bought_item", "m4a1");
					PlayerItems[param1][0][0] = GetWeaponidByName("weapon_m4a1");
					PlayerItems[param1][0][1] = 1;
				}
				
				else if(!StrEqual(weaponname, "weapon_m4a1", false))
				{
					SetClientMoney(param1, ClientCash - m4a1_cost);
					GivePlayerItem(param1, "weapon_m4a1");
					GivePlayerItem(param1, weaponname);
					LastPrimaryWeapon[param1] = 11;
				}
			}
			else
			PrintCenterText(param1, "%t", "item_owned");
		}
		else if(param2 == 12 && ClientCash >= aug_cost && aug_cost != -1)
		{
			if(weaponid != -1)
			{
				
				GetEdictClassname(weaponid, weaponname, sizeof(weaponname));
				if(!StrEqual(weaponname, "weapon_aug", false))
					RemovePlayerItem(param1, weaponid);
				else
				PrintCenterText(param1, "%t", "item_owned");
			}
			
			if(GetWeaponidByName("weapon_aug") != PlayerItems[param1][0][0])
			{
				if(PlayerisProtected[param1])
				{
					PrintToChat(param1, "[SM] %t", "bought_item", "aug");
					PlayerItems[param1][0][0] = GetWeaponidByName("weapon_aug");
					PlayerItems[param1][0][1] = 1;
				}
				
				else if(!StrEqual(weaponname, "weapon_aug", false))
				{
					SetClientMoney(param1, ClientCash - aug_cost);
					GivePlayerItem(param1, "weapon_aug");
					GivePlayerItem(param1, weaponname);
					LastPrimaryWeapon[param1] = 12;	
				}
			}
			else
			PrintCenterText(param1, "%t", "item_owned");
		}
		else if(param2 == 13 && ClientCash >= sg552_cost && sg552_cost != -1)
		{
			if(weaponid != -1)
			{
				
				GetEdictClassname(weaponid, weaponname, sizeof(weaponname));
				if(!StrEqual(weaponname, "weapon_sg552", false))
					RemovePlayerItem(param1, weaponid);
				else
				PrintCenterText(param1, "%t", "item_owned");
				
			}
			
			if(GetWeaponidByName("weapon_sg552") != PlayerItems[param1][0][0])
			{
				if(PlayerisProtected[param1])
				{
					PrintToChat(param1, "[SM] %t", "bought_item", "sg552");
					PlayerItems[param1][0][0] = GetWeaponidByName("weapon_sg552");
					PlayerItems[param1][0][1] = 1;
				}
				
				else if(!StrEqual(weaponname, "weapon_sg552", false))
				{
					SetClientMoney(param1, ClientCash - sg552_cost);
					GivePlayerItem(param1, "weapon_sg552");
					GivePlayerItem(param1, weaponname);
					LastPrimaryWeapon[param1] = 13;	
				}
			}
			else
			PrintCenterText(param1, "%t", "item_owned");
		}
		else if(param2 == 14 && ClientCash >= sg550_cost && sg550_cost != -1)
		{
			if(weaponid != -1)
			{
				
				GetEdictClassname(weaponid, weaponname, sizeof(weaponname));
				if(!StrEqual(weaponname, "weapon_sg550", false))
					RemovePlayerItem(param1, weaponid);
				else
				PrintCenterText(param1, "%t", "item_owned");
				
			}
			
			if(GetWeaponidByName("weapon_sg550") != PlayerItems[param1][0][0])
			{
				if(PlayerisProtected[param1])
				{
					PrintToChat(param1, "[SM] %t", "bought_item", "sg550");
					PlayerItems[param1][0][0] = GetWeaponidByName("weapon_sg550");
					PlayerItems[param1][0][1] = 1;
				}
				
				else if(!StrEqual(weaponname, "weapon_sg550", false))
				{
					SetClientMoney(param1, ClientCash - sg550_cost);
					GivePlayerItem(param1, "weapon_sg550");
					GivePlayerItem(param1, weaponname);
					LastPrimaryWeapon[param1] = 14;	
				}
			}
			else
			PrintCenterText(param1, "%t", "item_owned");
		}
		else if(param2 == 15 && ClientCash >= awp_cost && awp_cost != -1)
		{
			if(weaponid != -1)
			{
				
				GetEdictClassname(weaponid, weaponname, sizeof(weaponname));
				if(!StrEqual(weaponname, "weapon_awp", false))
					RemovePlayerItem(param1, weaponid);
				else
				PrintCenterText(param1, "%t", "item_owned");
				
			}
			if(GetWeaponidByName("weapon_awp") != PlayerItems[param1][0][0])
			{
				if(PlayerisProtected[param1])
				{
					PrintToChat(param1, "[SM] %t", "bought_item", "awp");
					PlayerItems[param1][0][0] = GetWeaponidByName("weapon_awp");
					PlayerItems[param1][0][1] = 1;
				}
				
				else if(!StrEqual(weaponname, "weapon_awp", false))
				{
					SetClientMoney(param1, ClientCash - awp_cost);
					GivePlayerItem(param1, "weapon_awp");
					GivePlayerItem(param1, weaponname);
					LastPrimaryWeapon[param1] = 15;
				}
			}
			else
			PrintCenterText(param1, "%t", "item_owned");
		}
		else if(param2 == 16 && ClientCash >= g3sg1_cost && g3sg1_cost != -1)
		{
			if(weaponid != -1)
			{
				
				GetEdictClassname(weaponid, weaponname, sizeof(weaponname));
				if(!StrEqual(weaponname, "weapon_g3sg1", false))
					RemovePlayerItem(param1, weaponid);
				else
				PrintCenterText(param1, "%t", "item_owned");
				
			}
			
			if(GetWeaponidByName("weapon_g3sg1") != PlayerItems[param1][0][0])
			{
				if(PlayerisProtected[param1])
				{
					PrintToChat(param1, "[SM] %t", "bought_item", "g3sg1");
					PlayerItems[param1][0][0] = GetWeaponidByName("weapon_g3sg1");
					PlayerItems[param1][0][1] = 1;
				}
				
				else if(!StrEqual(weaponname, "weapon_g3sg1", false))
				{
					SetClientMoney(param1, ClientCash - g3sg1_cost);
					GivePlayerItem(param1, "weapon_g3sg1");
					GivePlayerItem(param1, weaponname);
					LastPrimaryWeapon[param1] = 16;	
				}
			}
			else
			PrintCenterText(param1, "%t", "item_owned");
		}
		else if(param2 == 17 && ClientCash >= m249_cost && m249_cost != -1)
		{			
			if(weaponid != -1)
			{
				
				GetEdictClassname(weaponid, weaponname, sizeof(weaponname));
				if(!StrEqual(weaponname, "weapon_m249", false))
					RemovePlayerItem(param1, weaponid);
				else
				PrintCenterText(param1, "%t", "item_owned");
				
			}
			
			if(GetWeaponidByName("weapon_m249") != PlayerItems[param1][0][0])
			{
				if(PlayerisProtected[param1])
				{
					PrintToChat(param1, "[SM] %t", "bought_item", "m249");
					PlayerItems[param1][0][0] = GetWeaponidByName("weapon_m249");
					PlayerItems[param1][0][1] = 1;
				}
				
				else if(!StrEqual(weaponname, "weapon_m249", false))
				{
					SetClientMoney(param1, ClientCash - m249_cost);
					GivePlayerItem(param1, "weapon_m249");
					GivePlayerItem(param1, weaponname);
					LastPrimaryWeapon[param1] = 17;	
				}
			}
			else
			PrintCenterText(param1, "%t", "item_owned");
		}
		else if(param2 == 0 && ClientCredits[param1] > 0 && m3_cost != -1)
		{
			if(weaponid != -1)
			{
				
				GetEdictClassname(weaponid, weaponname, sizeof(weaponname));
				if(!StrEqual(weaponname, "weapon_m3", false))
					RemovePlayerItem(param1, weaponid);
				else
				PrintCenterText(param1, "%t", "item_owned");
			}
			if(GetWeaponidByName("weapon_m3") != PlayerItems[param1][0][0])
			{
				if(PlayerisProtected[param1])
				{
					PrintToChat(param1, "[SM] %t", "bought_item", "shotgun");
					PlayerItems[param1][0][0] = GetWeaponidByName("weapon_m3");
					PlayerItems[param1][0][1] = 1;
				}
				
				else if(!StrEqual(weaponname, "weapon_m3", false))
				{
					ClientCredits[param1]--;
					GivePlayerItem(param1, "weapon_m3");
					GivePlayerItem(param1, weaponname);
					LastPrimaryWeapon[param1] = 0;	
				}
			}
			else
			PrintCenterText(param1, "%t", "item_owned");
		}
		else if(param2 == 1 && ClientCredits[param1] > 0 && xm1014_cost != -1)
		{			
			if(weaponid != -1)
			{
				
				GetEdictClassname(weaponid, weaponname, sizeof(weaponname));
				if(!StrEqual(weaponname, "weapon_xm1014", false))
					RemovePlayerItem(param1, weaponid);
				else
				PrintCenterText(param1, "%t", "item_owned");
			}
			
			if(GetWeaponidByName("weapon_xm1014") != PlayerItems[param1][0][0])
			{
				if(PlayerisProtected[param1])
				{
					PrintToChat(param1, "[SM] %t", "bought_item", "auto shotgun");
					PlayerItems[param1][0][0] = GetWeaponidByName("weapon_xm1014");
					PlayerItems[param1][0][1] = 1;
				}
				
				else if(!StrEqual(weaponname, "weapon_xm1014", false))
				{
					ClientCredits[param1]--;
					GivePlayerItem(param1, "weapon_xm1014");
					GivePlayerItem(param1, weaponname);
					LastPrimaryWeapon[param1] = 1;	
				}
			}
			else
			PrintCenterText(param1, "%t", "item_owned");
		}
		else if(param2 == 2 && ClientCredits[param1] > 0 && tmp_cost != -1)
		{			
			if(weaponid != -1)
			{
				
				GetEdictClassname(weaponid, weaponname, sizeof(weaponname));
				if(!StrEqual(weaponname, "weapon_tmp", false))
					RemovePlayerItem(param1, weaponid);
				else
				PrintCenterText(param1, "%t", "item_owned");
				
			}
			
			if(GetWeaponidByName("weapon_tmp") != PlayerItems[param1][0][0])
			{
				if(PlayerisProtected[param1])
				{
					PrintToChat(param1, "[SM] %t", "bought_item", "tmp");
					PlayerItems[param1][0][0] = GetWeaponidByName("weapon_tmp");
					PlayerItems[param1][0][1] = 1;
				}
				
				else if(!StrEqual(weaponname, "weapon_tmp", false))
				{
					ClientCredits[param1]--;
					GivePlayerItem(param1, "weapon_tmp");
					GivePlayerItem(param1, weaponname);
					LastPrimaryWeapon[param1] = 2;
				}
			}
			else
			PrintCenterText(param1, "%t", "item_owned");
		}
		else if(param2 == 3 && ClientCredits[param1] > 0 && mac10_cost != -1)
		{			
			if(weaponid != -1)
			{
				
				GetEdictClassname(weaponid, weaponname, sizeof(weaponname));
				if(!StrEqual(weaponname, "weapon_mac10", false))
					RemovePlayerItem(param1, weaponid);
				else
				PrintCenterText(param1, "%t", "item_owned");
				
			}
			
			if(GetWeaponidByName("weapon_mac10") != PlayerItems[param1][0][0])
			{
				if(PlayerisProtected[param1])
				{
					PrintToChat(param1, "[SM] %t", "bought_item", "mac10");
					PlayerItems[param1][0][0] = GetWeaponidByName("weapon_mac10");
					PlayerItems[param1][0][1] = 1;
				}
				
				else if(!StrEqual(weaponname, "weapon_mac10", false))
				{
					ClientCredits[param1]--;
					GivePlayerItem(param1, "weapon_mac10");
					GivePlayerItem(param1, weaponname);
					LastPrimaryWeapon[param1] = 3;
				}
			}
			else
			PrintCenterText(param1, "%t", "item_owned");
		}
		else if(param2 == 4 && ClientCredits[param1] > 0 && mp5navy_cost != -1)
		{
			if(weaponid != -1)
			{
				
				
				GetEdictClassname(weaponid, weaponname, sizeof(weaponname));
				if(!StrEqual(weaponname, "weapon_mp5navy", false))
					RemovePlayerItem(param1, weaponid);
				else
				PrintCenterText(param1, "%t", "item_owned");
				
			}
			
			if(GetWeaponidByName("weapon_mp5navy") != PlayerItems[param1][0][0])
			{
				if(PlayerisProtected[param1])
				{
					PrintToChat(param1, "[SM] %t", "bought_item", "mp5navy");
					PlayerItems[param1][0][0] = GetWeaponidByName("weapon_mp5navy");
					PlayerItems[param1][0][1] = 1;
				}
				
				else if(!StrEqual(weaponname, "weapon_mp5navy", false))
				{
					ClientCredits[param1]--;
					GivePlayerItem(param1, "weapon_mp5navy");
					GivePlayerItem(param1, weaponname);
					LastPrimaryWeapon[param1] = 4;
				}
			}
			else
			PrintCenterText(param1, "%t", "item_owned");
		}
		else if(param2 == 5 && ClientCredits[param1] > 0 && ump45_cost != -1)
		{
			if(weaponid != -1)
			{
				
				GetEdictClassname(weaponid, weaponname, sizeof(weaponname));
				if(!StrEqual(weaponname, "weapon_ump45", false))
					RemovePlayerItem(param1, weaponid);
				else
				PrintCenterText(param1, "%t", "item_owned");
				
			}
			
			if(GetWeaponidByName("weapon_ump45") != PlayerItems[param1][0][0])
			{
				if(PlayerisProtected[param1])
				{
					PrintToChat(param1, "[SM] %t", "bought_item", "ump45");
					PlayerItems[param1][0][0] = GetWeaponidByName("weapon_ump45");
					PlayerItems[param1][0][1] = 1;
				}
				
				else if(!StrEqual(weaponname, "weapon_ump45", false))
				{
					ClientCredits[param1]--;
					GivePlayerItem(param1, "weapon_ump45");
					GivePlayerItem(param1, weaponname);
					LastPrimaryWeapon[param1] = 5;
				}
			}
			else
			PrintCenterText(param1, "%t", "item_owned");
		}
		else if(param2 == 6 && ClientCredits[param1] > 0 && p90_cost != -1)
		{
			if(weaponid != -1)
			{
				
				GetEdictClassname(weaponid, weaponname, sizeof(weaponname));
				if(!StrEqual(weaponname, "weapon_p90", false))
					RemovePlayerItem(param1, weaponid);
				else
				PrintCenterText(param1, "%t", "item_owned");
				
			}
			
			if(GetWeaponidByName("weapon_p90") != PlayerItems[param1][0][0])
			{
				if(PlayerisProtected[param1])
				{
					PrintToChat(param1, "[SM] %t", "bought_item", "p90");
					PlayerItems[param1][0][0] = GetWeaponidByName("weapon_p90");
					PlayerItems[param1][0][1] = 1;
				}
				
				else if(!StrEqual(weaponname, "weapon_p90", false))
				{
					ClientCredits[param1]--;
					GivePlayerItem(param1, "weapon_p90");
					GivePlayerItem(param1, weaponname);
					LastPrimaryWeapon[param1] = 6;
				}
			}
			else
			PrintCenterText(param1, "%t", "item_owned");
		}
		else if(param2 == 7 && ClientCredits[param1] > 0 && galil_cost != -1)
		{
			if(weaponid != -1)
			{
				
				GetEdictClassname(weaponid, weaponname, sizeof(weaponname));
				if(!StrEqual(weaponname, "weapon_galil", false))
					RemovePlayerItem(param1, weaponid);
				else
				PrintCenterText(param1, "%t", "item_owned");
				
			}
			
			if(GetWeaponidByName("weapon_galil") != PlayerItems[param1][0][0])
			{
				if(PlayerisProtected[param1])
				{
					PrintToChat(param1, "[SM] %t", "bought_item", "galil");
					PlayerItems[param1][0][0] = GetWeaponidByName("weapon_galil");
					PlayerItems[param1][0][1] = 1;
				}
				
				else if(!StrEqual(weaponname, "weapon_galil", false))
				{
					ClientCredits[param1]--;
					GivePlayerItem(param1, "weapon_galil");
					GivePlayerItem(param1, weaponname);
					LastPrimaryWeapon[param1] = 7;	
				}
			}
			else
			PrintCenterText(param1, "%t", "item_owned");
		}
		else if(param2 == 8 && ClientCredits[param1] > 0 && famas_cost != -1)
		{
			if(weaponid != -1)
			{
				
				GetEdictClassname(weaponid, weaponname, sizeof(weaponname));
				if(!StrEqual(weaponname, "weapon_famas", false))
					RemovePlayerItem(param1, weaponid);
				else
				PrintCenterText(param1, "%t", "item_owned");
				
			}
			
			if(GetWeaponidByName("weapon_famas") != PlayerItems[param1][0][0])
			{
				if(PlayerisProtected[param1])
				{
					PrintToChat(param1, "[SM] %t", "bought_item", "famas");
					PlayerItems[param1][0][0] = GetWeaponidByName("weapon_famas");
					PlayerItems[param1][0][1] = 1;
				}
				
				else if(!StrEqual(weaponname, "weapon_famas", false))
				{
					ClientCredits[param1]--;
					GivePlayerItem(param1, "weapon_famas");
					GivePlayerItem(param1, weaponname);
					LastPrimaryWeapon[param1] = 8;	
				}
			}
			else
			PrintCenterText(param1, "%t", "item_owned");
		}
		else if(param2 == 9 && ClientCredits[param1] > 0 && ak47_cost != -1)
		{
			if(weaponid != -1)
			{
				
				GetEdictClassname(weaponid, weaponname, sizeof(weaponname));
				if(!StrEqual(weaponname, "weapon_ak47", false))
					RemovePlayerItem(param1, weaponid);
				else
				PrintCenterText(param1, "%t", "item_owned");
				
			}
			
			if(GetWeaponidByName("weapon_ak47") != PlayerItems[param1][0][0])
			{
				if(PlayerisProtected[param1])
				{
					PrintToChat(param1, "[SM] %t", "bought_item", "ak47");
					PlayerItems[param1][0][0] = GetWeaponidByName("weapon_ak47");
					PlayerItems[param1][0][1] = 1;
				}
				
				else if(!StrEqual(weaponname, "weapon_famas", false))
				{
					ClientCredits[param1]--;
					GivePlayerItem(param1, "weapon_ak47");
					GivePlayerItem(param1, weaponname);
					LastPrimaryWeapon[param1] = 9;	
				}
			}
			else
			PrintCenterText(param1, "%t", "item_owned");
		}
		else if(param2 == 10 && ClientCredits[param1] > 0 && scout_cost != -1)
		{
			if(weaponid != -1)
			{
				
				GetEdictClassname(weaponid, weaponname, sizeof(weaponname));
				if(!StrEqual(weaponname, "weapon_scout", false))
					RemovePlayerItem(param1, weaponid);
				else
				PrintCenterText(param1, "%t", "item_owned");
				
			}
			
			if(GetWeaponidByName("weapon_scout") != PlayerItems[param1][0][0])
			{
				if(PlayerisProtected[param1])
				{
					PrintToChat(param1, "[SM] %t", "bought_item", "scout");
					PlayerItems[param1][0][0] = GetWeaponidByName("weapon_scout");
					PlayerItems[param1][0][1] = 1;
				}
				
				else if(!StrEqual(weaponname, "weapon_scout", false))
				{
					ClientCredits[param1]--;
					GivePlayerItem(param1, "weapon_scout");
					GivePlayerItem(param1, weaponname);
					LastPrimaryWeapon[param1] = 10;	
				}
			}
			else
			PrintCenterText(param1, "%t", "item_owned");
		}
		else if(param2 == 11 && ClientCredits[param1] > 0 && m4a1_cost != -1)
		{
			if(weaponid != -1)
			{
				
				GetEdictClassname(weaponid, weaponname, sizeof(weaponname));
				if(!StrEqual(weaponname, "weapon_m4a1", false))
					RemovePlayerItem(param1, weaponid);
				else
				PrintCenterText(param1, "%t", "item_owned");
				
			}
			
			if(GetWeaponidByName("weapon_m4a1") != PlayerItems[param1][0][0])
			{
				if(PlayerisProtected[param1])
				{
					PrintToChat(param1, "[SM] %t", "bought_item", "m4a1");
					PlayerItems[param1][0][0] = GetWeaponidByName("weapon_m4a1");
					PlayerItems[param1][0][1] = 1;
				}
				
				else if(!StrEqual(weaponname, "weapon_m4a1", false))
				{
					ClientCredits[param1]--;
					GivePlayerItem(param1, "weapon_m4a1");
					GivePlayerItem(param1, weaponname);
					LastPrimaryWeapon[param1] = 11;	
				}
			}
			else
			PrintCenterText(param1, "%t", "item_owned");
		}
		else if(param2 == 12 && ClientCredits[param1] > 0 && aug_cost != -1)
		{
			if(weaponid != -1)
			{
				
				GetEdictClassname(weaponid, weaponname, sizeof(weaponname));
				if(!StrEqual(weaponname, "weapon_aug", false))
					RemovePlayerItem(param1, weaponid);
				else
				PrintCenterText(param1, "%t", "item_owned");
			}
			
			if(GetWeaponidByName("weapon_aug") != PlayerItems[param1][0][0])
			{
				if(PlayerisProtected[param1])
				{
					PrintToChat(param1, "[SM] %t", "bought_item", "aug");
					PlayerItems[param1][0][0] = GetWeaponidByName("weapon_aug");
					PlayerItems[param1][0][1] = 1;
				}
				
				else if(!StrEqual(weaponname, "weapon_aug", false))
				{
					ClientCredits[param1]--;
					GivePlayerItem(param1, "weapon_aug");
					GivePlayerItem(param1, weaponname);
					LastPrimaryWeapon[param1] = 12;
				}
			}
			else
			PrintCenterText(param1, "%t", "item_owned");
		}
		else if(param2 == 13 && ClientCredits[param1] > 0 && sg552_cost != -1)
		{
			if(weaponid != -1)
			{
				
				GetEdictClassname(weaponid, weaponname, sizeof(weaponname));
				if(!StrEqual(weaponname, "weapon_sg552", false))
					RemovePlayerItem(param1, weaponid);
				else
				PrintCenterText(param1, "%t", "item_owned");
				
			}
			
			if(GetWeaponidByName("weapon_sg552") != PlayerItems[param1][0][0])
			{
				if(PlayerisProtected[param1])
				{
					PrintToChat(param1, "[SM] %t", "bought_item", "sg552");
					PlayerItems[param1][0][0] = GetWeaponidByName("weapon_sg552");
					PlayerItems[param1][0][1] = 1;
				}
				
				else if(!StrEqual(weaponname, "weapon_sg552", false))
				{
					ClientCredits[param1]--;
					GivePlayerItem(param1, "weapon_sg552");
					GivePlayerItem(param1, weaponname);
					LastPrimaryWeapon[param1] = 13;
				}
			}
			else
			PrintCenterText(param1, "%t", "item_owned");
		}
		else if(param2 == 14 && ClientCredits[param1] > 0 && sg550_cost != -1)
		{
			if(weaponid != -1)
			{
				
				GetEdictClassname(weaponid, weaponname, sizeof(weaponname));
				if(!StrEqual(weaponname, "weapon_sg550", false))
					RemovePlayerItem(param1, weaponid);
				else
				PrintCenterText(param1, "%t", "item_owned");
				
			}
			
			if(GetWeaponidByName("weapon_sg550") != PlayerItems[param1][0][0])
			{
				if(PlayerisProtected[param1])
				{
					PrintToChat(param1, "[SM] %t", "bought_item", "sg550");
					PlayerItems[param1][0][0] = GetWeaponidByName("weapon_sg550");
					PlayerItems[param1][0][1] = 1;
				}
				
				else if(!StrEqual(weaponname, "weapon_sg550", false))
				{
					ClientCredits[param1]--;
					GivePlayerItem(param1, "weapon_sg550");
					GivePlayerItem(param1, weaponname);
					LastPrimaryWeapon[param1] = 14;	
				}
			}
			else
			PrintCenterText(param1, "%t", "item_owned");
		}
		else if(param2 == 15 && ClientCredits[param1] > 0 && awp_cost != -1)
		{
			if(weaponid != -1)
			{
				
				GetEdictClassname(weaponid, weaponname, sizeof(weaponname));
				if(!StrEqual(weaponname, "weapon_awp", false))
					RemovePlayerItem(param1, weaponid);
				else
				PrintCenterText(param1, "%t", "item_owned");
				
			}
			
			if(GetWeaponidByName("weapon_awp") != PlayerItems[param1][0][0])
			{
				if(PlayerisProtected[param1])
				{
					PrintToChat(param1, "[SM] %t", "bought_item", "awp");
					PlayerItems[param1][0][0] = GetWeaponidByName("weapon_awp");
					PlayerItems[param1][0][1] = 1;
				}
				
				else if(!StrEqual(weaponname, "weapon_awp", false))
				{
					ClientCredits[param1]--;
					GivePlayerItem(param1, "weapon_awp");
					GivePlayerItem(param1, weaponname);
					LastPrimaryWeapon[param1] = 15;	
				}
			}
			else
			PrintCenterText(param1, "%t", "item_owned");
		}
		else if(param2 == 16 && ClientCredits[param1] > 0 && g3sg1_cost != -1)
		{
			if(weaponid != -1)
			{
				
				GetEdictClassname(weaponid, weaponname, sizeof(weaponname));
				if(!StrEqual(weaponname, "weapon_g3sg1", false))
					RemovePlayerItem(param1, weaponid);
				else
				PrintCenterText(param1, "%t", "item_owned");
				
			}
			
			if(GetWeaponidByName("weapon_g3sg1") != PlayerItems[param1][0][0])
			{
				if(PlayerisProtected[param1])
				{
					PrintToChat(param1, "[SM] %t", "bought_item", "g3sg1");
					PlayerItems[param1][0][0] = GetWeaponidByName("weapon_g3sg1");
					PlayerItems[param1][0][1] = 1;
				}
				
				else if(!StrEqual(weaponname, "weapon_g3sg1", false))
				{
					ClientCredits[param1]--;
					GivePlayerItem(param1, "weapon_g3sg1");
					GivePlayerItem(param1, weaponname);
					LastPrimaryWeapon[param1] = 16;	
				}
			}
			else
			PrintCenterText(param1, "%t", "item_owned");
		}
		else if(param2 == 17 && ClientCredits[param1] > 0 && m249_cost != -1)
		{			
			if(weaponid != -1)
			{
				
				GetEdictClassname(weaponid, weaponname, sizeof(weaponname));
				if(!StrEqual(weaponname, "weapon_m249", false))
					RemovePlayerItem(param1, weaponid);
				else
				PrintCenterText(param1, "%t", "item_owned");
				
			}
			
			if(GetWeaponidByName("weapon_m249") != PlayerItems[param1][0][0])
			{
				if(PlayerisProtected[param1])
				{
					PrintToChat(param1, "[SM] %t", "bought_item", "m249");
					PlayerItems[param1][0][0] = GetWeaponidByName("weapon_m249");
					PlayerItems[param1][0][1] = 1;
				}
				
				else if(!StrEqual(weaponname, "weapon_m249", false))
				{
					ClientCredits[param1]--;
					GivePlayerItem(param1, "weapon_m249");
					GivePlayerItem(param1, weaponname);
					LastPrimaryWeapon[param1] = 17;	
				}
			}
			else
			PrintCenterText(param1, "%t", "item_owned");
		}
		ManageAccounts(param1);
	}
}



public RebuySecondary(param1, param2)
{
	if(param2 != -1)
	{
		new weaponid = GetPlayerWeaponSlot(param1, 1);
		new String:weaponname[32];
		new ClientCash = GetClientMoney(param1);
		if(param2 == 0 && ClientCash >= glock_cost && glock_cost != -1)
		{
			if(weaponid != -1)
			{
				
				GetEdictClassname(weaponid, weaponname, sizeof(weaponname));
				if(!StrEqual(weaponname, "weapon_glock", false))
					RemovePlayerItem(param1, weaponid);
				else
				PrintCenterText(param1, "%t", "item_owned");
				
			}
			
			if(GetWeaponidByName("weapon_glock") != PlayerItems[param1][1][0])
			{
				if(PlayerisProtected[param1])
				{
					PrintToChat(param1, "[SM] %t", "bought_item", "glock");
					PlayerItems[param1][1][0] = GetWeaponidByName("weapon_glock");
					PlayerItems[param1][1][1] = 1;
				}
				
				else if(!StrEqual(weaponname, "weapon_glock", false))
				{
					SetClientMoney(param1, ClientCash - glock_cost);
					GivePlayerItem(param1, "weapon_glock");
					GivePlayerItem(param1, weaponname);
					LastSecondaryWeapon[param1] = 0;
				}
			}
			else
			PrintCenterText(param1, "%t", "item_owned");
		}
		else if(param2 == 1 && ClientCash >= usp_cost && usp_cost != -1)
		{
			if(weaponid != -1)
			{
				
				GetEdictClassname(weaponid, weaponname, sizeof(weaponname));
				if(!StrEqual(weaponname, "weapon_usp", false))
					RemovePlayerItem(param1, weaponid);
				else
				PrintCenterText(param1, "%t", "item_owned");
				
			}
			
			if(GetWeaponidByName("weapon_usp") != PlayerItems[param1][1][0])
			{
				if(PlayerisProtected[param1])
				{
					PrintToChat(param1, "[SM] %t", "bought_item", "usp");
					PlayerItems[param1][1][0] = GetWeaponidByName("weapon_usp");
					PlayerItems[param1][1][1] = 1;
				}
				
				else if(!StrEqual(weaponname, "weapon_usp", false))
				{
					SetClientMoney(param1, ClientCash - usp_cost);
					GivePlayerItem(param1, "weapon_usp");
					GivePlayerItem(param1, weaponname);
					LastSecondaryWeapon[param1] = 1;
				}
			}
			else
			PrintCenterText(param1, "%t", "item_owned");
		}
		else if(param2 == 2 && ClientCash >= p228_cost && p228_cost != -1)
		{
			if(weaponid != -1)
			{
				
				GetEdictClassname(weaponid, weaponname, sizeof(weaponname));
				if(!StrEqual(weaponname, "weapon_p228", false))
					RemovePlayerItem(param1, weaponid);
				else
				PrintCenterText(param1, "%t", "item_owned");
				
			}
			
			if(GetWeaponidByName("weapon_p228") != PlayerItems[param1][1][0])
			{
				if(PlayerisProtected[param1])
				{
					PrintToChat(param1, "[SM] %t", "bought_item", "p228");
					PlayerItems[param1][1][0] = GetWeaponidByName("weapon_p228");
					PlayerItems[param1][1][1] = 1;
				}
				
				else if(!StrEqual(weaponname, "weapon_p228", false))
				{
					SetClientMoney(param1, ClientCash - p228_cost);
					GivePlayerItem(param1, "weapon_p228");
					GivePlayerItem(param1, weaponname);
					LastSecondaryWeapon[param1] = 2;
				}
			}
			else
			PrintCenterText(param1, "%t", "item_owned");
		}
		else if(param2 == 3 && ClientCash >= deagle_cost && deagle_cost != -1)
		{
			if(weaponid != -1)
			{
				
				GetEdictClassname(weaponid, weaponname, sizeof(weaponname));
				if(!StrEqual(weaponname, "weapon_deagle", false))
					RemovePlayerItem(param1, weaponid);
				else
				PrintCenterText(param1, "%t", "item_owned");
				
			}
			
			if(GetWeaponidByName("weapon_deagle") != PlayerItems[param1][1][0])
			{
				if(PlayerisProtected[param1])
				{
					PrintToChat(param1, "[SM] %t", "bought_item", "desert eagle");
					PlayerItems[param1][1][0] = GetWeaponidByName("weapon_deagle");
					PlayerItems[param1][1][1] = 1;
				}
				
				else if(!StrEqual(weaponname, "weapon_deagle", false))
				{
					SetClientMoney(param1, ClientCash - deagle_cost);
					GivePlayerItem(param1, "weapon_deagle");
					GivePlayerItem(param1, weaponname);
					LastSecondaryWeapon[param1] = 3;
				}
			}
			else
			PrintCenterText(param1, "%t", "item_owned");
		}
		else if(param2 == 4 && ClientCash >= fiveseven_cost && fiveseven_cost != -1)
		{
			if(weaponid != -1)
			{
				
				GetEdictClassname(weaponid, weaponname, sizeof(weaponname));
				if(!StrEqual(weaponname, "weapon_fiveseven", false))
					RemovePlayerItem(param1, weaponid);
				else
				PrintCenterText(param1, "%t", "item_owned");
				
			}
			
			if(GetWeaponidByName("weapon_fiveseven") != PlayerItems[param1][1][0])
			{
				if(PlayerisProtected[param1])
				{
					PrintToChat(param1, "[SM] %t", "bought_item", "fiveseven");
					PlayerItems[param1][1][0] = GetWeaponidByName("weapon_fiveseven");
					PlayerItems[param1][1][1] = 1;
				}
				
				else if(!StrEqual(weaponname, "weapon_fiveseven", false))
				{
					SetClientMoney(param1, ClientCash - fiveseven_cost);
					GivePlayerItem(param1, "weapon_fiveseven");
					GivePlayerItem(param1, weaponname);
					LastSecondaryWeapon[param1] = 4;
				}
			}
			else
			PrintCenterText(param1, "%t", "item_owned");
		}
		else if(param2 == 5 && ClientCash >= elite_cost && elite_cost != -1)
		{
			if(weaponid != -1)
			{
				
				GetEdictClassname(weaponid, weaponname, sizeof(weaponname));
				if(!StrEqual(weaponname, "weapon_elite", false))
					RemovePlayerItem(param1, weaponid);
				else
				PrintCenterText(param1, "%t", "item_owned");
				
			}
			
			if(GetWeaponidByName("weapon_elite") != PlayerItems[param1][1][0])
			{
				if(PlayerisProtected[param1])
				{
					PrintToChat(param1, "[SM] %t", "bought_item", "dual Bereta elites");
					PlayerItems[param1][1][0] = GetWeaponidByName("weapon_elite");
					PlayerItems[param1][1][1] = 1;
				}
				
				else if(!StrEqual(weaponname, "weapon_elite", false))
				{
					SetClientMoney(param1, ClientCash - elite_cost);
					GivePlayerItem(param1, "weapon_elite");
					GivePlayerItem(param1, weaponname);
					LastSecondaryWeapon[param1] = 5;
				}
			}
			else
			PrintCenterText(param1, "%t", "item_owned");
		}
		else if(param2 == 0 && ClientCredits[param1] > 0 && glock_cost != -1)
		{
			if(weaponid != -1)
			{
				
				GetEdictClassname(weaponid, weaponname, sizeof(weaponname));
				if(!StrEqual(weaponname, "weapon_glock", false))
					RemovePlayerItem(param1, weaponid);
				else
				PrintCenterText(param1, "%t", "item_owned");
				
			}
			
			if(GetWeaponidByName("weapon_glock") != PlayerItems[param1][1][0])
			{
				if(PlayerisProtected[param1])
				{
					PrintToChat(param1, "[SM] %t", "bought_item", "glock");
					PlayerItems[param1][1][0] = GetWeaponidByName("weapon_glock");
					PlayerItems[param1][1][1] = 1;
				}
				
				else if(!StrEqual(weaponname, "weapon_glock", false))
				{
					ClientCredits[param1]--;
					GivePlayerItem(param1, "weapon_glock");
					GivePlayerItem(param1, weaponname);
					LastSecondaryWeapon[param1] = 0;
				}
			}
			else
			PrintCenterText(param1, "%t", "item_owned");
		}
		else if(param2 == 1 && ClientCredits[param1] > 0 && usp_cost != -1)
		{
			if(weaponid != -1)
			{
				
				GetEdictClassname(weaponid, weaponname, sizeof(weaponname));
				if(!StrEqual(weaponname, "weapon_usp", false))
					RemovePlayerItem(param1, weaponid);
				else
				PrintCenterText(param1, "%t", "item_owned");
				
			}
			
			if(GetWeaponidByName("weapon_usp") != PlayerItems[param1][1][0])
			{
				if(PlayerisProtected[param1])
				{
					PrintToChat(param1, "[SM] %t", "bought_item", "usp");
					PlayerItems[param1][1][0] = GetWeaponidByName("weapon_usp");
					PlayerItems[param1][1][1] = 1;
				}
				
				else if(!StrEqual(weaponname, "weapon_usp", false))
				{
					ClientCredits[param1]--;
					GivePlayerItem(param1, "weapon_usp");
					GivePlayerItem(param1, weaponname);
					LastSecondaryWeapon[param1] = 1;
				}
			}
			else
			PrintCenterText(param1, "%t", "item_owned");
		}
		else if(param2 == 2 && ClientCredits[param1] > 0 && p228_cost != -1)
		{
			if(weaponid != -1)
			{
				
				GetEdictClassname(weaponid, weaponname, sizeof(weaponname));
				if(!StrEqual(weaponname, "weapon_p228", false))
					RemovePlayerItem(param1, weaponid);
				else
				PrintCenterText(param1, "%t", "item_owned");
				
			}
			if(GetWeaponidByName("weapon_p228") != PlayerItems[param1][1][0])
			{
				if(PlayerisProtected[param1])
				{
					PrintToChat(param1, "[SM] %t", "bought_item", "p228");
					PlayerItems[param1][1][0] = GetWeaponidByName("weapon_p228");
					PlayerItems[param1][1][1] = 1;
				}
				
				else if(!StrEqual(weaponname, "weapon_p228", false))
				{
					ClientCredits[param1]--;
					GivePlayerItem(param1, "weapon_p228");
					GivePlayerItem(param1, weaponname);
					LastSecondaryWeapon[param1] = 2;
				}
			}
			else
			PrintCenterText(param1, "%t", "item_owned");
		}
		else if(param2 == 3 && ClientCredits[param1] > 0 && deagle_cost != -1)
		{
			if(weaponid != -1)
			{
				
				GetEdictClassname(weaponid, weaponname, sizeof(weaponname));
				if(!StrEqual(weaponname, "weapon_deagle", false))
					RemovePlayerItem(param1, weaponid);
				else
				PrintCenterText(param1, "%t", "item_owned");
				
			}
			
			if(GetWeaponidByName("weapon_deagle") != PlayerItems[param1][1][0])
			{
				if(PlayerisProtected[param1])
				{
					PrintToChat(param1, "[SM] %t", "bought_item", "desert eagle");
					PlayerItems[param1][1][0] = GetWeaponidByName("weapon_deagle");
					PlayerItems[param1][1][1] = 1;
				}
				
				else if(!StrEqual(weaponname, "weapon_deagle", false))
				{
					ClientCredits[param1]--;
					GivePlayerItem(param1, "weapon_deagle");
					GivePlayerItem(param1, weaponname);
					LastSecondaryWeapon[param1] = 3;
				}
			}
			else
			PrintCenterText(param1, "%t", "item_owned");
		}
		else if(param2 == 4 && ClientCredits[param1] > 0 && fiveseven_cost != -1)
		{
			if(weaponid != -1)
			{
				
				GetEdictClassname(weaponid, weaponname, sizeof(weaponname));
				if(!StrEqual(weaponname, "weapon_fiveseven", false))
					RemovePlayerItem(param1, weaponid);
				else
				PrintCenterText(param1, "%t", "item_owned");
				
			}
			
			if(GetWeaponidByName("weapon_fiveseven") != PlayerItems[param1][1][0])
			{
				if(PlayerisProtected[param1])
				{
					PrintToChat(param1, "[SM] %t", "bought_item", "fiveseven");
					PlayerItems[param1][1][0] = GetWeaponidByName("weapon_fiveseven");
					PlayerItems[param1][1][1] = 1;
				}
				
				else if(!StrEqual(weaponname, "weapon_fiveseven", false))
				{
					ClientCredits[param1]--;
					GivePlayerItem(param1, "weapon_fiveseven");
					GivePlayerItem(param1, weaponname);
					LastSecondaryWeapon[param1] = 4;
				}
			}
			else
			PrintCenterText(param1, "%t", "item_owned");
		}
		else if(param2 == 5 && ClientCredits[param1] > 0 && elite_cost != -1)
		{
			if(weaponid != -1)
			{
				
				GetEdictClassname(weaponid, weaponname, sizeof(weaponname));
				if(!StrEqual(weaponname, "weapon_elite", false))
					RemovePlayerItem(param1, weaponid);
				else
				PrintCenterText(param1, "%t", "item_owned");
				
			}
			
			if(GetWeaponidByName("weapon_elite") != PlayerItems[param1][1][0])
			{
				if(PlayerisProtected[param1])
				{
					PrintToChat(param1, "[SM] %t", "bought_item", "dual Bereta elites");
					PlayerItems[param1][1][0] = GetWeaponidByName("weapon_elite");
					PlayerItems[param1][1][1] = 1;
				}
				
				else if(!StrEqual(weaponname, "weapon_elite", false))
				{
					ClientCredits[param1]--;
					GivePlayerItem(param1, "weapon_elite");
					GivePlayerItem(param1, weaponname);
					LastSecondaryWeapon[param1] = 5;
				}
			}
			else
			PrintCenterText(param1, "%t", "item_owned");
		}
		else
		PrintCenterText(param1, "%t", "money");
		ManageAccounts(param1);
	}
}



public RebuyEquip(param1)
{
	new i;
	new ClientCash = GetClientMoney(param1);
	new ClientTeam = GetClientTeam(param1);
	new helmet = FindSendPropOffs("CCSPlayer", "m_bHasHelmet");
	new armor = FindSendPropOffs("CCSPlayer", "m_ArmorValue");
	if(LastEquipmentItem[param1][0] == 1 && ClientCash >= kevlar && kevlar != -1)
	{
		SetEntProp(param1, Prop_Send, "m_ArmorValue", 100, 1);
		SetClientMoney(param1, ClientCash - kevlar);
	}
	else if(LastEquipmentItem[param1][0] == 1 && ClientCredits[param1] > 0 && kevlar != -1)
	{
		SetEntProp(param1, Prop_Send, "m_ArmorValue", 100, 1);
		SetClientMoney(param1, ClientCash - kevlar);
	}
	if(LastEquipmentItem[param1][1] == 1 && ClientCash >= kevlarhelmet && kevlarhelmet != -1)
	{
		if(GetEntData(param1, helmet) == 1 && GetEntData(param1, armor) == 100)
		{
			PrintCenterText(param1, "You already have a kevlar and helmet!");
		}
		else if(GetEntData(param1, armor) == 100 && GetEntData(param1, helmet) == 0)
		{
			SetEntProp(param1, Prop_Send, "m_bHasHelmet", 1, 1);
			SetClientMoney(param1, ClientCash - helmet_cost && helmet_cost != -1);
		}
		else if(GetEntData(param1, helmet) == 0 && GetEntData(param1, armor) < 100)
		{
			SetEntProp(param1, Prop_Send, "m_ArmorValue", 100, 1);
			SetEntProp(param1, Prop_Send, "m_bHasHelmet", 1, 1);
			SetClientMoney(param1, ClientCash - kevlarhelmet);
		}
	}
	else if(LastEquipmentItem[param1][1] == 1 && ClientCredits[param1] > 0 && kevlarhelmet != -1)
	{
		if(GetEntData(param1, helmet) == 1 && GetEntData(param1, armor) == 100)
		{
			PrintCenterText(param1, "You already have a kevlar and helmet!");
		}
		else if(GetEntData(param1, armor) == 100 && GetEntData(param1, helmet) == 0)
		{
			SetEntProp(param1, Prop_Send, "m_bHasHelmet", 1, 1);
			SetClientMoney(param1, ClientCash - helmet_cost && helmet_cost != -1);
		}
		else if(GetEntData(param1, helmet) == 0 && GetEntData(param1, armor) < 100)
		{
			SetEntProp(param1, Prop_Send, "m_ArmorValue", 100, 1);
			SetEntProp(param1, Prop_Send, "m_bHasHelmet", 1, 1);
			SetClientMoney(param1, ClientCash - kevlarhelmet);
		}
	}
	if(PlayerItems[param1][3][1] == 0)
	{
		if(LastEquipmentItem[param1][2] > 0 && ClientCash >= flashbang_cost && flashbang_cost != -1)
		{
			for(i = 0; i <= LastEquipmentItem[param1][2]; i++)
			{
				if(ClientCash >= flashbang_cost)
				{
					if(PlayerisProtected[param1])
					{
						PrintToChat(param1, "[SM] %t", "bought_item", "Flashbang Grenade");
						PlayerItems[param1][3][0] = GetWeaponidByName("weapon_flashbang");
						PlayerItems[param1][3][1]++;
					}
					else
					GivePlayerItem(param1, "weapon_flashbang");
					
					SetClientMoney(param1, ClientCash - flashbang_cost);
				}
			}
		}
		else if(LastEquipmentItem[param1][2] > 0 && ClientCredits[param1] > 0 && flashbang_cost != -1)
		{
			for(i = 0; i <= LastEquipmentItem[param1][2]; i++)
			{
				if(ClientCash >= flashbang_cost)
				{
					if(PlayerisProtected[param1])
					{
						PrintToChat(param1, "[SM] %t", "bought_item", "Flashbang Grenade");
						PlayerItems[param1][3][0] = GetWeaponidByName("weapon_flashbang");
						PlayerItems[param1][3][1]++;
					}
					else
					GivePlayerItem(param1, "weapon_flashbang");
					
					SetClientMoney(param1, ClientCash - flashbang_cost);
				}
			}
		}
	}
	
	if(PlayerItems[param1][4][1] == 0)
	{
		if(LastEquipmentItem[param1][3] > 0 && ClientCash >= hegrenade_cost && hegrenade_cost != -1)
		{
			for(i = 0; i <= LastEquipmentItem[param1][3]; i++)
			{
				if(ClientCash >= 300)
				{	
					if(PlayerisProtected[param1])
					{
						PrintToChat(param1, "[SM] %t", "bought_item", "HE Grenade");
						PlayerItems[param1][4][0] = GetWeaponidByName("weapon_hegrenade");
						PlayerItems[param1][4][1]++;
					}
					else
					GivePlayerItem(param1, "weapon_hegrenade");
					
					SetClientMoney(param1, ClientCash - hegrenade_cost);
				}
			}
		}
		else if(LastEquipmentItem[param1][3] > 0 && ClientCredits[param1] > 0 && hegrenade_cost != -1)
		{
			for(i = 0; i <= LastEquipmentItem[param1][3]; i++)
			{
				if(ClientCash >= 300)
				{	
					if(PlayerisProtected[param1])
					{
						PrintToChat(param1, "[SM] %t", "bought_item", "HE Grenade");
						PlayerItems[param1][4][0] = GetWeaponidByName("weapon_hegrenade");
						PlayerItems[param1][4][1]++;
					}
					else
					GivePlayerItem(param1, "weapon_hegrenade");
					
					SetClientMoney(param1, ClientCash - hegrenade_cost);
				}
			}
		}
	}
	
	if(PlayerItems[param1][5][1] == 0)
	{
		if(LastEquipmentItem[param1][4] > 0 && ClientCash >= smokegrenade_cost && smokegrenade_cost != -1)
		{
			for(i = 0; i <= LastEquipmentItem[param1][4]; i++)
			{
				if(ClientCash >= smokegrenade_cost)
				{
					if(PlayerisProtected[param1])
					{
						PrintToChat(param1, "[SM] %t", "bought_item", "Smoke Grenade");
						PlayerItems[param1][5][0] = GetWeaponidByName("weapon_smokegrenade");
						PlayerItems[param1][5][1]++;
					}
					else
					GivePlayerItem(param1, "weapon_smokegrenade");
					
					SetClientMoney(param1, ClientCash - smokegrenade_cost);
				}
			}
		}
		else if(LastEquipmentItem[param1][4] > 0 && ClientCredits[param1] > 0 && smokegrenade_cost != -1)
		{
			for(i = 0; i <= LastEquipmentItem[param1][4]; i++)
			{
				if(ClientCash >= smokegrenade_cost)
				{
					if(PlayerisProtected[param1])
					{
						PrintToChat(param1, "[SM] %t", "bought_item", "Smoke Grenade");
						PlayerItems[param1][5][0] = GetWeaponidByName("weapon_smokegrenade");
						PlayerItems[param1][5][1]++;
					}
					else
					GivePlayerItem(param1, "weapon_smokegrenade");
					
					SetClientMoney(param1, ClientCash - smokegrenade_cost);
				}
			}
		}
	}
	
	if(LastEquipmentItem[param1][5] > 0 && ClientCash >= defusekit && ClientTeam == TEAM_CT && defusekit != -1)
	{
		SetEntProp(param1, Prop_Send, "m_bHasDefuser", 1, 1);
		SetClientMoney(param1, ClientCash - defusekit);
	}
	else if(LastEquipmentItem[param1][5] > 0 && ClientCredits[param1] > 0 && ClientTeam == TEAM_CT && defusekit != -1)
	{
		SetEntProp(param1, Prop_Send, "m_bHasDefuser", 1, 1);
		SetClientMoney(param1, ClientCash - defusekit);
	}
	if(LastEquipmentItem[param1][6] > 0 && ClientCash >= nvgoggles && ClientTeam == TEAM_CT && nvgoggles != -1)
	{
		SetEntProp(param1, Prop_Send, "m_bHasNightVision", 1, 1);
		SetClientMoney(param1, ClientCash - nvgoggles);
	}
	else if(LastEquipmentItem[param1][6] > 0 && ClientCredits[param1] > 0 && ClientTeam == TEAM_CT && nvgoggles != -1)
	{
		SetEntProp(param1, Prop_Send, "m_bHasNightVision", 1, 1);
		SetClientMoney(param1, ClientCash - nvgoggles);
	}
	if(LastEquipmentItem[param1][5] > 0 && ClientCash >= nvgoggles && ClientTeam == TEAM_T && nvgoggles != -1)
	{
		SetEntProp(param1, Prop_Send, "m_bHasNightVision", 1, 1);
		SetClientMoney(param1, ClientCash - nvgoggles);
	}
	else if(LastEquipmentItem[param1][5] > 0 && ClientCredits[param1] > 0 && ClientTeam == TEAM_T && nvgoggles != -1)
	{
		SetEntProp(param1, Prop_Send, "m_bHasNightVision", 1, 1);
		SetClientMoney(param1, ClientCash - nvgoggles);
	}
}



public Buy_PriAmmo(client)
{
	new String: weaponname[32];
	new weaponid;
	new ClientCash = GetClientMoney(client);
	if(ClientCash > 100 && GetPlayerWeaponSlot(client, 0) != -1)
	{
		weaponid = GetPlayerWeaponSlot(client, 0);
		GetEdictClassname(weaponid, weaponname, sizeof(weaponname));
		RemovePlayerItem(client, weaponid);
		SetClientMoney(client, ClientCash - 100);
		GivePlayerItem(client, weaponname);
	}
}



public Buy_SecAmmo(client)
{
	new String: weaponname[32];
	new weaponid;
	new ClientCash = GetClientMoney(client);
	if(ClientCash > 90 && GetPlayerWeaponSlot(client, 1) != -1)
	{
		weaponid = GetPlayerWeaponSlot(client, 1);
		GetEdictClassname(weaponid, weaponname, sizeof(weaponname));
		RemovePlayerItem(client, weaponid);
		SetClientMoney(client, ClientCash - 90);
		GivePlayerItem(client, weaponname);
	}
}



public Buy_Menu(Handle:menu, MenuAction:action, param1, param2)
{
	if(action == MenuAction_Select)
	{
		if(buymenucont[param1] == false)
		{
			if(param2 == 0)
			{
				Buy_Pistols_Control(param1, 0);
			}
			else if(param2 == 1)
			{
				Buy_Guns_Control(param1, 0);
			}
			else if(param2 == 2)
			{
				Buy_Equipment_Control(param1, 0);
			}
			else if(param2 == 3)
			{
				Buy_PriAmmo(param1);
			}
			else if(param2 == 4)
			{
				Buy_SecAmmo(param1);
			}
			else if(param2 == 5)
			{
				BuyHealthMenu_control(param1, 0);
			}
			else if(param2 == 6)
			{
				if(buymenudisplay[param1] == false)
				{
					buymenudisplay[param1] = true;
					BuyMenu_control(param1, 0);
				}
				else
				{
					buymenudisplay[param1] = false;
					PrintToChat(param1, "[SM] %t",  "buymenu_chat");
				}
			}
			else if(param2 == 7)
			{
				RebuyPrimary(param1, LastPrimaryWeapon[param1]);
				RebuySecondary(param1, LastSecondaryWeapon[param1]);
				RebuyEquip(param1);
			}
			else if(param2 == 8)
			{
				LastPrimaryWeapon[param1] = -1;
				LastSecondaryWeapon[param1]= -1;
				for(new i = 0; i < 7; i++)
				{
					LastEquipmentItem[param1][i] = 0;
				}
			}
			else if(param2 == 9)
			{
				if(buymenucont[param1] == false)
				{
					buymenucont[param1] = true;
					BuyMenu_control(param1, 0);
				}
				else
				buymenucont[param1] = false;
			}
		}
		else
		{
			if(param2 == 0)
			{
				Buy_Pistols_Control(param1, 0);
			}
			else if(param2 == 1)
			{
				Buy_PriAmmo(param1);
			}
			else if(param2 == 2)
			{
				Buy_SecAmmo(param1);
			}
			else if(param2 == 3)
			{
				BuyHealthMenu_control(param1, 0);
			}
			else if(param2 == 4)
			{
				RebuyPrimary(param1, LastPrimaryWeapon[param1]);
				RebuySecondary(param1, LastSecondaryWeapon[param1]);
				RebuyEquip(param1);
				
				
			}
			else if(param2 == 5)
			{
				if(buymenucont[param1] == false)
				{
					buymenucont[param1] = true;
					BuyMenu_control(param1, 0);
				}
				else
				buymenucont[param1] = false;
			}
			else if(param2 == 6)
			{
				if(buymenudisplay[param1] == false)
				{
					buymenudisplay[param1] = true;
					BuyMenu_control(param1, 0);
				}
				else
				{
					buymenudisplay[param1] = false;
					PrintToChat(param1, "[SM] %t",  "buymenu_chat");
				}
			}
			else if(param2 == 7)
			{
				LastPrimaryWeapon[param1] = -1;
				LastSecondaryWeapon[param1]= -1;
				for(new i = 0; i < 7; i++)
				{
					LastEquipmentItem[param1][i] = 0;
				}
			}
		}
	}
	if(action == MenuAction_Cancel)
	{
		if(param2 == MenuCancel_Exit || param2 == MenuCancel_Timeout || MenuCancel_Interrupted)
		{
			PrintToChat(param1, "[SM] %t",  "buymenu_chat");
		}
	}
	if(action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}



public Action:BuyMenu_control(client, args)
{
	new Handle:menu = CreateMenu(Buy_Menu);
	new String:buffer[32], String:buffer2[32], String:buffer3[32], String:buffer4[32], String:buffer5[32];
	new String:buffer6[32], String:buffer7[32], String:buffer8[32], String:buffer9[32], String:buffer10[32];
	new String: buffer11[32];
	
	Format(buffer, sizeof(buffer), "%T", "buy_menu", LANG_SERVER);
	if(buymenucont[client] == false)
	{
		Format(buffer2, sizeof(buffer2), "%T", "buy_primary", LANG_SERVER);
		Format(buffer3, sizeof(buffer3), "%T", "buy_secondary", LANG_SERVER);
		Format(buffer4, sizeof(buffer4), "%T", "buy_equipment", LANG_SERVER);
	}
	else
	Format(buffer2, sizeof(buffer2), "%T", "buy_weapons", LANG_SERVER);
	
	if(buymenucont[client])
		Format(buffer5, sizeof(buffer5), "%T", "automenu_off", LANG_SERVER);
	else
	Format(buffer5, sizeof(buffer5), "%T", "automenu_on", LANG_SERVER);
	Format(buffer6, sizeof(buffer6), "%T", "buy_healthkits", LANG_SERVER);
	if(buymenudisplay[client])
		Format(buffer7, sizeof(buffer7), "%T", "buy_menu_hide", LANG_SERVER);
	else
	Format(buffer7, sizeof(buffer7), "%T", "buy_menu_show", LANG_SERVER);
	Format(buffer8, sizeof(buffer8), "%T", "buy_priammo", LANG_SERVER);
	Format(buffer9, sizeof(buffer9), "%T", "buy_secammo", LANG_SERVER);
	Format(buffer10, sizeof(buffer10), "%T", "rebuy_weapons", LANG_SERVER);
	Format(buffer11, sizeof(buffer11), "%T", "reset_rebuy", LANG_SERVER);
	
	SetMenuTitle(menu, buffer);
	if(buymenucont[client] == false)
	{
		AddMenuItem(menu, buffer3, buffer3); // buy secondary weapon
		AddMenuItem(menu, buffer2, buffer2); // buy primary weapon
		AddMenuItem(menu, buffer4, buffer4); // buy equipment
		AddMenuItem(menu, buffer8, buffer8); // buy primary ammo
		AddMenuItem(menu, buffer9, buffer9); // buy secondary ammo
		AddMenuItem(menu, buffer6, buffer6); // buy healthkits
		AddMenuItem(menu, buffer7, buffer7); // hide buy menu on spawn
		AddMenuItem(menu, buffer10, buffer10); // rebuy weapons & equipment
		AddMenuItem(menu, buffer11, buffer11); // reset rebuy queue
		AddMenuItem(menu, buffer5, buffer5); // turn automenu on
	}
	else
	{
		AddMenuItem(menu, buffer2, buffer2); // buy weapons
		AddMenuItem(menu, buffer8, buffer8); // buy primary ammo
		AddMenuItem(menu, buffer9, buffer9); // buy secondary ammo
		AddMenuItem(menu, buffer6, buffer6); // buy healthkits
		AddMenuItem(menu, buffer10, buffer10); // rebuy weapons & equipment
		AddMenuItem(menu, buffer5, buffer5); // turn automenu on
		AddMenuItem(menu, buffer7, buffer7); // hide buy menu on spawn
		AddMenuItem(menu, buffer11, buffer11); // reset rebuy queue
	}
	
	
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 15);
}



public SetClientMoney(client, amount)
{
	if (g_Account != -1)
		SetEntData(client, g_Account, amount);
}

public GetClientMoney(client)
{
	if (g_Account != -1)
		return GetEntData(client, g_Account);
	
	return 0;
}



public SetClientHealth(client, amount)
{
	new HealthOffs = FindDataMapOffs(client, "m_iHealth");
	SetEntData(client, HealthOffs, amount, true);
}


public FloatToInt(Float: num)
{
	new String:temp[32];
	FloatToString(num, temp, sizeof(temp));
	return StringToInt(temp);
}


SendDialogToOne(client, color[3], String:text[], any:...)
{
	new String:message[100];
	VFormat(message, sizeof(message), text, 4);	
	
	new Handle:kv = CreateKeyValues("Stuff", "title", message);
	KvSetColor(kv, "color", color[0], color[1], color[2], 255);
	KvSetNum(kv, "level", 2);
	KvSetNum(kv, "time", 2);
	
	CreateDialog(client, kv, DialogType_Msg);
	
	CloseHandle(kv);	
}

stock GetWeaponAmmo(client, slot)
{
	new ammoOffset = FindSendPropInfo("CCSPlayer", "m_iAmmo");
	return GetEntData(client, ammoOffset+(slot*4));
}

stock SetWeaponAmmo(client, slot, ammo)
{
	new ammoOffset = FindSendPropInfo("CCSPlayer", "m_iAmmo");
	return SetEntData(client, ammoOffset+(slot*4), ammo);
}

stock GetPrimaryAmmo(client, weap) 
{   
	//new myweapons = FindSendPropInfo("CCSPlayer", "m_hMyWeapons");  
	//new weap = GetEntDataEnt2(client, myweapons+ (slot*4));
	if(IsValidEntity(weap))
		return GetEntData(weap, FindSendPropInfo("CBaseCombatWeapon", "m_iClip1")); 
	return 0;
}

stock SetPrimaryAmmo(client, weap, ammo) 
{     
	//new myweapons = FindSendPropInfo("CCSPlayer", "m_hMyWeapons");  
	//new weap = GetEntDataEnt2(client, myweapons+ (slot*4)); 
	if(IsValidEntity(weap))
		return SetEntData(weap, FindSendPropInfo("CBaseCombatWeapon", "m_iClip1"), ammo);
	return 0;
}
/*
public GetSecAmmo(client, entity)
{
decl i;
new offset;
new myweapons = FindSendPropInfo("CBaseCombatCharacter", "m_hMyWeapons");
new ammo = 0;

PrintToConsole(client, "[SM] Find weapon index: %d", entity);
for(i=0; i<188; i+=4) // See http://bailopan.net/table_dump.txt
{
new weap = GetEntDataEnt2(client, myweapons+ i);
if (!IsValidEntity(weap))
	continue;

PrintToConsole(client, "[SM] current weapon index: %d", weap);

offset = FindSendPropOffs("CCSPlayer", "m_iAmmo")+i;
ammo = GetEntData(client, offset);

if(ammo != 0)
{
PrintToConsole(client, "[SM] weapon offset: %d", i);
PrintToConsole(client, "[SM] weapon ammo: %d", ammo);
break;
}
}

if(ammo > 0)
	return ammo;
PrintToConsole(client, "[SM] Failed to find offset");
return 0;
}

public SetSecAmmo(client, entity, ammo)
{
decl i;
new offset;
new myweapons = FindSendPropInfo("CBaseCombatCharacter", "m_hMyWeapons");
new a = 0;

PrintToConsole(client, "[SM] Find weapon index: %d", entity);
for(i=0; i<188; i+=4) // See http://bailopan.net/table_dump.txt
{
new weap = GetEntDataEnt2(client, myweapons+ i);
if (!IsValidEntity(weap))
	continue;

PrintToConsole(client, "[SM] current weapon index: %d", weap);

offset = FindSendPropOffs("CCSPlayer", "m_iAmmo")+i;
a = GetEntData(client, offset);

if(a != 0)
{
PrintToConsole(client, "[SM] weapon offset: %d", i);
PrintToConsole(client, "[SM] weapon ammo: %d", a);
break;
}
}

SetEntData(entity, offset, ammo);
}
*/
