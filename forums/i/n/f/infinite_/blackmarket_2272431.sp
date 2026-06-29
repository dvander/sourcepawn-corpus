/*
* BlackMarket by Infinite
* License: GNU General Public License version 3
* */

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <morecolors>

#define VERSION "1.1"

/* Client Data */
new g_playerCash[65];
new g_playerSpendable[65];
new g_playerCanBuy[65]; // 0 = no 1 = yes

/* Handles */
new Handle:MoneyDispTimers[65] = {INVALID_HANDLE, ...};
new Handle:g_hTimedBuyExpire[65] = {INVALID_HANDLE, ...};
new Handle:g_hHudSync[65] = {INVALID_HANDLE, ...};
new Handle:g_hBuyMenu[65] = {INVALID_HANDLE, ...};

/* ConVar Handles */
new Handle:g_cvarVersion;

new Handle:g_cvarEnabled;
new Handle:g_cvarBuyTime;

new Handle:g_cvarRewardAR2;
new Handle:g_cvarReward357;
new Handle:g_cvarRewardShotgun;
new Handle:g_cvarRewardCrowbar;
new Handle:g_cvarRewardCrossbow;
new Handle:g_cvarRewardGrenade;
new Handle:g_cvarRewardRPG;
new Handle:g_cvarRewardSMG;
new Handle:g_cvarRewardStunstick;
new Handle:g_cvarRewardSLAM;
new Handle:g_cvarRewardPistol;
new Handle:g_cvarRewardPhysics;
new Handle:g_cvarRewardSMGNade;
new Handle:g_cvarRewardCball;

new Handle:g_cvarCostAR2;
new Handle:g_cvarCostAR2Ammo;
new Handle:g_cvarCostShotgun;
new Handle:g_cvarCostShotgunAmmo;
new Handle:g_cvarCost357;
new Handle:g_cvarCost357Ammo;
new Handle:g_cvarCostRPG;
new Handle:g_cvarCostSLAM;
new Handle:g_cvarCostSMGNade;
new Handle:g_cvarCostAR2Ball;
new Handle:g_cvarCostBattery;

public Plugin:myinfo =
{
	name = "Black Market",
	author = "Infinite/Pand3mic",
	description = "Black Market: Store for HL2:DM",
	version = VERSION,
	url = "www.sourcemod.net"
};

/* Forwards -----------------------------------------------------------------*/

public OnPluginStart()
{
	// Commands
	RegConsoleCmd("sm_bm", cmd_bm, "Opens the Black Market buy menu.");
	
	// Version ConVar
	g_cvarVersion = CreateConVar("bm_blackmarket_version", VERSION, "Public BlackMarket version ConVar", FCVAR_NOTIFY);
	new Float:versionConVar = GetConVarFloat(g_cvarVersion);
	
	// ConVars
	g_cvarEnabled = CreateConVar("bm_enable", "1", "Sets whether BlackMarket is enabled");
	g_cvarBuyTime = CreateConVar("bm_buytime", "20.0", "Amount of time after a player spawns to allow purchases.");
	
	g_cvarRewardAR2 = CreateConVar("bm_reward_ar2", "150", "Reward from a kill using the AR2.");
	g_cvarReward357 = CreateConVar("bm_reward_357", "100", "Reward from a kill using the 357.");
	g_cvarRewardShotgun = CreateConVar("bm_reward_shotgun", "150", "Reward from a kill using the shotgun.");
	g_cvarRewardCrowbar = CreateConVar("bm_reward_crowbar", "300", "Reward from a kill using the crowbar.");
	g_cvarRewardCrossbow = CreateConVar("bm_reward_crossbow", "100", "Reward from a kill using the crossbow.");
	g_cvarRewardGrenade = CreateConVar("bm_reward_grenade", "150", "Reward from a kill using a grenade.");
	g_cvarRewardRPG = CreateConVar("bm_reward_rpg", "100", "Reward from a kill using the RPG.");
	g_cvarRewardSMG = CreateConVar("bm_reward_smg", "200", "Reward from a kill using the SMG.");
	g_cvarRewardStunstick = CreateConVar("bm_reward_stunstick", "300", "Reward from a kill using the stunstick.");
	g_cvarRewardSLAM = CreateConVar("bm_reward_slam", "150", "Reward from a kill using the S.L.A.M.");
	g_cvarRewardPistol = CreateConVar("bm_reward_pistol", "250", "Reward from a kill using the pistol.");
	g_cvarRewardPhysics = CreateConVar("bm_reward_physics", "150", "Reward from a kill using a physics prop.");
	g_cvarRewardSMGNade = CreateConVar("bm_reward_smgnade", "100", "Reward from a kill using a SMG grenade.");
	g_cvarRewardCball = CreateConVar("bm_reward_comball", "150", "Reward from a kill using a combine ball.");
	
	g_cvarCostAR2 = CreateConVar("bm_cost_ar2", "300", "Cost to buy an AR2.");
	g_cvarCostAR2Ammo = CreateConVar("bm_cost_ammo_ar2", "50", "Cost to buy AR2 ammo.");
	g_cvarCostShotgun = CreateConVar("bm_cost_shotgun", "400", "Cost to buy a shotgun.");
	g_cvarCostShotgunAmmo = CreateConVar("bm_cost_ammo_shotgun", "50", "Cost to buy shotgun ammo.");
	g_cvarCost357 = CreateConVar("bm_cost_357", "750", "Cost to buy a 357.");
	g_cvarCost357Ammo = CreateConVar("bm_cost_ammo_357", "50", "Cost to buy 357 ammo.");
	g_cvarCostRPG = CreateConVar("bm_cost_rpg", "1500", "Cost to buy an RPG.");
	g_cvarCostSLAM = CreateConVar("bm_cost_slam", "200", "Cost to buy a S.L.A.M.");
	g_cvarCostSMGNade = CreateConVar("bm_cost_smgnade", "200", "Cost to buy a SMG nade.");
	g_cvarCostAR2Ball = CreateConVar("bm_cost_ar2ball", "200", "Cost to buy an AR2 ball.");
	g_cvarCostBattery = CreateConVar("bm_cost_battery", "100", "Cost to buy a battery.");

	// Event Hooks
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Post);
	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
	
	// Exec config
	AutoExecConfig(true, "blackmarket");
	
	PrintToServer("BlackMarket Version %f has been loaded.", versionConVar);
}

public OnMapEnd()
{
	for (new i = 1; i <= MaxClients; i++)
	{
		// Reset Player Data
		g_hHudSync[i] = INVALID_HANDLE;
		g_playerCash[i] = 0;
		g_playerSpendable[i] = 0;
		g_playerCanBuy[i] = 0;
	}
}

public OnClientPutInServer(client)
{
	g_playerCash[client] = 0;
	g_playerSpendable[client] = 0;
	g_playerCanBuy[client] = 0;
	MoneyDispTimers[client] = CreateTimer(0.4, Loop_MoneyDisp, client, TIMER_REPEAT);
}

public OnClientDisconnect(client)
{
	g_playerCash[client] = 0;
	g_playerSpendable[client] = 0;
	g_playerCanBuy[client] = 0;
}

/* Event Hooks --------------------------------------------------------------*/

public Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarInt(g_cvarEnabled) == 0)
		return;
	
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));

	decl String:victimName[32];
	GetClientName(victim, victimName, sizeof(victimName));

	decl String:weapon[32];
	GetEventString(event, "weapon", weapon, sizeof(weapon));

	// Make cash from victim's past life spendable.
	g_playerSpendable[victim] = g_playerCash[victim];

	// Reset victim's alive money
	g_playerCash[victim] = 0;
	
	// If the victim died before buytime expired, cancel their timer.
	if (g_playerCanBuy[victim] == 1)
		KillTimer(g_hTimedBuyExpire[victim]);

	// Ignore Suicides
	if (attacker == victim)
		return;

	// Reward the kill
	if (StrEqual(weapon, "ar2"))
	{
		new ar2reward = GetConVarInt(g_cvarRewardAR2);
		g_playerCash[attacker] += ar2reward;
	}
	else if (StrEqual(weapon, "357"))
	{
		new magnumreward = GetConVarInt(g_cvarReward357);
		g_playerCash[attacker] += magnumreward;
	}
	else if (StrEqual(weapon, "shotgun"))
	{
		new shotgunreward = GetConVarInt(g_cvarRewardShotgun);
		g_playerCash[attacker] += shotgunreward;
	}
	else if (StrEqual(weapon, "crowbar"))
	{
		new crowbarreward = GetConVarInt(g_cvarRewardCrowbar);
		g_playerCash[attacker] += crowbarreward;
	}
	else if (StrEqual(weapon, "crossbow_bolt"))
	{
		new crossbowreward = GetConVarInt(g_cvarRewardCrossbow);
		g_playerCash[attacker] += crossbowreward;
	}
	else if (StrEqual(weapon, "grenade_frag"))
	{
		new nadereward = GetConVarInt(g_cvarRewardGrenade);
		g_playerCash[attacker] += nadereward;
	}
	else if (StrEqual(weapon, "rpg_missile"))
	{
		new rpgreward = GetConVarInt(g_cvarRewardRPG);
		g_playerCash[attacker] += rpgreward;
	}
	else if (StrEqual(weapon, "smg1"))
	{
		new smgreward = GetConVarInt(g_cvarRewardSMG);
		g_playerCash[attacker] += smgreward;
	}
	else if (StrEqual(weapon, "stunstick"))
	{
		new stunreward = GetConVarInt(g_cvarRewardStunstick);
		g_playerCash[attacker] += stunreward;
	}
	else if (StrEqual(weapon, "slam"))
	{
		new slamreward = GetConVarInt(g_cvarRewardSLAM);
		g_playerCash[attacker] += slamreward;
	}
	else if (StrEqual(weapon, "pistol"))
	{
		new pistolreward = GetConVarInt(g_cvarRewardPistol);
		g_playerCash[attacker] += pistolreward;
	}
	else if (StrEqual(weapon, "physics"))
	{
		new physicsreward = GetConVarInt(g_cvarRewardPhysics);
		g_playerCash[attacker] += physicsreward;
	}
	else if (StrEqual(weapon, "smg1_grenade"))
	{
		new smgnadereward = GetConVarInt(g_cvarRewardSMGNade);
		g_playerCash[attacker] += smgnadereward;
	}
	else if (StrEqual(weapon, "combine_ball"))
	{
		new combineballreward = GetConVarInt(g_cvarRewardCball);
		g_playerCash[attacker] += combineballreward;
	}
	else
	{
		PrintToServer("[Black Market] ERROR: Unknown weapon key: %s", weapon);
	}
	return;

}

public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	// Client can buy for x seconds.
	g_playerCanBuy[client] = 1;
	new Float:buyTime = GetConVarFloat(g_cvarBuyTime);
	g_hTimedBuyExpire[client] = CreateTimer(buyTime, Timed_PlayerBuyExpire, client);
	
	if (GetConVarInt(g_cvarEnabled) == 0)
		return;
	
	CPrintToChat(client, "{darkorange}[Black Market] {white}You have {dodgerblue}$%d {white}available, say !bm to spend it!", g_playerSpendable[client]);
}

/* Commands -----------------------------------------------------------------*/

public Action:cmd_bm(client, args)
{
	if (GetConVarInt(g_cvarEnabled) == 0)
		return Plugin_Handled;
	
	BuildBuyMenu(client); // Will check if player can buy before displaying menu
	new Float:buyTime = GetConVarFloat(g_cvarBuyTime);

	if (g_playerCanBuy[client] == 1)
	{
		CPrintToChat(client, "{darkorange}[Black Market] {white}Press ESC to access the buy menu.");		
	}
	else
	{
		CPrintToChat(client, "{darkorange}[Black Market] {white}You can only buy within %d seconds of spawning.", buyTime);
	}

	return Plugin_Handled;
}

BuildBuyMenu(client)
{
	g_hBuyMenu[client] = CreateMenu(BuyMenuHandler);
	SetMenuTitle(g_hBuyMenu[client], "Balance: $%d", g_playerSpendable[client]);

	decl String:ar2[64];
	new ar2Cost = GetConVarInt(g_cvarCostAR2);
	Format(ar2, sizeof(ar2), "AR2 ($%d)", ar2Cost);
	AddMenuItem(g_hBuyMenu[client], "weapon_ar2", ar2);
	
	decl String:ar2ammo[64];
	new ar2ammoCost = GetConVarInt(g_cvarCostAR2Ammo);
	Format(ar2ammo, sizeof(ar2ammo), "AR2 Ammo ($%d)", ar2ammoCost);
	AddMenuItem(g_hBuyMenu[client], "item_ammo_ar2_large", ar2ammo);
	
	decl String:shotgun[64];
	new shotgunCost = GetConVarInt(g_cvarCostShotgun);
	Format(shotgun, sizeof(shotgun), "Shotgun ($%d)", shotgunCost);
	AddMenuItem(g_hBuyMenu[client], "weapon_shotgun", shotgun);
	
	decl String:shotgunammo[64];
	new shotgunammoCost = GetConVarInt(g_cvarCostShotgunAmmo);
	Format(shotgunammo, sizeof(shotgunammo), "Shotgun Ammo ($%d)", shotgunammoCost);
	AddMenuItem(g_hBuyMenu[client], "item_box_buckshot", shotgunammo);
	
	decl String:magnum[64];
	new magnumCost = GetConVarInt(g_cvarCost357);
	Format(magnum, sizeof(magnum), ".357 Magnum ($%d)", magnumCost);
	AddMenuItem(g_hBuyMenu[client], "weapon_357", magnum);
	
	decl String:magnumammo[64];
	new magnumammoCost = GetConVarInt(g_cvarCost357Ammo);
	Format(magnumammo, sizeof(magnumammo), ".357 Ammo ($%d)", magnumammoCost);
	AddMenuItem(g_hBuyMenu[client], "item_ammo_357", magnumammo);
	
	decl String:rpg[64];
	new rpgCost = GetConVarInt(g_cvarCostRPG);
	Format(rpg, sizeof(rpg), "RPG ($%d)", rpgCost);
	AddMenuItem(g_hBuyMenu[client], "weapon_rpg", rpg);
	
	decl String:slam[64];
	new slamCost = GetConVarInt(g_cvarCostSLAM);
	Format(slam, sizeof(slam), "S.L.A.M ($%d)", slamCost);
	AddMenuItem(g_hBuyMenu[client], "weapon_slam", slam);
	
	decl String:smgnade[64];
	new smgnadeCost = GetConVarInt(g_cvarCostSMGNade);
	Format(smgnade, sizeof(smgnade), "SMG Grenade ($%d)", smgnadeCost);
	AddMenuItem(g_hBuyMenu[client], "item_ammo_smg1_grenade", smgnade);
	
	decl String:ar2ball[64];
	new ar2ballCost = GetConVarInt(g_cvarCostAR2Ball);
	Format(ar2ball, sizeof(ar2ball), "AR2 Energy Ball ($%d)", ar2ballCost);
	AddMenuItem(g_hBuyMenu[client], "item_ammo_ar2_altfire", ar2ball);
	
	decl String:battery[64];
	new batteryCost = GetConVarInt(g_cvarCostBattery);
	Format(battery, sizeof(battery), "Battery ($%d)", batteryCost);
	AddMenuItem(g_hBuyMenu[client], "item_battery", battery);
	

	SetMenuPagination(g_hBuyMenu[client], 7);
	SetMenuExitButton(g_hBuyMenu[client], false);

	if (g_playerCanBuy[client] == 1)
	{		
		DisplayMenu(g_hBuyMenu[client], client, MENU_TIME_FOREVER);
	}
}

/* Menu Handlers ------------------------------------------------------------*/

public BuyMenuHandler(Handle:menu, MenuAction:action, p1, p2)
{
	if (action == MenuAction_Select)
	{
		decl String:item[64];
		switch (p2)
		{
			case 0: // AR2
			{
				GetMenuItem(g_hBuyMenu[p1], 0, item, sizeof(item));
				new ar2cost = GetConVarInt(g_cvarCostAR2);
				if (g_playerSpendable[p1] >= ar2cost)
				{
					GivePlayerItem(p1, item);
					CPrintToChat(p1, "{darkorange}[Black Market] {white}You have purchased an {dodgerblue}AR2.");
					g_playerSpendable[p1] -= ar2cost;
				}
				else
				{
					CPrintToChat(p1, "{darkorange}[Black Market] {white}You cannot afford that item.");
				}
				
				if (g_playerCanBuy[p1] == 1)
					BuildBuyMenu(p1);
					
			}
			case 1:
			{
				GetMenuItem(g_hBuyMenu[p1], 1, item, sizeof(item));
				new ar2ammocost = GetConVarInt(g_cvarCostAR2Ammo);
				if (g_playerSpendable[p1] >= ar2ammocost)
				{
					GivePlayerItem(p1, item);
					CPrintToChat(p1, "{darkorange}[Black Market] {white}You have purchased some {dodgerblue}AR2 ammo.");
					g_playerSpendable[p1] -= ar2ammocost;
				}
				else
				{
					CPrintToChat(p1, "{darkorange}[Black Market] {white}You cannot afford that item.");
				}
				
				if (g_playerCanBuy[p1] == 1)
					BuildBuyMenu(p1);
			}
			case 2:
			{
				GetMenuItem(g_hBuyMenu[p1], 2, item, sizeof(item));
				new shotguncost = GetConVarInt(g_cvarCostShotgun);
				if (g_playerSpendable[p1] >= shotguncost)
				{
					GivePlayerItem(p1, item);
					CPrintToChat(p1, "{darkorange}[Black Market] {white}You have purchased a {dodgerblue}shotgun.");
					g_playerSpendable[p1] -= shotguncost;
				}
				else
				{
					CPrintToChat(p1, "{darkorange}[Black Market] {white}You cannot afford that item.");
				}
				
				if (g_playerCanBuy[p1] == 1)
					BuildBuyMenu(p1);
			}
			case 3:
			{
				GetMenuItem(g_hBuyMenu[p1], 3, item, sizeof(item));
				new shotgunammocost = GetConVarInt(g_cvarCostShotgunAmmo);
				if (g_playerSpendable[p1] >= shotgunammocost)
				{
					GivePlayerItem(p1, item);
					CPrintToChat(p1, "{darkorange}[Black Market] {white}You have purchased some {dodgerblue}shotgun ammo.");
					g_playerSpendable[p1] -= shotgunammocost;
				}
				else
				{
					CPrintToChat(p1, "{darkorange}[Black Market] {white}You cannot afford that item.");
				}
				
				if (g_playerCanBuy[p1] == 1)
					BuildBuyMenu(p1);
			}
			case 4:
			{
				GetMenuItem(g_hBuyMenu[p1], 4, item, sizeof(item));
				new magnumcost = GetConVarInt(g_cvarCost357);
				if (g_playerSpendable[p1] >= magnumcost)
				{
					GivePlayerItem(p1, item);
					CPrintToChat(p1, "{darkorange}[Black Market] {white}You have purchased a {dodgerblue}.357 magnum.");
					g_playerSpendable[p1] -= magnumcost;
				}
				else
				{
					CPrintToChat(p1, "{darkorange}[Black Market] {white}You cannot afford that item.");
				}
				
				if (g_playerCanBuy[p1] == 1)
					BuildBuyMenu(p1);
			}
			case 5:
			{
				GetMenuItem(g_hBuyMenu[p1], 5, item, sizeof(item));
				new magnumammocost = GetConVarInt(g_cvarCost357Ammo);
				if (g_playerSpendable[p1] >= magnumammocost)
				{
					GivePlayerItem(p1, item);
					CPrintToChat(p1, "{darkorange}[Black Market] {white}You have purchased some {dodgerblue}.357 ammo.");
					g_playerSpendable[p1] -= magnumammocost;
				}
				else
				{
					CPrintToChat(p1, "{darkorange}[Black Market] {white}You cannot afford that item.");
				}
				
				if (g_playerCanBuy[p1] == 1)
					BuildBuyMenu(p1);
			}
			case 6:
			{
				GetMenuItem(g_hBuyMenu[p1], 6, item, sizeof(item));
				new rpgcost = GetConVarInt(g_cvarCostRPG);
				if (g_playerSpendable[p1] >= rpgcost)
				{
					GivePlayerItem(p1, item);
					CPrintToChat(p1, "{darkorange}[Black Market] {white}You have purchased an {dodgerblue}RPG.");
					g_playerSpendable[p1] -= rpgcost;
				}
				else
				{
					CPrintToChat(p1, "{darkorange}[Black Market] {white}You cannot afford that item.");
				}
				
				if (g_playerCanBuy[p1] == 1)
					BuildBuyMenu(p1);
			}
			case 7:
			{
				GetMenuItem(g_hBuyMenu[p1], 7, item, sizeof(item));
				new slamcost = GetConVarInt(g_cvarCostSLAM);
				if (g_playerSpendable[p1] >= slamcost)
				{
					GivePlayerItem(p1, item);
					CPrintToChat(p1, "{darkorange}[Black Market] {white}You have purchased a {dodgerblue}S.L.A.M");
					g_playerSpendable[p1] -= slamcost;
				}
				else
				{
					CPrintToChat(p1, "{darkorange}[Black Market] {white}You cannot afford that item.");
				}
				
				if (g_playerCanBuy[p1] == 1)
					BuildBuyMenu(p1);
			}
			case 8:
			{
				GetMenuItem(g_hBuyMenu[p1], 8, item, sizeof(item));
				new smgnadecost = GetConVarInt(g_cvarCostSMGNade);
				if (g_playerSpendable[p1] >= smgnadecost)
				{
					GivePlayerItem(p1, item);
					CPrintToChat(p1, "{darkorange}[Black Market] {white}You have purchased an {dodgerblue}SMG grenade.");
					g_playerSpendable[p1] -= smgnadecost;
				}
				else
				{
					CPrintToChat(p1, "{darkorange}[Black Market] {white}You cannot afford that item.");
				}
				
				if (g_playerCanBuy[p1] == 1)
					BuildBuyMenu(p1);
			}
			case 9:
			{
				GetMenuItem(g_hBuyMenu[p1], 9, item, sizeof(item));
				new ar2ballcost = GetConVarInt(g_cvarCostAR2Ball);
				if (g_playerSpendable[p1] >= ar2ballcost)
				{
					GivePlayerItem(p1, item);
					CPrintToChat(p1, "{darkorange}[Black Market] {white}You have purchased an {dodgerblue}AR2 energy ball.");
					g_playerSpendable[p1] -= ar2ballcost;
				}
				else
				{
					CPrintToChat(p1, "{darkorange}[Black Market] {white}You cannot afford that item.");
				}
				
				if (g_playerCanBuy[p1] == 1)
					BuildBuyMenu(p1);
			}
			case 10:
			{
				GetMenuItem(g_hBuyMenu[p1], 10, item, sizeof(item));
				new batterycost = GetConVarInt(g_cvarCostBattery);
				if (g_playerSpendable[p1] >= batterycost)
				{
					GivePlayerItem(p1, item);
					CPrintToChat(p1, "{darkorange}[Black Market] {white}You have purchased a {dodgerblue}battery.");
					g_playerSpendable[p1] -= batterycost;
				}
				else
				{
					CPrintToChat(p1, "{darkorange}[Black Market] {white}You cannot afford that item.");
				}
				
				if (g_playerCanBuy[p1] == 1)
					BuildBuyMenu(p1);
			}
		}
	}		
}

/* Loops --------------------------------------------------------------------*/

public Action:Loop_MoneyDisp(Handle:timer, any:client)
{
	if (!IsClientInGame(client))
		return Plugin_Stop;
	
	
	if (g_hHudSync[client] == INVALID_HANDLE)
	{
		g_hHudSync[client] = CreateHudSynchronizer();
	}

	SetHudTextParams(0.9, 0.7, 0.45, 255, 135, 0, 255, 0, 0.01, 0.01, 0.01);
	
	if (GetConVarInt(g_cvarEnabled) == 0)
		return Plugin_Continue;
	
	ShowSyncHudText(client, g_hHudSync[client], "BM: $%d ($%d)", g_playerSpendable[client], g_playerCash[client]);
	
	return Plugin_Continue;
}

/* Timed Callbacks ----------------------------------------------------------*/

public Action:Timed_PlayerBuyExpire(Handle:timer, any:client)
{
	g_playerCanBuy[client] = 0;

	if (g_hBuyMenu[client] != INVALID_HANDLE)
		CancelMenu(g_hBuyMenu[client]);
		
	if (GetConVarInt(g_cvarEnabled) == 0)
		return;
	
	if (IsClientInGame(client))
		CPrintToChat(client, "{darkorange}[Black Market] {white}Your buy period has expired.");
}
