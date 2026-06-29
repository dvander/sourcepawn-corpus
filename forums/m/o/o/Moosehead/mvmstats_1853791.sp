/**
* TF2 MvM Stats Plugins v1.1 (12/16/2012)
* 
* Change Log:
*  1.1 - 12/16/2012 
*   Better scoring calculation
*   Reduced tank MVP display to 5 seconds
*   Better message positioning
*  1.0 - 12/14/2012 
*   Initial Release
*
* Author:
*  Moosehead (Monospace Software LLC)
* 
* Credit To:
*  HLstatsX/SuperLogs: TF2
*  win-panel by Reflex
* 
* Description:
*  Makes TF2 MvM mode a little more competitive by tracking and reporting 
*  statistics for each MvM wave.  Displays MVP for each tank and at the end 
*  of each wave.  A menu allows players to browse statistics ordered by 
*  rank for each round.  The Wave MVP is calculated from a formula using the 
*  ranks and a weight for each stat category.  The Tank MVP is simply based 
*  on the player that does the most damage to the tank.
*
* Screen Shots:
*  http://imgur.com/a/RAkSP/embed#0
* 
* Commands:
*  mvmstats - pops up MvM Stats menu
* 
* CVARs:
*  mvmstats_report_tank_health - Report tank health upon spawning
*  mvmstats_version - MvM Stats Version
* 
* Dependencies:
*  SDK Hooks - http://forums.alliedmods.net/showthread.php?t=106748
*
* Install:
*  Install SDK Hooks
*  Place mvmstats.smx in tf\addons\sourcemod\plugins
*
* Compiling:
*  Install SDK Hooks
*  Place mvmstats.sp in tf\addons\sourcemod\scripting
*  spcomp mvmstats.sp -o..\plugins\mvmstats
*/

#include <sourcemod>
#include <tf2_stocks>
#include <sdkhooks>

#pragma semicolon 1

#define PLUGIN_VERSION "1.1"

#define MAXWAVES 11
#define MAXSTATS 12
#define MAXTANKS 8
#define MAXPANELS 9

#define BOT_DAMAGE 0
#define GIANT_DAMAGE 1
#define TANK_DAMAGE 2
#define BOT_KILL 3
#define GIANT_KILL 4
#define TANK_KILL 5
#define CASH_PICKUP 6
#define CANTEEN_USED 7
#define BOMB_DEFENDED 8
#define BOMB_RESET 9
#define BOMB_DEPLOY_RESET 10
#define ASSIST 11
#define SCORE 12

new g_stats[MAXPLAYERS+1][MAXWAVES+1][MAXSTATS+1];
new g_currentWave = 0;

new g_tanks[MAXTANKS+1][MAXPLAYERS+1];

new Float:g_scoreWeights[MAXSTATS+1];

new String:g_panelTitles[MAXPANELS][32];
new g_panelOrder[MAXPANELS];
new g_lastPanel[MAXPLAYERS+1];

new String:g_panelButton[] = "buttons/button14.wav";
new String:g_panelExit[] = "buttons/combine_button7.wav";

new Handle:g_reportTankHandle = INVALID_HANDLE;
new bool:g_reportTank;

public Plugin:myinfo =
{
	name = "TF2 MvM Stats",
	author = "Monospace Software LLC",
	description = "Track and report wave statistics in TF2 MvM mode",
	version = PLUGIN_VERSION,
	url = "http://www.monospacesoftware.com"
}

public OnPluginStart()
{
	InitConVars();
	InitPanelNavigation();
	InitScoreWeights();
	InitHooks();
	
	new mvmStatsEntity = FindEntityByClassname(-1, "tf_mann_vs_machine_stats");
	if (IsValidEntity(mvmStatsEntity)) {
		new currentWave = GetEntProp(mvmStatsEntity, Prop_Send, "m_iCurrentWaveIdx");
		g_currentWave = currentWave;
		LogMessage("Plugin loaded at MvM Wave %i", currentWave);
	}
	
	RegConsoleCmd("mvmstats", StatsCommand, "Show MvM Stats");
}

// INITS =====================================================

InitConVars()
{
	new Handle:Version = CreateConVar("mvmstats_version", PLUGIN_VERSION, "TF2 MvM Stats Version", FCVAR_NOTIFY|FCVAR_PLUGIN|FCVAR_DONTRECORD);
	SetConVarString(Version, PLUGIN_VERSION, _, true);

	g_reportTank = true;
	g_reportTankHandle = CreateConVar("mvmstats_report_tank_health", "1", "Report tank health upon spawning?", FCVAR_PLUGIN, true, 0.0, true, 1.0);	
	HookConVarChange(g_reportTankHandle, ConVarChanged);
}

InitPanelNavigation()
{
	// Panel titles and display order
	
	g_panelTitles[0] = "MvM SCORE";
	g_panelTitles[1] = "BOT KILLS";
	g_panelTitles[2] = "BOT DAMAGE";
	g_panelTitles[3] = "GIANT KILLS";
	g_panelTitles[4] = "GIANT DAMAGE";
	g_panelTitles[5] = "TANK DAMAGE";
	g_panelTitles[6] = "ASSISTS";
	g_panelTitles[7] = "CASH COLLECTED";
	g_panelTitles[8] = "CANTEENS USED";
	
	g_panelOrder[0] = SCORE;
	g_panelOrder[1] = BOT_KILL;
	g_panelOrder[2] = BOT_DAMAGE;
	g_panelOrder[3] = GIANT_KILL;
	g_panelOrder[4] = GIANT_DAMAGE;
	g_panelOrder[5] = TANK_DAMAGE;
	g_panelOrder[6] = ASSIST;
	g_panelOrder[7] = CASH_PICKUP;
	g_panelOrder[8] = CANTEEN_USED;
}

InitScoreWeights()
{
	// Weights for each category used to determine the MvM score/wave winner
	// All together these should average 1.0

	g_scoreWeights[BOT_DAMAGE] = 1.2;
	g_scoreWeights[BOT_KILL] = 0.8;
	g_scoreWeights[ASSIST] = 1.1;
	g_scoreWeights[CASH_PICKUP] = 1.1;
	g_scoreWeights[TANK_DAMAGE] = 1.0;
	g_scoreWeights[GIANT_DAMAGE] = 1.2;
	g_scoreWeights[GIANT_KILL] = 0.6;
}

InitHooks()
{
	HookEvent("player_hurt", PlayerHurt);
	HookEvent("npc_hurt", TankHurt);
	HookEvent("player_death", PlayerDeath);
	HookEvent("mvm_begin_wave", WaveBegin);
	HookEvent("ctf_flag_captured", WaveEnd);
	HookEvent("mvm_wave_complete", WaveComplete);
	HookEvent("mvm_mission_complete", MissionComplete);
	HookEvent("mvm_pickup_currency", CashPickup);
	HookEvent("player_used_powerup_bottle", CanteenUsed);
	
	// these don't seem to fire reliably
	HookEvent("mvm_kill_robot_delivering_bomb", BombDefended);
	HookEvent("mvm_bomb_reset_by_player", BombReset);
	HookEvent("mvm_bomb_deploy_reset_by_player", BombDeployReset);
}

// CONVAR HANDLING =====================================================

public ConVarChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	if(cvar == g_reportTankHandle) {
		g_reportTank = StringToInt(newVal) ? true : false;
	}
}

// LIFECYCLE EVENTS =====================================================

public OnMapStart()
{
	PrecacheSound(g_panelButton);
	PrecacheSound(g_panelExit);

	ResetAllStats();
}

public OnClientPutInServer(client)
{
	if (IsValidClient(client)) {
		ResetClientStats(client);
	}
}

public WaveBegin(Handle:event, const String:name[], bool:dontBroadcast)
{
	new waveIndex = GetEventInt(event, "wave_index");
	g_currentWave = waveIndex;
	
	LogMessage("Wave %i Begin", waveIndex);
	
	if (waveIndex == 0) {
		ResetAllStats();
	} else {
		ResetWaveStats(waveIndex);
	}
}

public WaveEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	new winningTeam = GetEventInt(event, "capping_team");
	if (winningTeam == 3) {
		LogMessage("Wave %i Lost", g_currentWave);
		ResetWaveStats(g_currentWave);
		if (g_currentWave > 0)
			g_currentWave--;
	}
}

public WaveComplete(Handle:event, const String:name[], bool:dontBroadcast)
{
	LogMessage("Wave %i Won", g_currentWave);
	
	UpdateWaveScores(g_currentWave);
	ShowWaveStatsAll(g_currentWave);
	ShowWaveWinner(g_currentWave);
}

public MissionComplete(Handle:event, const String:name[], bool:dontBroadcast)
{
	decl String:mission[128];
	GetEventString(event, "mission", mission, sizeof(mission));
	
	LogMessage("MissionComplete: %s", mission);
}

// STAT EVENTS =====================================================

public PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	new damage = GetEventInt(event, "damageamount");
	
	if (IsValidClient(attacker) && victim != attacker && damage > 0) {
		decl String:botName[32];
		GetClientName(victim, botName, sizeof(botName));
		
		// this adjusts stats for overkill
		new hp = GetEntProp(victim, Prop_Data, "m_iHealth");
		if (hp < 0) {
			damage += hp;
		}

		if (StrContains(botName, "Giant") != -1 || StrContains(botName, "Super") != -1 || StrContains(botName, "Major") != -1) {
			g_stats[attacker][g_currentWave][GIANT_DAMAGE] += damage;
			//LogMessage("Giant Damage! %i to %i %s from %N, total %i", damage, victim, botName, attacker, g_stats[attacker][g_currentWave][GIANT_DAMAGE]);
		} else {
			g_stats[attacker][g_currentWave][BOT_DAMAGE] += damage;
			//LogMessage("Bot Damage! %i to %i %s from %N, total %i", damage, victim, botName, attacker, g_stats[attacker][g_currentWave][BOT_DAMAGE]);
		}
	}
}

public PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new victim   = GetClientOfUserId(GetEventInt(event, "userid"));
//	new custom_kill = GetEventInt(event, "customkill");
//	new death_flags = GetEventInt(event, "death_flags");
	new assister   = GetClientOfUserId(GetEventInt(event, "assister"));
	
	if (IsValidClient(attacker) && victim != attacker) {
		decl String:botName[32];
		GetClientName(victim, botName, sizeof(botName));
		
		if (StrContains(botName, "Giant") != -1 || StrContains(botName, "Super") != -1 || StrContains(botName, "Major") != -1) {
			g_stats[attacker][g_currentWave][GIANT_KILL]++;
			//LogMessage("Giant Kill! %i %s from %N, total %i", victim, botName, attacker, g_stats[attacker][g_currentWave][GIANT_KILL]);
		} else {
			g_stats[attacker][g_currentWave][BOT_KILL]++;
			//LogMessage("Bot Kill! %i %s from %N, total %i", victim, botName, attacker, g_stats[attacker][g_currentWave][BOT_KILL]);
		}
		
		if (IsValidClient(assister)) {
			g_stats[assister][g_currentWave][ASSIST]++;
			//LogMessage("Assist %i %s from %N, total %i", victim, botName, assister, g_stats[assister][g_currentWave][ASSIST]);
		}
	}
}

public CashPickup(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetEventInt(event, "player");
	new amount = GetEventInt(event, "currency");
	
	//LogMessage("CashPickup: %N %i", client, amount);
	
	g_stats[client][g_currentWave][CASH_PICKUP] += amount;
}

public CanteenUsed(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetEventInt(event, "player");
	//new type = GetEventInt(event, "type");
	
	//LogMessage("CanteenUsed: %N", client);
	
	g_stats[client][g_currentWave][CANTEEN_USED]++;
}

public BombDefended(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetEventInt(event, "player");
	//LogMessage("BombDefended: %N", client);
	g_stats[client][g_currentWave][BOMB_DEFENDED]++;
}

public BombReset(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetEventInt(event, "player");
	//LogMessage("BombReset: %N", client);
	g_stats[client][g_currentWave][BOMB_RESET]++;
}

public BombDeployReset(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetEventInt(event, "player");
	//LogMessage("BombDeployReset: %N", client);
	g_stats[client][g_currentWave][BOMB_DEPLOY_RESET]++;
}

// TANKS EVENTS =====================================================

public OnEntityCreated(entity, const String:classname[])
{
	if (StrEqual("tank_boss", classname)) {
		SDKHook(entity, SDKHook_SpawnPost, TankSpawned);
	}
}

public TankSpawned(entity)
{
	RegisterTank(entity);
	new maxHp = GetEntProp(entity, Prop_Data, "m_iMaxHealth");
	
	//LogMessage("TankSpawned: %i with %i", entity, maxHp);
	
	if (g_reportTank) {
		//PrintToChatAll("Tank spawned with %i health!", maxHp);
		
		new Handle:hudHandle = CreateHudSynchronizer();
		SetHudTextParams(0.18, 0.9, 10.0, 255, 0, 0, 255);

		for(new client = 0; client < MaxClients; client++) {
			if (IsValidClient(client)) {
				ShowSyncHudText(client, hudHandle, "Tank spawned with %i health!", maxHp);
			}
		}
		
		CloseHandle(hudHandle);
	}
}

public TankHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim = GetEventInt(event, "entindex");
	
	//decl String:className[16];
	//GetEntityClassname(victim, className, sizeof(className));
	
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker_player"));
	new damage = GetEventInt(event, "damageamount");
	
	if (IsValidClient(attacker) && damage > 0) {
		g_stats[attacker][g_currentWave][TANK_DAMAGE] += damage;
		//LogMessage("Tank Damage! %i to %i %s from %N, total %i", damage, victim, className, attacker, g_stats[attacker][g_currentWave][TANK_DAMAGE]);
		
		new tankIndex = GetTankIndex(victim);
		if (tankIndex >= 0) {
			g_tanks[tankIndex][attacker] += damage;
			//LogMessage("Tank Damage! %i to %i/%i %s from %N, total %i", damage, victim, tankIndex, className, attacker, g_tanks[tankIndex][attacker]);
		}
	}
}

public OnEntityDestroyed(entity)
{
	new index = GetTankIndex(entity);
	if (index >= 0 && IsValidEntity(entity)) {
		new hp = GetEntProp(entity, Prop_Data, "m_iHealth");
		new maxHp = GetEntProp(entity, Prop_Data, "m_iMaxHealth");
		if (hp <= 0 && maxHp > 0) {
			//LogMessage("Tank %i/%i destroyed: hp=%i, maxHp=%i", entity, index, hp, maxHp);
			ShowTankWinner(entity, index);
			g_tanks[index][0] = 0;	
		}
	}
}

// STATS HANDLING =====================================================

UpdateWaveScores(wave)
{
	//LogMessage("UpdateWaveScores %i", wave);
	
	new Float:scores[MaxClients+1];
	new statCount = 0;
	
	for (new stat = 0; stat < MAXSTATS; stat++) {
		if (g_scoreWeights[stat] > 0) {
			statCount++;
			
			new Float:total = 0.0;
			
			for(new client = 0; client < MaxClients; client++) {
				if (IsValidClient(client) && g_stats[client][wave][stat] > 0) {
					total += g_stats[client][wave][stat];
				}
			}
			
			//LogMessage(" Updatings scores for stat %i with weight %f, current total %f", stat, g_scoreWeights[stat], total);
			
			for(new client = 0; client < MaxClients; client++) {
				if (IsValidClient(client) && g_stats[client][wave][stat] > 0) {
					new Float:score = (g_stats[client][wave][stat]/total) * g_scoreWeights[stat];
					scores[client] += score;
					//LogMessage("  %N score for stat %i is %i/%f, total %f", client, stat, g_stats[client][wave][stat], score, scores[client]);
				}
			}
		}
	}
	
	for(new client = 0; client < MaxClients; client++) {
		if (IsValidClient(client)) {
			new Float:avgScore = scores[client]/statCount;
			g_stats[client][wave][SCORE] = RoundFloat(avgScore*100.0);
			//LogMessage("%N avg score is %f, statCount=%i, final score is %i", client, avgScore, statCount, g_stats[client][wave][SCORE]);
		}
	}
}

/*
public Action:ResetRound(Handle:event, const String:name[], bool:dontBroadcast)
{
	//LogMessage("ResetRound");
	
	new mvmStatsEntity = FindEntityByClassname(-1, "tf_mann_vs_machine_stats");
	if (IsValidEntity(mvmStatsEntity)) {
		new currentWave = GetEntProp(mvmStatsEntity, Prop_Send, "m_iCurrentWaveIdx");
		//LogMessage("Reset to wave %i", currentWave);
		g_currentWave = currentWave;
	}

	return Plugin_Continue;
}
*/

ResetClientStats(client)
{
	//LogMessage("ResetClientStats: %N", client); 
	
	for(new wave = 0; wave <  MAXWAVES; wave++) {
		for (new stat = 0; stat < MAXSTATS; stat++) {
			g_stats[client][wave][stat] = 0;
		}
	}
	
	for(new tank = 0; tank < sizeof(g_tanks); tank++) {
		g_tanks[tank][client] = 0;
	}
}

ResetWaveStats(wave)
{
	//LogMessage("ResetWaveStats: %i", wave); 
	
	for(new client = 0; client < MaxClients; client++) {
		for (new stat = 0; stat < MAXSTATS; stat++) {
			g_stats[client][wave][stat] = 0;
		}
	}
	
	ResetAllTanks();
}

ResetAllStats()
{
	//LogMessage("ResetAllStats"); 
	
	for(new client = 0; client < MaxClients; client++) {
		for(new wave = 0; wave <  MAXWAVES; wave++) {
			for (new stat = 0; stat < MAXSTATS; stat++) {
				g_stats[client][wave][stat] = 0;
			}
		}
	}
	
	ResetAllTanks();
}

// STATS SORTING =====================================================

GetWaveStatsSorted(stats[][], waveIndex, statIndex)
{
	new statCount = 0;
	
	for(new client = 0; client < MaxClients; client++) {
		if (IsValidClient(client)) {
			stats[client][0] = client;
			stats[client][1] = g_stats[client][waveIndex][statIndex];
			statCount++;
		} else {
			stats[client][0] = -1;
			stats[client][1] = -1;
		}
	}
	
	SortCustom2D(stats, MaxClients, SortStatsDesc);
	
	return statCount;
}

public SortStatsDesc(x[], y[], array[][], Handle:data)
{
	if (x[1] > y[1])
		return -1;
	else if (x[1] < y[1])
		return 1;
	return 0;
}

// TANKS STATS HANDLING =====================================================

RegisterTank(entity)
{
	for(new i=0; i<sizeof(g_tanks); i++) {
		if (g_tanks[i][0] == 0) {
			ResetTank(i);
			g_tanks[i][0] = entity;
			return i;
		}
	}
	
	LogMessage("WARNING: Unable to register tank entity %i!", entity);
	return -1;
}

GetTankIndex(entity)
{
	for(new i=0; i<sizeof(g_tanks); i++) {
		if (g_tanks[i][0] == entity) {
			return i;
		}
	}
	
	return -1;
}

ResetAllTanks()
{
	//LogMessage("ResetAllTanks"); 
	
	for(new tank = 0; tank < sizeof(g_tanks); tank++) {
		ResetTank(tank);
	}
}

ResetTank(tank)
{
	//LogMessage("ResetTank %i", tank); 

	for(new client = 0; client < MaxClients; client++) {
		g_tanks[tank][client] = 0;
	}
	
	g_tanks[tank][0] = 0;
}

// MVP =====================================================

ShowWaveWinner(wave)
{
	new maxScore = 0;
	new waveWinner = 0;
	
	for(new client = 0; client < MaxClients; client++) {
		if (IsValidClient(client)) {
			if (g_stats[client][wave][SCORE] > maxScore) {
				maxScore = g_stats[client][wave][SCORE];
				waveWinner = client;
			}
		}
	}

	LogMessage("Wave MVP: %N %i points!", waveWinner, maxScore);
	//PrintCenterTextAll("Wave MVP: %N %i points!", waveWinner, maxScore);

	new Handle:hudHandle = CreateHudSynchronizer();
	SetHudTextParams(-1.0, 0.42, 15.0, 255, 255, 255, 255);

	for(new client = 0; client < MaxClients; client++) {
		if (IsValidClient(client)) {
			ShowSyncHudText(client, hudHandle, "Wave MVP: %N %i points!", waveWinner, maxScore);
		}
	}
	
	CloseHandle(hudHandle);
}

ShowTankWinner(entity, index)
{
	new maxDamage = 0;
	new tankWinner = 0;
	
	for(new client = 0; client < MaxClients; client++) {
		if (IsValidClient(client)) {
			if (g_tanks[index][client] > maxDamage) {
				maxDamage = g_tanks[index][client];
				tankWinner = client;
			}
		}
	}

	new maxHp = GetEntProp(entity, Prop_Data, "m_iMaxHealth");
	new percent = RoundToFloor((float(maxDamage)/float(maxHp)) * 100.0);
	LogMessage("Tank MVP: %N %i%% damage!", tankWinner, percent);
	//PrintCenterTextAll("Tank MVP: %N %i%% damage!", tankWinner, percent);
	
	new Handle:hudHandle = CreateHudSynchronizer();
	SetHudTextParams(-1.0, 0.5, 5.0, 255, 255, 255, 255);

	for(new client = 0; client < MaxClients; client++) {
		if (IsValidClient(client)) {
			ShowSyncHudText(client, hudHandle, "Tank MVP: %N %i%% damage!", tankWinner, percent);
		}
	}
	
	CloseHandle(hudHandle);
}

// PANEL HANDLING =====================================================

public Action:StatsCommand(client, args)
{
	//LogMessage("StatsCommand: %N", client);
	
	if(!client) {
		PrintToServer("[MvM Stats] %t", "Command is in-game only");
		return Plugin_Handled;
	}
	
	if (g_currentWave < 0) {
		PrintToChat(client, "[MvM Stats] No waves complete");
		return Plugin_Handled;
	}
	
	UpdateWaveScores(g_currentWave);
	
	ShowWaveStatsClient(client, g_currentWave);
	
	return Plugin_Handled;
}

ShowWaveStatsAll(wave)
{
	for(new client = 0; client < MaxClients; client++) {
		if (IsValidClient(client)) {
			ShowWaveStatsClient(client, wave);
			PrintToChat(client, "Type !mvmstats anytime to popup stats menu");
		}
	}
}

ShowWaveStatsClient(client, wave)
{
	ShowPanel(client, wave, 0);
}

ShowPanel(client, wave, panelIndex)
{
	new stat = g_panelOrder[panelIndex];
	g_lastPanel[client] = panelIndex;

	new stats[MaxClients+1][2];
	
	new Handle:panel = CreatePanel();
	
	new String:title[128];
	Format(title, sizeof(title), "[Wave %i] %s", (wave+1), g_panelTitles[panelIndex]);
	SetPanelTitle(panel, title);
		
	DrawPanelText(panel, " ");

	new statCount = GetWaveStatsSorted(stats, wave, stat);
	DrawWaveStat(panel, stats, statCount);
	
	DrawPanelText(panel, " ");
	
	new String:prev[32];
	new String:next[32];
	
	if (panelIndex == 0)  {
		Format(prev, sizeof(prev), "<Last] %s", g_panelTitles[sizeof(g_panelTitles)-1]);
		DrawPanelItem(panel, prev);
	} else {
		Format(prev, sizeof(prev), "<Prev] %s", g_panelTitles[panelIndex-1]);
		DrawPanelItem(panel, prev);
	}
	
	// next
	if (panelIndex == sizeof(g_panelTitles)-1) {
		Format(next, sizeof(next), "[First> %s", g_panelTitles[0]);
		DrawPanelItem(panel, next);
	} else {
		Format(next, sizeof(next), "[Next> %s", g_panelTitles[panelIndex+1]);
		DrawPanelItem(panel, next);
	}

	DrawPanelItem(panel, "[Exit]");
	
	SendPanelToClient(panel, client, PanelHandler, 20);
	
	CloseHandle(panel);
}

public PanelHandler(Handle:panel, MenuAction:action, client, key)
{
	if (action == MenuAction_Select) {
		if (key == 1) {
			new prevPanel = g_lastPanel[client]-1;
			if (prevPanel < 0) {
				prevPanel = sizeof(g_panelOrder)-1;
			}
		
			//LogMessage("PanelHandler <Prev: %N", client);
			EmitSoundToClient(client, g_panelButton);
			ShowPanel(client, g_currentWave, prevPanel);
		} else if (key == 2) {
			new nextPanel = g_lastPanel[client]+1;
			if (nextPanel > sizeof(g_panelOrder)-1) {
				nextPanel = 0;
			}

			//LogMessage("PanelHandler Next>: %N", client);
			EmitSoundToClient(client, g_panelButton);
			ShowPanel(client, g_currentWave, nextPanel);
		} else {
			//LogMessage("PanelHandler Exit: %N", client);
			EmitSoundToClient(client, g_panelExit);
		}
	}
}

DrawWaveStat(Handle:panel, stats[][], statCount)
{
	decl String:line[128];
	decl String:playerScore[12];
	decl String:playerClass[32];
	decl String:widthString[16];
	decl String:lineFormat[32];
	
	strcopy(lineFormat, sizeof(lineFormat), "%-{width}i   %s   %N");

	new maxLen = 0;
	for(new i = 0; i < statCount; i++) {
		IntToString(stats[i][1], playerScore, sizeof(playerScore));
		new scoreLen = strlen(playerScore);
		if (scoreLen > maxLen)
			maxLen = scoreLen;
	}
	
	IntToString(maxLen+3, widthString, sizeof(widthString));
	ReplaceString(lineFormat, sizeof(lineFormat), "{width}", widthString);
	
	for(new i = 0; i < statCount; i++) {
		GetClientClassName(stats[i][0], playerClass, sizeof(playerClass));
		Format(line, sizeof(line), lineFormat, stats[i][1],  playerClass, stats[i][0]);
		DrawPanelText(panel, line);
	}
}

public GetClientClassName(client, String:className[], classNameSize)
{
	new TFClassType:class = TF2_GetPlayerClass(client);
	
	if (class == TFClass_Scout)
		strcopy(className, classNameSize, "Scout          ");
	else if (class == TFClass_Sniper)
		strcopy(className, classNameSize, "Sniper         ");
	else if (class == TFClass_Soldier)
		strcopy(className, classNameSize, "Soldier        ");
	else if (class == TFClass_DemoMan)
		strcopy(className, classNameSize, "Demoman   ");
	else if (class == TFClass_Medic)
		strcopy(className, classNameSize, "Medic          ");
	else if (class == TFClass_Heavy)
		strcopy(className, classNameSize, "Heavy         ");
	else if (class == TFClass_Pyro)
		strcopy(className, classNameSize, "Pyro            ");
	else if (class == TFClass_Spy)
		strcopy(className, classNameSize, "Spy             ");
	else if (class == TFClass_Engineer)
		strcopy(className, classNameSize, "Engineer     ");
	else
		strcopy(className, classNameSize, "");
}

// MISC UTILITIES =====================================================

IsValidClient(client, bool:replay = true)
{
	if(client <= 0 || client > MaxClients || !IsClientConnected(client) || IsFakeClient(client) || !IsClientInGame(client) || GetEntProp(client, Prop_Send, "m_bIsCoaching")) 
		return false;
		
	if(replay && (IsClientSourceTV(client) || IsClientReplay(client))) 
		return false;
		
	return true;
}
