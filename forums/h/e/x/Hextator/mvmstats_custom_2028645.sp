/**
* TF2 MvM Stats Plugins v1.1 (12/16/2012)
* 
* Change Log:
*  1.5h - 20130904
*   Added interface for viewing totals
*   Added mission MVP and loser tracking
*  1.4h - 20130904
*   Red Money scoring fixed
*  1.3h - 20130901
*   Bugfixes due to Red Money update
*   Updated enum values used to represent Vaccinator effects based on updated tf2.inc
*  1.2h - 20130314
*   Updates by Hextator start here; indicated by version number suffixed with "h"
*   MUCH better scoring calculation
*   MUCH better menu navigation
*   Support for viewing any completed wave and the stats of the last failed wave
*  1.1 - 12/16/2012 
*   Better scoring calculation
*   Reduced tank MVP display to 5 seconds
*   Better message positioning
*  1.0 - 12/14/2012 
*   Initial Release
* 
* Author:
*  Moosehead (Monospace Software LLC)
* Current contributor:
*  Hextator (see credits)
* 
* Credit To:
*  Hextator
*	http://steamcommunity.com/profiles/76561198055341804
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
#include <tf2>

#pragma semicolon 1

#define PLUGIN_VERSION "1.5h"

#define MAXWAVES 11
#define MAXSTATS 19
#define MAXTANKS 8
#define DEBUG_ADJUSTED_DAMAGE 1
#if defined DEBUG_ADJUSTED_DAMAGE
#define MAXPANELS 18
new bool:g_debugAdjustedDamage = true;
#else
#define MAXPANELS 15
new bool:g_debugAdjustedDamage = false;
#endif

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
#define UBER_MEDIC_KILL 13
#define ADJUSTED_BOT_DAMAGE 14
#define ADJUSTED_GIANT_DAMAGE 15
#define ADJUSTED_TANK_DAMAGE 16
#define UBER_DEPLOYED 17
#define BUFF_DEPLOYED 18

new g_stats[MAXPLAYERS+1][MAXWAVES+1][MAXSTATS+1];
new Float:g_totals[MAXWAVES+1][MAXSTATS+1];

// Bomb reset variables
new bool:g_bombResetBonus[MAXPLAYERS+1];

#define TFCondLen 255
// _:TFCond may not evaluate correctly due to tf2.inc's
// TFCond enum being of date and missing some elements

// Status bonus variables
// NOTE: First flag is used to signal that a buff has been given
// The flag should be cleared when another flag is set to indicate which buff it is
// The flags for all players giving a buff to a player should be cleared for that
// buff when the buff wears off of the target
new bool:g_statusBonus[MAXPLAYERS+1][MAXPLAYERS+1][TFCondLen+1];
// Similar to the above; used for detecting which power is being shared
// via canteen sharing
new bool:g_canteenActive[MAXPLAYERS+1][TFCondLen+1];

// (Soldier) buff variables
// For buffs; shouldn't be necessary but the player_buff event is being strange(?)
new const TFCond:g_buffTranslations[] = {
	TFCond:0,
	TFCond_Buffed,
	TFCond_DefenseBuffed,
	TFCond_RegenBuffed
};
new g_buffCounter = 0;
new g_buffOrder[MAXPLAYERS+1];
new TFCond:g_buffActive[MAXPLAYERS+1];

// Stun bonus variables
new g_lastDamagedBy[MAXPLAYERS+1];
new g_lastStunnedBy[MAXPLAYERS+1];

// Red money variables
new bool:g_currencyInit = false;
new bool:g_recentRifleKill[MAXPLAYERS+1];
new g_currencyDuringPreviousFrame[MAXPLAYERS+1];
new bool:g_recentMoneyGrab[MAXPLAYERS+1];
new g_currencyGrabbedSincePreviousFrame = 0;

new g_currentWave = 0;
new g_currentWaveToView[MAXPLAYERS+1];

new g_tanks[MAXTANKS+1][MAXPLAYERS+1];

new Float:g_scoreWeights[MAXSTATS+1];
new Float:g_damageWeightTotal = 0.0;
new Float:g_statTotal = 0.0;

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
	//InitScoreWeights();
	InitHooks();
	
	new mvmStatsEntity = FindEntityByClassname(-1, "tf_mann_vs_machine_stats");
	if (IsValidEntity(mvmStatsEntity)) {
		new currentWave = GetEntProp(mvmStatsEntity, Prop_Send, "m_iCurrentWaveIdx");
		g_currentWave = currentWave;
		for (new player = 0; player < MAXPLAYERS+1; player++) {
			g_currentWaveToView[player] = g_currentWave;
		}
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

	new index = 0;
	g_panelTitles[index++]  = "MvM SCORE (Percentage)";
	g_panelTitles[index++] = "ACTUAL BOT DAMAGE";
	if (g_debugAdjustedDamage) {
		g_panelTitles[index++]  = "VISIBLE BOT DAMAGE";
	}
	g_panelTitles[index++] = "ACTUAL GIANT DAMAGE";
	if (g_debugAdjustedDamage) {
		g_panelTitles[index++]  = "VISIBLE GIANT DAMAGE";
	}
	g_panelTitles[index++] = "ACTUAL TANK DAMAGE";
	if (g_debugAdjustedDamage) {
		g_panelTitles[index++] = "VISIBLE TANK DAMAGE";
	}
	g_panelTitles[index++] = "CASH COLLECTED";
	g_panelTitles[index++] = "BOMB RESETS";
	g_panelTitles[index++] = "BOMB DEPLOY RESETS";
	g_panelTitles[index++] = "UBER MEDIC KILLS";
	g_panelTitles[index++] = "BOMB DEFENSES";
	g_panelTitles[index++] = "ASSISTS";
	g_panelTitles[index++] = "UBERS DEPLOYED";
	g_panelTitles[index++] = "BUFFS DEPLOYED";
	g_panelTitles[index++] = "CANTEENS USED";
	g_panelTitles[index++] = "BOT KILLS";
	g_panelTitles[index++] = "GIANT KILLS";

	index = 0;
	g_panelOrder[index++]  = SCORE;
	g_panelOrder[index++] = ADJUSTED_BOT_DAMAGE;
	if (g_debugAdjustedDamage) {
		g_panelOrder[index++]  = BOT_DAMAGE;
	}
	g_panelOrder[index++] = ADJUSTED_GIANT_DAMAGE;
	if (g_debugAdjustedDamage) {
		g_panelOrder[index++]  = GIANT_DAMAGE;
	}
	g_panelOrder[index++] = ADJUSTED_TANK_DAMAGE;
	if (g_debugAdjustedDamage) {
		g_panelOrder[index++] = TANK_DAMAGE;
	}
	g_panelOrder[index++] = CASH_PICKUP;
	g_panelOrder[index++] = BOMB_RESET;
	g_panelOrder[index++] = BOMB_DEPLOY_RESET;
	g_panelOrder[index++] = UBER_MEDIC_KILL;
	g_panelOrder[index++] = BOMB_DEFENDED;
	g_panelOrder[index++] = ASSIST;
	g_panelOrder[index++] = UBER_DEPLOYED;
	g_panelOrder[index++] = BUFF_DEPLOYED;
	g_panelOrder[index++] = CANTEEN_USED;
	g_panelOrder[index++] = BOT_KILL;
	g_panelOrder[index++] = GIANT_KILL;
}

InitScoreWeights()
{
	// Altogether, weights should average 1.0

	// Old weights for each category used to determine the MvM score/wave winner

	// g_scoreWeights[BOT_DAMAGE] = 1.2;
	// g_scoreWeights[BOT_KILL] = 0.8;
	// g_scoreWeights[ASSIST] = 1.1;
	// g_scoreWeights[CASH_PICKUP] = 1.1;
	// g_scoreWeights[TANK_DAMAGE] = 1.0;
	// g_scoreWeights[GIANT_DAMAGE] = 1.2;
	// g_scoreWeights[GIANT_KILL] = 0.6;

	g_statTotal = 0.0;
	// Base scoring is done by adjusted damage
	g_scoreWeights[ADJUSTED_BOT_DAMAGE] = 1.0; g_statTotal += 1.0;
	// Tanks require serious attention
	g_scoreWeights[ADJUSTED_TANK_DAMAGE] = 1.5 * g_scoreWeights[ADJUSTED_BOT_DAMAGE]; g_statTotal += 1.0;
	// Damaging giants is more important than damaging small bots
	g_scoreWeights[ADJUSTED_GIANT_DAMAGE] = 1.5 * g_scoreWeights[ADJUSTED_BOT_DAMAGE]; g_statTotal += 1.0;
	g_damageWeightTotal = (
		g_scoreWeights[ADJUSTED_BOT_DAMAGE] +
		g_scoreWeights[ADJUSTED_TANK_DAMAGE] +
		g_scoreWeights[ADJUSTED_GIANT_DAMAGE]
	);
	// Picking up cash is 70% as important as dealing damage because only about 70%
	// of the cash is needed to win (usually, and this is from PE so it may need adjusting)
	// Additionally, picking up cash is about 60% of the job of the person assigned the task,
	// so another 40% penalty in score value is incurred
	// Finally, cash is only able to be picked up if it is made to appear to begin with,
	// so another 30% penalty is incurred
	g_scoreWeights[CASH_PICKUP] = 0.7 * 0.6 * 0.7 * g_damageWeightTotal; g_statTotal += 1.0;
	// Killing uber medics is about 60% of the job of someone who is assigned the task,
	// so it is ranked as 60% as important as dealing damage
	g_scoreWeights[UBER_MEDIC_KILL] = 0.6 * g_damageWeightTotal; g_statTotal += 1.0;
	new Float:weightTotal = 0.0;
	for (new index = 0; index < MAXSTATS+1; index++) {
		weightTotal += g_scoreWeights[index];
	}
	// Bomb defenses buy the group a few precious seconds and total
	// 10% of the score (arbitrary guess at their worth; may need adjusting)
	g_scoreWeights[BOMB_DEFENDED] = 0.1 * weightTotal; g_statTotal += 1.0;
}

NormalizeWeights(bool:damageOnly = false) {
	new Float:weightTotal = 0.0;
	new Float:statTotal = damageOnly? g_damageWeightTotal : 0.0;
	//new Float:statTotalToReport = damageOnly? 3.0 : 0.0;
	for (new index = 0; index < MAXSTATS+1; index++) {
		if (
			!damageOnly ||
			index == ADJUSTED_BOT_DAMAGE ||
			index == ADJUSTED_TANK_DAMAGE ||
			index == ADJUSTED_GIANT_DAMAGE
		) {
			new Float:currWeight = g_scoreWeights[index];
			weightTotal += currWeight;
			if (!damageOnly && currWeight > 0) {
				statTotal += 1.0;
			}
		}
	}
	//if (!damageOnly) { statTotalToReport = statTotal; }
	//LogMessage("Stat total: %f", statTotalToReport);
	//LogMessage("Weight total: %f", weightTotal);
	new Float:normalFact = 0.0;
	if (weightTotal > 0) {
		normalFact = statTotal/weightTotal;
	}
	if (statTotal == 0.0) {
		return;
	}
	//LogMessage("Normalization factor: %f", normalFact);
	for (new index = 0; index < MAXSTATS+1; index++) {
		if (
			!damageOnly ||
			index == ADJUSTED_BOT_DAMAGE ||
			index == ADJUSTED_TANK_DAMAGE ||
			index == ADJUSTED_GIANT_DAMAGE
		) {
			g_scoreWeights[index] *= normalFact;
			// LogMessage(
				// "New weight: %f, %2.0f%",
				// g_scoreWeights[index],
				// (g_scoreWeights[index]/statTotal) * 100.0
			// );
		}
	}
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

	// These don't seem to fire reliably
	// (Actually this first one seems to work pretty well)
	HookEvent("mvm_kill_robot_delivering_bomb", BombDefended);
	HookEvent("mvm_bomb_reset_by_player", BombReset);
	HookEvent("mvm_bomb_deploy_reset_by_player", BombDeployReset);

	// New hooks

	HookEvent("mvm_bomb_alarm_triggered", BombAlarmTriggered);

	HookEvent("mvm_medic_powerup_shared", MedicPowerShared);
	HookEvent("player_chargedeployed", PlayerChargeDeployed);
	HookEvent("player_invulned", PlayerInvulned);
	HookEvent("medic_death", MedicDeath);

	HookEvent("deploy_buff_banner", DeployBuffBanner);
	HookEvent("player_buff", PlayerBuff);

	HookUserMessage(GetUserMessageId("PlayerJarated"), Event_PlayerSplashed);
	// These 2 events don't work; using above
	//HookEvent("player_jarated", PlayerJarated);
	//HookEvent("player_jarated_fade", PlayerJaratedFade);

	// This event doesn't work; using g_lastDamagedBy
	//HookEvent("mvm_scout_marked_for_death", ScoutDeathMark);

	HookEvent("player_stunned", PlayerStunned);
	// This event doesn't work; using above
	// I'm starting to wonder how anything Valve does works even sometimes
	//HookEvent("player_sapped_object", PlayerSappedObject);

	// TODO:
	// Engineer dispenser health and ammo bonuses
	// Give credit for Red Money to Sniper instead of those who pick it up
	// Medic heal bonus (for low HP players only?)
		// Link to thread with info on getting max HP
		// to determine if heal target is at low health, overhealed etc.
		// http://forums.alliedmods.net/showthread.php?t=67502
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

HandleRedMoney() {
	// Red money handling
	if (g_currencyInit) {
		new playersWithRifleKills = 0;
		new redMoneyGained = 0;
		for (new player = 0; player < MAXPLAYERS+1; player++) {
			if (g_recentRifleKill[player]) {
				// LogMessage("Recent rifle kill");
				playersWithRifleKills++;
				new previousCurrency = g_currencyDuringPreviousFrame[player];
				g_currencyDuringPreviousFrame[player] = GetEntProp(player, Prop_Send, "m_nCurrency");
				new gainedCurrency = g_currencyDuringPreviousFrame[player] - previousCurrency;
				if (gainedCurrency > 0) {
					redMoneyGained += gainedCurrency;
				}
			}
		}
		if (playersWithRifleKills != 0 && redMoneyGained > 0) {
			new redMoneyToGive = redMoneyGained/playersWithRifleKills;
			for (new player = 0; player < MAXPLAYERS+1; player++) {
				if (g_recentRifleKill[player]) {
					g_stats[player][g_currentWave][CASH_PICKUP] += redMoneyToGive;
					// LogMessage("Player %N received credit for %d$ of red money", player, redMoneyToGive);
				}
			}
		}
		new playersWithMoneyGrabs = 0;
		new greenMoneyGained = 0;
		for (new player = 0; player < MAXPLAYERS+1; player++) {
			if (g_recentMoneyGrab[player]) {
				// LogMessage("Recent money grab");
				playersWithMoneyGrabs++;
				new previousCurrency = g_currencyDuringPreviousFrame[player];
				g_currencyDuringPreviousFrame[player] = GetEntProp(player, Prop_Send, "m_nCurrency");
				new gainedCurrency = g_currencyDuringPreviousFrame[player] - previousCurrency;
				if (gainedCurrency > 0) {
					greenMoneyGained += gainedCurrency;
				}
			}
		}
		new redMoneyTouched = g_currencyGrabbedSincePreviousFrame - greenMoneyGained;
		if (playersWithMoneyGrabs != 0 && redMoneyTouched > 0) {
			new redMoneyToTake = redMoneyTouched/playersWithMoneyGrabs;
			for (new player = 0; player < MAXPLAYERS+1; player++) {
				if (g_recentMoneyGrab[player]) {
					g_stats[player][g_currentWave][CASH_PICKUP] -= redMoneyToTake;
					// LogMessage("Player %N lost credit for %d$ of red money", player, redMoneyToTake);
				}
			}
		}
	}
	else {
		for (new player = 0; player < MAXPLAYERS+1; player++) {
			g_recentRifleKill[player] = false;
			g_recentMoneyGrab[player] = false;
		}
		g_currencyGrabbedSincePreviousFrame = 0;
	}
	for (new player = 0; player < MAXPLAYERS+1; player++) {
		if (!g_recentRifleKill[player] && !g_recentMoneyGrab[player] && IsValidClient(player)) {
			g_currencyDuringPreviousFrame[player] = GetEntProp(player, Prop_Send, "m_nCurrency");
		}
		g_recentRifleKill[player] = false;
		g_recentMoneyGrab[player] = false;
	}
	g_currencyGrabbedSincePreviousFrame = 0;
	g_currencyInit = true;
}

public OnGameFrame() {
	HandleRedMoney();
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
	for (new player = 0; player < MAXPLAYERS+1; player++) {
		g_currentWaveToView[player] = g_currentWave;
	}
	
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
		//ResetWaveStats(g_currentWave);
		ResetScoreBonuses();
		//if (g_currentWave > 0)
			//g_currentWave--;

		UpdateWaveScores(g_currentWave);
		ShowWaveStatsAll(g_currentWave);
		ShowWaveWinner(g_currentWave);
	}
}

public WaveComplete(Handle:event, const String:name[], bool:dontBroadcast)
{
	LogMessage("Wave %i Won", g_currentWave);

	ResetScoreBonuses();

	UpdateWaveScores(g_currentWave);
	ShowWaveStatsAll(g_currentWave);
	ShowWaveWinner(g_currentWave);
}

public MissionComplete(Handle:event, const String:name[], bool:dontBroadcast)
{
	decl String:mission[128];
	GetEventString(event, "mission", mission, sizeof(mission));

	ResetScoreBonuses();
	
	LogMessage("MissionComplete: %s", mission);
}

// STAT EVENTS =====================================================

AddAdjustedTankDamage(attacker, victim, damage, adjustedDamageIndex) {
	// LogMessage(
		// "Tank Damage! %i to %i from %N",
		// damage, victim, attacker
	// );
	if (adjustedDamageIndex == ADJUSTED_TANK_DAMAGE) {
		new tankIndex = GetTankIndex(victim);
		if (tankIndex >= 0) {
			g_tanks[tankIndex][attacker] += damage;
			// LogMessage(
				// "Tank Damage! %i to %i/%i from %N, total %i",
				// damage,
				// victim, tankIndex,
				// attacker, g_tanks[tankIndex][attacker]
			// );
		}
	}
}

DamageAdjust(attacker, victim, damage, adjustedDamageIndex, bool:wasCrit, bool:wasMiniCrit) {
	new Float:adjustedDamage = float(damage);
	// Written oddly to suppress a negligible warning
	new bool:crits = wasCrit; crits = false;
	new bool:realCrits = false;
	new bool:miniCrits = false;
	new bool:sapped = false;
	new bool:uber = false;
	//LogMessage("Reached DamageAdjust for TFCond_Kritzkrieged");
	for (new buffOwner = 0; buffOwner < MaxClients && !crits; buffOwner++) {
		new Float:buffDamage = 0.0;
		// If Kritz'd
		if (
			IsValidClient(buffOwner) &&
			g_statusBonus[buffOwner][attacker][TFCond_Kritzkrieged]
		) {
			// LogMessage(
				// "Damage while Kritzkrieg'd by %N against %N thanks to %N",
				// attacker, victim, buffOwner
			// );
			crits = true;
			buffDamage = (adjustedDamage * 2)/3;
			adjustedDamage -= buffDamage;
			g_stats[buffOwner][g_currentWave][adjustedDamageIndex] +=
				RoundFloat(buffDamage);
			AddAdjustedTankDamage(
				buffOwner, victim,
				RoundFloat(buffDamage), adjustedDamageIndex
			);
			break;
		}
	}
	//LogMessage("Reached DamageAdjust for TFCond_CritCanteen");
	for (new buffOwner = 0; buffOwner < MaxClients && !crits; buffOwner++) {
		new Float:buffDamage = 0.0;
		// If Crit canteen'd
		if (
			IsValidClient(buffOwner) &&
			g_statusBonus[buffOwner][attacker][TFCond_CritCanteen]
		) {
			// LogMessage(
				// "Damage while Crit canteen'd by %N against %N thanks to %N",
				// attacker, victim, buffOwner
			// );
			crits = true;
			buffDamage = (adjustedDamage * 2)/3;
			adjustedDamage -= buffDamage;
			g_stats[buffOwner][g_currentWave][adjustedDamageIndex] +=
				RoundFloat(buffDamage);
			AddAdjustedTankDamage(
				buffOwner, victim,
				RoundFloat(buffDamage), adjustedDamageIndex
			);
			break;
		}
	}
	realCrits = crits;
	// Check if the player is giving crits to themselves to avoid
	// giving a buff bonus to someone who is buffing a self-buffed
	// player with crits
	if (
		TF2_IsPlayerInCondition(attacker, TFCond_CritCanteen) ||
		TF2_IsPlayerInCondition(attacker, TFCond_Kritzkrieged)// ||
		// This seems to break stuff
		//wasCrit
	) { crits = true; }
	//LogMessage("Reached DamageAdjust for TFCond_Jarated");
	for (new buffOwner = 0; buffOwner < MaxClients && !crits && !miniCrits; buffOwner++) {
		new Float:buffDamage = 0.0;
		// If target is Jarate'd
		if (
			IsValidClient(buffOwner) &&
			adjustedDamageIndex != ADJUSTED_TANK_DAMAGE &&
			g_statusBonus[buffOwner][victim][TFCond_Jarated]
		) {
			// LogMessage(
				// "Mini crit due to Jarate by %N against %N thanks to %N",
				// attacker, victim, buffOwner
			// );
			miniCrits = true;
			buffDamage = (adjustedDamage * 35)/135;
			adjustedDamage -= buffDamage;
			g_stats[buffOwner][g_currentWave][adjustedDamageIndex] +=
				RoundFloat(buffDamage);
			// AddAdjustedTankDamage(
				// buffOwner, victim,
				// RoundFloat(buffDamage), adjustedDamageIndex
			// );
			break;
		}
	}
	//LogMessage("Reached DamageAdjust for TFCond_MarkedForDeath");
	// XXX: Crit flag is set when hitting a death marked target even if it's not a crit
	// This is a pretty nasty bug, Valve.
	// Because of this, Scout's death mark will steal 35/135 damage from random crits
	// and headshots.
	for (new buffOwner = 0; buffOwner < MaxClients && !realCrits && !miniCrits; buffOwner++) {
		new Float:buffDamage = 0.0;
		// If target is marked for death
		if (
			IsValidClient(buffOwner) &&
			adjustedDamageIndex != ADJUSTED_TANK_DAMAGE &&
			g_statusBonus[buffOwner][victim][TFCond_MarkedForDeath]
		) {
			// LogMessage(
				// "Mini crit due to death mark by %N against %N thanks to %N",
				// attacker, victim, buffOwner
			// );
			// miniCrits = true;
			buffDamage = (adjustedDamage * 35)/135;
			// Can't reliably deduct because of crit flag bug
			if (buffOwner == attacker) {
				adjustedDamage -= buffDamage;
			}
			g_stats[buffOwner][g_currentWave][adjustedDamageIndex] +=
				RoundFloat(buffDamage);
			// AddAdjustedTankDamage(
				// buffOwner, victim,
				// RoundFloat(buffDamage), adjustedDamageIndex
			// );
			break;
		}
	}
	//LogMessage("Reached DamageAdjust for TFCond_Buffed");
	for (new buffOwner = 0; buffOwner < MaxClients && !crits && !miniCrits; buffOwner++) {
		new Float:buffDamage = 0.0;
		// If Buff Banner'd
		if (
			IsValidClient(buffOwner) &&
			g_statusBonus[buffOwner][attacker][TFCond_Buffed]
		) {
			miniCrits = true;
			buffDamage = (adjustedDamage * 35)/135;
			adjustedDamage -= buffDamage;
			g_stats[buffOwner][g_currentWave][adjustedDamageIndex] +=
				RoundFloat(buffDamage);
			AddAdjustedTankDamage(
				buffOwner, victim,
				RoundFloat(buffDamage), adjustedDamageIndex
			);
			break;
		}
	}
	if (wasMiniCrit) { miniCrits = true; }
	//LogMessage("Reached DamageAdjust for TFCond_Sapped");
	for (new buffOwner = 0; buffOwner < MaxClients && !uber; buffOwner++) {
		new Float:buffDamage = 0.0;
		// If Sapped
		if (
			IsValidClient(buffOwner) &&
			adjustedDamageIndex != ADJUSTED_TANK_DAMAGE &&
			g_statusBonus[buffOwner][victim][TFCond_Sapped]
		) {
			// LogMessage(
				// "Hurt sapped target by %N against %N thanks to %N",
				// attacker, victim, buffOwner
			// );
			// 35/135 shared bonus for sapped giants,
			// 100/100 shared bonus for other sapped bots
			buffDamage = (adjustedDamage * 35)/135;
			if (adjustedDamageIndex == ADJUSTED_BOT_DAMAGE) {
				buffDamage = adjustedDamage;
				sapped = true;
			}
			// Should be unnecessary, but whatever
			if (adjustedDamageIndex == ADJUSTED_TANK_DAMAGE) {
				buffDamage = 0.0;
			}
			if (buffOwner == attacker) {
				adjustedDamage -= buffDamage;
			}
			g_stats[buffOwner][g_currentWave][adjustedDamageIndex] +=
				RoundFloat(buffDamage);
			AddAdjustedTankDamage(
				buffOwner, victim,
				RoundFloat(buffDamage), adjustedDamageIndex
			);
			break;
		}
	}
	//LogMessage("Reached DamageAdjust for TFCond_Dazed");
	for (new buffOwner = 0; buffOwner < MaxClients && !uber && !sapped; buffOwner++) {
		new Float:buffDamage = 0.0;
		// If Dazed
		if (
			IsValidClient(buffOwner) &&
			adjustedDamageIndex != ADJUSTED_TANK_DAMAGE &&
			g_statusBonus[buffOwner][victim][TFCond_Dazed]
		) {
			// LogMessage(
				// "Hurt dazed target by %N against %N thanks to %N",
				// attacker, victim, buffOwner
			// );
			// 35/135 shared bonus for dazed bots,
			// no bonus for dazed giants
			// XXX: Can giants even be dazed?
			buffDamage = (adjustedDamage * 35)/135;
			if (adjustedDamageIndex == ADJUSTED_GIANT_DAMAGE) {
				buffDamage = 0.0;
			}
			// Should be unnecessary, but whatever
			if (adjustedDamageIndex == ADJUSTED_TANK_DAMAGE) {
				buffDamage = 0.0;
			}
			if (buffOwner == attacker) {
				adjustedDamage -= buffDamage;
			}
			g_stats[buffOwner][g_currentWave][adjustedDamageIndex] +=
				RoundFloat(buffDamage);
			AddAdjustedTankDamage(
				buffOwner, victim,
				RoundFloat(buffDamage), adjustedDamageIndex
			);
			break;
		}
	}
	//LogMessage("Reached DamageAdjust for TFCond_Ubercharged");
	for (new buffOwner = 0; buffOwner < MaxClients && !uber && !sapped; buffOwner++) {
		new Float:buffDamage = 0.0;
		// If Uber'd
		if (
			IsValidClient(buffOwner) &&
			g_statusBonus[buffOwner][attacker][TFCond_Ubercharged]
		) {
			uber = true;
			buffDamage = (adjustedDamage * 2)/3;
			// if (buffOwner == attacker) {
			adjustedDamage -= buffDamage;
			// }
			g_stats[buffOwner][g_currentWave][adjustedDamageIndex] +=
				RoundFloat(buffDamage);
			AddAdjustedTankDamage(
				buffOwner, victim,
				RoundFloat(buffDamage), adjustedDamageIndex
			);
			break;
		}
	}
	//LogMessage("Reached DamageAdjust for TFCond_UberchargedCanteen");
	for (new buffOwner = 0; buffOwner < MaxClients && !uber && !sapped; buffOwner++) {
		new Float:buffDamage = 0.0;
		// If Uber canteen'd
		if (
			IsValidClient(buffOwner) &&
			g_statusBonus[buffOwner][attacker][TFCond_UberchargedCanteen]
		) {
			uber = true;
			buffDamage = (adjustedDamage * 2)/3;
			// if (buffOwner == attacker) {
			adjustedDamage -= buffDamage;
			// }
			g_stats[buffOwner][g_currentWave][adjustedDamageIndex] +=
				RoundFloat(buffDamage);
			AddAdjustedTankDamage(
				buffOwner, victim,
				RoundFloat(buffDamage), adjustedDamageIndex
			);
			break;
		}
	}
	// Check if the player is giving uber to themselves to avoid
	// giving a buff bonus to someone who is buffing a self-buffed
	// player with uber
	if (
		TF2_IsPlayerInCondition(attacker, TFCond_UberchargedCanteen) ||
		TF2_IsPlayerInCondition(attacker, TFCond_Ubercharged)
	) { uber = true; }
	//LogMessage("Reached DamageAdjust for Vaccinator Ubers");
	for (new buffOwner = 0; buffOwner < MaxClients && !uber && !sapped; buffOwner++) {
		new Float:buffDamage = 0.0;
		// If target is Uber'd by the Vaccinator
		if (
			IsValidClient(buffOwner) && (
			g_statusBonus[buffOwner][attacker][TFCond_UberBulletResist] ||
			g_statusBonus[buffOwner][attacker][TFCond_UberBlastResist] ||
			g_statusBonus[buffOwner][attacker][TFCond_UberFireResist]
		)) {
			// LogMessage(
				// "Damage while Vaccinator Uber'd by %N against %N thanks to %N",
				// attacker, victim, buffOwner
			// );
			// Can be outprioritized by full uber, but is treated
			// as an uber itself for outprioritizing other conditions
			uber = true;
			buffDamage = adjustedDamage/2;
			// if (buffOwner == attacker) {
			adjustedDamage -= buffDamage;
			// }
			g_stats[buffOwner][g_currentWave][adjustedDamageIndex] +=
				RoundFloat(buffDamage);
			AddAdjustedTankDamage(
				buffOwner, victim,
				RoundFloat(buffDamage), adjustedDamageIndex
			);
			break;
		}
	}
	//LogMessage("Reached DamageAdjust for TFCond_Milked");
	for (new buffOwner = 0; buffOwner < MaxClients && !uber; buffOwner++) {
		new Float:buffDamage = 0.0;
		// If target is Mad Milk'd
		if (
			IsValidClient(buffOwner) &&
			adjustedDamageIndex != ADJUSTED_TANK_DAMAGE &&
			g_statusBonus[buffOwner][victim][TFCond_Milked]
		) {
			// LogMessage(
				// "Damage to milked target by %N against %N thanks to %N",
				// attacker, victim, buffOwner
			// );
			buffDamage = (adjustedDamage * 60)/160;
			if (buffOwner == attacker) {
				adjustedDamage -= buffDamage;
			}
			g_stats[buffOwner][g_currentWave][adjustedDamageIndex] +=
				RoundFloat(buffDamage);
			// AddAdjustedTankDamage(
				// buffOwner, victim,
				// RoundFloat(buffDamage), adjustedDamageIndex
			// );
			break;
		}
	}
	//LogMessage("Reached DamageAdjust for TFCond_DefenseBuffed");
	for (new buffOwner = 0; buffOwner < MaxClients && !uber && !sapped; buffOwner++) {
		new Float:buffDamage = 0.0;
		// If Defense buff'd
		if (
			IsValidClient(buffOwner) &&
			g_statusBonus[buffOwner][attacker][TFCond_DefenseBuffed]
		) {
			uber = true;
			buffDamage = (adjustedDamage * 35)/135;
			if (buffOwner == attacker) {
				adjustedDamage -= buffDamage;
			}
			g_stats[buffOwner][g_currentWave][adjustedDamageIndex] +=
				RoundFloat(buffDamage);
			AddAdjustedTankDamage(
				buffOwner, victim,
				RoundFloat(buffDamage), adjustedDamageIndex
			);
			break;
		}
	}
	//LogMessage("Reached DamageAdjust for TFCond_RegenBuffed");
	for (new buffOwner = 0; buffOwner < MaxClients && !uber && !sapped; buffOwner++) {
		new Float:buffDamage = 0.0;
		// If Regen buff'd
		if (
			IsValidClient(buffOwner) &&
			g_statusBonus[buffOwner][attacker][TFCond_RegenBuffed]
		) {
			uber = true;
			buffDamage = (adjustedDamage * 35)/135;
			if (buffOwner == attacker) {
				adjustedDamage -= buffDamage;
			}
			g_stats[buffOwner][g_currentWave][adjustedDamageIndex] +=
				RoundFloat(buffDamage);
			AddAdjustedTankDamage(
				buffOwner, victim,
				RoundFloat(buffDamage), adjustedDamageIndex
			);
			break;
		}
	}
	g_stats[attacker][g_currentWave][adjustedDamageIndex] += RoundFloat(adjustedDamage);
	//LogMessage("Reached AddAdjustedTankDamage call in DamageAdjust");
	AddAdjustedTankDamage(attacker, victim, RoundFloat(adjustedDamage), adjustedDamageIndex);
}

public PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	new damage = GetEventInt(event, "damageamount");
	new bool:wasCrit = GetEventBool(event, "crit");
	new bool:wasMiniCrit = GetEventBool(event, "minicrit");
	
	if (IsValidClient(attacker) && victim != attacker && damage > 0) {
		decl String:botName[32];
		GetClientName(victim, botName, sizeof(botName));
		
		// this adjusts stats for overkill
		new hp = GetEntProp(victim, Prop_Data, "m_iHealth");
		if (hp < 0) {
			damage += hp;
		}

		new damageCount = BOT_DAMAGE;
		new adjustedDamageCount = ADJUSTED_BOT_DAMAGE;
		new bool:isGiant = false;
		if (StrContains(botName, "Giant") != -1 || StrContains(botName, "Super") != -1 || StrContains(botName, "Major") != -1) {
			damageCount = GIANT_DAMAGE;
			adjustedDamageCount = ADJUSTED_GIANT_DAMAGE;
			isGiant = true;
		}
		g_stats[attacker][g_currentWave][damageCount] += damage;
		DamageAdjust(attacker, victim, damage, adjustedDamageCount, wasCrit, wasMiniCrit);
		for (new client = 0; client < MaxClients; client++) {
			if (attacker != client && IsValidClient(client) && g_bombResetBonus[client]) {
				g_stats[client][g_currentWave][adjustedDamageCount] += damage;
			}
		}
		if (isGiant) {
			//LogMessage("Giant Damage! %d to %d %s from %d %N, total %i", damage, victim, botName, attacker, attacker, g_stats[attacker][g_currentWave][GIANT_DAMAGE]);			
		}
		else {
			
			//LogMessage("Bot Damage! %d to %d %s from %d %N, total %i", damage, victim, botName, attacker, attacker, g_stats[attacker][g_currentWave][BOT_DAMAGE]);	
		}
		g_lastDamagedBy[victim] = attacker;
	}
}

public PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new victim   = GetClientOfUserId(GetEventInt(event, "userid"));
	new weapon   = GetEventInt(event, "weaponid");
//	new custom_kill = GetEventInt(event, "customkill");
//	new death_flags = GetEventInt(event, "death_flags");
	new assister   = GetClientOfUserId(GetEventInt(event, "assister"));

	// Red money handling
	// Rifle kills since last OnGameFrame
	new bool:killerIsSniper = IsValidClient(attacker) && TF2_GetPlayerClass(attacker) == TFClass_Sniper;
	if (killerIsSniper && (
		weapon == TF_WEAPON_SNIPERRIFLE
		|| weapon == TF_WEAPON_SNIPERRIFLE_DECAP
		|| weapon == TF_WEAPON_NONE
	)) {
		g_recentRifleKill[attacker] = true && IsValidClient(attacker);
		// LogMessage("Kill by Sniper %d with %d", attacker, weapon);
	}

	// TODO: Is this unnecessary?
	for (new client = 0; client < MaxClients; client++) {
		for (new cond = 0; cond < TFCondLen; cond++) {
			g_statusBonus[client][victim][cond] = false;
		}
	}
	
	if (IsValidClient(attacker) && victim != attacker) {
		decl String:botName[32];
		GetClientName(victim, botName, sizeof(botName));
		
		if (StrContains(botName, "Giant") != -1 || StrContains(botName, "Super") != -1 || StrContains(botName, "Major") != -1) {
			g_stats[attacker][g_currentWave][GIANT_KILL]++;
			//LogMessage("Giant Kill! %i %s from %N, total %i", victim, botName, attacker, g_stats[attacker][g_currentWave][GIANT_KILL]);
		} else {
			if (StrContains(botName, "Uber") != -1) {
				g_stats[attacker][g_currentWave][UBER_MEDIC_KILL]++;
				//LogMessage("Uber Medic Kill! %i %s from %N, total %i", victim, botName, attacker, g_stats[attacker][g_currentWave][UBER_MEDIC_KILL]);
			} else {
				g_stats[attacker][g_currentWave][BOT_KILL]++;
				//LogMessage("Bot Kill! %i %s from %N, total %i", victim, botName, attacker, g_stats[attacker][g_currentWave][BOT_KILL]);
			}
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

	// Red Money handling
	g_recentMoneyGrab[client] = true && IsValidClient(client);
	g_currencyGrabbedSincePreviousFrame += amount;
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
	ResetBombResetBonuses();
	g_stats[client][g_currentWave][BOMB_DEFENDED]++;
}

public BombReset(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetEventInt(event, "player");
	//LogMessage("BombReset: %N", client);
	g_bombResetBonus[client] = true;
	g_stats[client][g_currentWave][BOMB_RESET]++;
}

public BombDeployReset(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetEventInt(event, "player");
	//LogMessage("BombDeployReset: %N", client);
	// For scoring purposes, bomb deploy resets are just a special case of bomb resets
	//g_stats[client][g_currentWave][BOMB_RESET]++;
	g_bombResetBonus[client] = true;
	g_stats[client][g_currentWave][BOMB_DEPLOY_RESET]++;
}

public BombAlarmTriggered(Handle:event, const String:name[], bool:dontBroadcast)
{
	//LogMessage("BombAlarmTriggered");
	ResetBombResetBonuses();
}

public MedicPowerShared(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetEventInt(event, "player");
	if (IsValidClient(client)) {
		//LogMessage("MedicPowerShared: %N", client);
		// Mark that canteen sharing has begun
		g_canteenActive[client][0] = true;
	}
}

public PlayerChargeDeployed(Handle:event, const String:name[], bool:dontBroadcast)
{
	// "userid"	"short"		// user ID of medic who deployed charge
	// "targetid"	"short"		// user ID of who the medic charged
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new target = GetClientOfUserId(GetEventInt(event, "targetid"));
	if (IsValidClient(client) && IsValidClient(target)) {
		g_stats[client][g_currentWave][UBER_DEPLOYED]++;
		g_statusBonus[client][target][0] = true;
		//LogMessage("PlayerChargeDeployed: %N to %N", client, target);
	}
}

public PlayerInvulned(Handle:event, const String:name[], bool:dontBroadcast)
{
	// "userid"	"short"
	// "medic_userid"	"short"
	new client = GetClientOfUserId(GetEventInt(event, "medic_userid"));
	new target = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IsValidClient(client) && IsValidClient(target)) {
		//LogMessage("PlayerInvulned: %N to %N", client, target);
	}
}

public MedicDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	// "userid"	"short"   	// user ID who died				
	// "attacker"	"short"	 	// user ID who killed
	// "healing"	"short"		// amount healed in this life
	// "charged"	"bool"		// had a full ubercharge?
	new medic = GetClientOfUserId(GetEventInt(event, "userid"));
	//new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	//new healingAmt = GetEventInt(event, "healing");
	//new bool:wasCharged = GetEventBool(event, "charged");
	if (IsValidClient(medic)) {
		// LogMessage(
			// "MedicDeath: %N died to %N after %d healing. Charged: %d",
			// medic, attacker, healingAmt, wasCharged
		// );
	}
}

public Action:Event_PlayerSplashed(UserMsg:msg_id, Handle:bf, const players[], playersNum, bool:reliable, bool:init)
{
	new client = BfReadByte(bf);
	new victim = BfReadByte(bf);
	new bool:alreadyJarated = false;
	new bool:alreadyMilked = false;
	for (new buffOwner = 0; buffOwner < MaxClients; buffOwner++) {
		if (buffOwner == client) {
			continue;
		}
		if (g_statusBonus[buffOwner][victim][TFCond_Jarated]) {
			alreadyJarated = true;
		}
		if (g_statusBonus[buffOwner][victim][TFCond_Milked]) {
			alreadyMilked = true;
		}
	}
	new bool:jarated = TF2_IsPlayerInCondition(victim, TFCond_Jarated);
	new bool:milked = TF2_IsPlayerInCondition(victim, TFCond_Milked);
	if (!alreadyJarated && jarated) {
		g_statusBonus[client][victim][TFCond_Jarated] = true;
		//LogMessage("PlayerSplashed: %N splashed %N with Jarate", client, victim);
	}
	else if (!alreadyMilked && milked) {
		g_statusBonus[client][victim][TFCond_Milked] = true;
		//LogMessage("PlayerSplashed: %N splashed %N with Mad Milk", client, victim);
	}
}

public DeployBuffBanner(Handle:event, const String:name[], bool:dontBroadcast)
{
	// "buff_type"		"byte"		// type of buff (skin index)
	// "buff_owner"	"short"		// user ID of the person who gets the banner
	new buffType = GetEventInt(event, "buff_type");
	new client = GetClientOfUserId(GetEventInt(event, "buff_owner"));
	if (IsValidClient(client)) {
		g_stats[client][g_currentWave][BUFF_DEPLOYED]++;
		//LogMessage("DeployBuffBanner: %N caused buff type %d", client, buffType);
		g_buffOrder[client] = g_buffCounter++;
		g_buffActive[client] = g_buffTranslations[buffType];
	}
}

public PlayerBuff(Handle:event, const String:name[], bool:dontBroadcast)
{
	// "userid"		"short"   	// user ID of the player the buff is being applied to
	// "buff_owner"	"short"		// user ID of the player with the banner
	// "buff_type"		"byte"		// type of buff
	new target = GetClientOfUserId(GetEventInt(event, "userid"));
	new client = GetClientOfUserId(GetEventInt(event, "buff_owner"));
	//new buffType = GetEventInt(event, "buff_type");
	if (IsValidClient(client) && IsValidClient(target)) {
		//LogMessage("PlayerBuff: %N caused buff type %d to %N", client, buffType, target);
	}
}

// public PlayerSappedObject(Handle:event, const String:name[], bool:dontBroadcast)
// {
	// // "userid"	"short"		// user ID of the spy
	// // "ownerid"	"short"		// user ID of the building owner
	// // "object"	"byte"
	// // "sapperid"	"short"		// index of the sapper
	// new spy = GetEventInt(event, "userid");
	// new buildingOwner = GetEventInt(event, "ownerid");
	// new objectSapped = GetEventInt(event, "object");
	// new sapperID = GetEventInt(event, "sapperid");
	// LogMessage("PlayerSappedObject fired");
	// if (true) {
		// LogMessage(
			// "PlayerSappedObject: %N sapped %N's %d with sapper of ID %d",
			// spy, buildingOwner, objectSapped, sapperID
		// );
	// }
// }

public PlayerStunned(Handle:event, const String:name[], bool:dontBroadcast)
{
	// "stunner"	"short"
	// "victim"	"short"
	// "victim_capping"	"bool"
	// "big_stun"	"bool"
	new stunner = GetClientOfUserId(GetEventInt(event, "stunner"));
	new victim = GetClientOfUserId(GetEventInt(event, "victim"));
	//new bool:victimCapping = GetEventInt(event, "victim_capping");
	//new bool:bigStun = GetEventInt(event, "big_stun");
	if (IsValidClient(stunner)) {
		// LogMessage(
			// "PlayerStunned: %N stunned %N",
			// stunner, victim
		// );
		g_lastStunnedBy[victim] = stunner;
	}
}

public TF2_OnConditionAdded(client, TFCond:condition) {
	//LogMessage("TF2_OnConditionAdded: %N gained condition %d", client, condition);
	//new bool:markedForDeath = false;
	if (condition == TFCond_MarkedForDeath) {
		new buffOwner = g_lastDamagedBy[client];
		g_statusBonus[buffOwner][client][TFCond_MarkedForDeath] /*= markedForDeath*/ = true;
		// LogMessage(
			// "TF2_OnConditionAdded: %d %N marked %d %N for death",
			// buffOwner, buffOwner,
			// client, client
		// );
	}
	else if (
		condition == TFCond_Dazed ||
		condition == TFCond_Sapped
	) {
		new stunner = g_lastStunnedBy[client];
		if (stunner < 0) {
			// LogMessage(
				// "TF2_OnConditionAdded: Error processing %d stunning %d using stunned by check",
				// stunner,
				// client
			// );
			stunner = g_lastDamagedBy[client];
			if (stunner < 0) {
				// LogMessage(
					// "TF2_OnConditionAdded: Error processing %d stunning %d using damage check",
					// stunner,
					// client
				// );
			}
			else {
				g_statusBonus[stunner][client][condition] = true;
			}
		}
		else {
			g_statusBonus[stunner][client][condition] = true;
		}
	}
	//g_lastDamagedBy[client] = -1;

	// XXX: This should be MAX_INT or similar
	new timeStamp = 0x7FFFFFFF;
	new buffOwnerID = 0x7FFFFFFF;
	for (new buffOwner = 0; buffOwner < MaxClients; buffOwner++) {
		if (buffOwner == client) {
			continue;
		}
		// Do we know that this buff came from an ally
		// and who it is from?
		if (
			g_statusBonus[buffOwner][client][0] && !(
			// Ignore 10% resistances if they come between
			// an Uber deployed signal and the condition add signal
			condition == TFCond_SmallBulletResist ||
			condition == TFCond_SmallBlastResist ||
			condition == TFCond_SmallFireResist
		)) {
			g_statusBonus[buffOwner][client][0] = false;
			g_statusBonus[buffOwner][client][condition] = true;
			// LogMessage(
				// "TF2_OnConditionAdded: %N determined to be giving condition %d to %N",
				// buffOwner, condition, client
			// );
		}
		// Can we assume that this conditon came from an ally
		// based on a recent sharing of a canteen?
		if (g_canteenActive[buffOwner][condition]) {
			g_canteenActive[buffOwner][condition] = false;
			g_statusBonus[buffOwner][client][condition] = true;
			// LogMessage(
				// "TF2_OnConditionAdded: %N determined to be giving condition %d to %N",
				// buffOwner, condition, client
			// );
		}
		// Find the oldest buff banner use, if any, that is still active
		// and which is also for this condition
		if (g_buffActive[buffOwner] == condition) {
			if (g_buffOrder[buffOwner] < timeStamp) {
				timeStamp = g_buffOrder[buffOwner];
				buffOwnerID = buffOwner;
			}
		}
	}
	if (buffOwnerID < 0x7FFFFFFF) {
		// buffOwnerID should be the ID of the person
		// who first activated the buff currently being added
		g_statusBonus[buffOwnerID][client][condition] = true;
		// LogMessage(
			// "TF2_OnConditionAdded: %N determined to be giving condition %d to %N",
			// buffOwnerID, condition, client
		// );	
	}
	if (g_canteenActive[client][0]) {
		// This status is probably being added because of activating
		// a canteen which will be shared - note what the
		// condition is
		g_canteenActive[client][0] = false;
		g_canteenActive[client][condition] = true;
	}
}

public TF2_OnConditionRemoved(client, TFCond:condition) {
	//LogMessage("TF2_OnConditionRemoved: %N lost condition %d", client, condition);

	for (new buffOwner = 0; buffOwner < MaxClients; buffOwner++) {
		new bool:oldStatus = g_statusBonus[buffOwner][client][condition];
		if (oldStatus) {
			// LogMessage(
				// "TF2_OnConditionRemoved: %N determined to be no longer giving condition %d to %N",
				// buffOwner, condition, client
			// );
		}
		g_statusBonus[buffOwner][client][condition] = false;
		if (client == buffOwner && g_buffActive[buffOwner] == condition) {
			g_buffActive[buffOwner] = TFCond:0;
		}
	}
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
	new bool:wasCrit = GetEventBool(event, "crit");
	// This argument isn't part of the npc_hurt event
	//new bool:wasMiniCrit = GetEventBool(event, "minicrit");

	/*
	// This was supposed adjust for overkill but it doesn't work
	new hp = GetEntProp(victim, Prop_Data, "m_iHealth");
	if (hp < 0) {
		damage += hp;
	}
	*/

	if (IsValidClient(attacker) && damage > 0) {
		g_stats[attacker][g_currentWave][TANK_DAMAGE] += damage;
		DamageAdjust(attacker, victim, damage, ADJUSTED_TANK_DAMAGE, wasCrit, false);
		//LogMessage("Tank Damage! %i to %i %s from %N, total %i", damage, victim, className, attacker, g_stats[attacker][g_currentWave][TANK_DAMAGE]);
		//g_lastDamagedBy[victim] = attacker;
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

	InitScoreWeights();

	for (new stat = 0; stat < MAXSTATS; stat++) {
		if (g_scoreWeights[stat] > 0) {
			new Float:total = 0.0;
			
			for(new client = 0; client < MaxClients; client++) {
				new Float:currStat = float(g_stats[client][wave][stat]);
				if (IsValidClient(client) && currStat > 0) {
					// LogMessage(
						// "%N wave %d stats %d = %d",
						// client, wave, stat, currStat
					// );
					total += currStat;
				}
			}
			if (total == 0.0) {
				g_scoreWeights[stat] = 0.0;
			}
			g_totals[wave][stat] = total;
		}
	}
	new bool:allZero = true;
	for (new stat = 0; stat < MAXSTATS; stat++) {
		if (g_scoreWeights[stat] > 0) {
			allZero = false;
			break;
		}
	}

	if (allZero) {
		InitScoreWeights();
	}
	else {
		NormalizeWeights(true);
		NormalizeWeights();
	}

	new statCount = 0;
	for (new stat = 0; stat < MAXSTATS; stat++) {
		if (g_scoreWeights[stat] > 0) {
			statCount++;

			//LogMessage(" Updatings scores for stat %i with weight %f, current total %f", stat, g_scoreWeights[stat], g_totals[wave][stat]);
			
			for (new client = 0; client < MaxClients; client++) {
				if (IsValidClient(client) && g_stats[client][wave][stat] > 0) {
					//LogMessage("%N wave %d stat %d", client, wave, stat);
					new Float:score = float(g_stats[client][wave][stat]);
					//LogMessage("g_stats[client][wave][stat] = %f", score);
					score /= g_totals[wave][stat];
					//LogMessage("/= g_totals[wave][stat] = %f", score);
					score *= g_scoreWeights[stat];
					//LogMessage("*= g_scoreWeights[stat] = %f", score);
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
		for (new player = 0; player < MAXPLAYERS+1, player++) {
			g_currentWaveToView[player] = g_currentWave;
		}
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

	g_bombResetBonus[client] = false;
	for (new target = 0; target < MaxClients; target++) {
		for (new cond = 0; cond < TFCondLen + 1; cond++) {
			g_statusBonus[client][target][cond] = false;
		}
	}
	for (new cond = 0; cond < TFCondLen + 1; cond++) {
		g_canteenActive[client][cond] = false;
	}
	// XXX: Should be MAX_INT or similar
	g_buffOrder[client] = 0x7FFFFFFF;
	g_buffActive[client] = TFCond:0;
	g_lastDamagedBy[client] = -1;
	g_lastStunnedBy[client] = -1;
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
	ResetScoreBonuses();
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
	ResetScoreBonuses();
}

ResetBombResetBonuses() {
	for (new client = 0; client < MaxClients; client++) {
		g_bombResetBonus[client] = false;
	}
}

ResetScoreBonuses()
{
	//LogMessage("ResetScoreBonuses"); 
	
	for (new client = 0; client < MaxClients; client++) {
		g_bombResetBonus[client] = false;
		for (new target = 0; target < MaxClients; target++) {
			for (new cond = 0; cond < TFCondLen + 1; cond++) {
				g_statusBonus[client][target][cond] = false;
			}
		}
		for (new cond = 0; cond < TFCondLen + 1; cond++) {
			g_canteenActive[client][cond] = false;
		}
		g_buffOrder[client] = 0;
		g_buffActive[client] = TFCond:0;
		g_lastDamagedBy[client] = -1;
		g_lastStunnedBy[client] = -1;
	}
	g_buffCounter = 0;
}

// STATS SORTING =====================================================

GetWaveStatsSorted(stats[][], waveIndex, statIndex)
{
	new bool:showTotals = waveIndex == g_currentWave + 1;

	new statCount = 0;
	
	for(new client = 0; client < MaxClients; client++) {
		if (IsValidClient(client)) {
			stats[client][0] = client;
			if (showTotals) {
				new statTotal = 0;
				for (new currWave = 0; currWave < g_currentWave + 1; currWave++) {
					statTotal +=  g_stats[client][currWave][statIndex];
				}
				if (statIndex == SCORE && waveIndex > 0) {
					statTotal /= waveIndex;
				}
				stats[client][1] = statTotal;
			}
			else {
				stats[client][1] = g_stats[client][waveIndex][statIndex];
			}
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
	new maxMissionScore = 0;
	new missionWinner = 0;

	// XXX: Should be MAX_INT or similar
	new minScore = 0x7FFFFFFF;
	new waveLoser = 0;
	// XXX: Should be MAX_INT or similar
	new minMissionScore = 0x7FFFFFFF;
	new missionLoser = 0;

	new missionTotals[MAXPLAYERS+1];
	new completedWaves = g_currentWave + 1;

	for (new waveIndex = 0; waveIndex < completedWaves; waveIndex++) {
		for (new client = 0; client < MaxClients; client++) {
			if (IsValidClient(client)) {
				missionTotals[client] += g_stats[client][waveIndex][SCORE];
			}
		}
	}

	for (new client = 0; client < MaxClients; client++) {
		if (IsValidClient(client)) {
			if (g_stats[client][wave][SCORE] > maxScore) {
				maxScore = g_stats[client][wave][SCORE];
				waveWinner = client;
			}
			if (missionTotals[client] > maxMissionScore) {
				maxMissionScore = missionTotals[client];
				missionWinner = client;
			}
			if (g_stats[client][wave][SCORE] < minScore) {
				minScore = g_stats[client][wave][SCORE];
				waveLoser = client;
			}
			if (missionTotals[client] < minMissionScore) {
				minMissionScore = missionTotals[client];
				missionLoser = client;
			}
		}
	}

	new bool:loser = waveWinner != waveLoser;
	new bool:totalLoser = missionWinner != missionLoser;

	LogMessage("Mission MVP: %N, who did %i%% of the work!", missionWinner, maxMissionScore/completedWaves);
	LogMessage("Wave MVP: %N, who did %i%% of the work!", waveWinner, maxScore);
	if (!loser) {
		//PrintCenterTextAll("Wave MVP: %N, who did %i%% of the work!", waveWinner, maxScore);
	}
	else {
		// PrintCenterTextAll(
			// "Wave MVP: %N, who did %i%% of the work!\nWave Loser: %N, who only did %i%% of the work!",
			// waveWinner, maxScore,
			// waveLoser, minScore
		// );
	}
	if (loser) {
		LogMessage("Wave Loser: %N, who only did %i%% of the work!", waveLoser, minScore);
		LogMessage("Mission Loser: %N, who only did %i%% of the work!", missionLoser, minMissionScore/completedWaves);
	}

	new Handle:hudHandle = CreateHudSynchronizer();
	SetHudTextParams(-1.0, 0.42, 15.0, 255, 255, 255, 255);

	for(new client = 0; client < MaxClients; client++) {
		if (IsValidClient(client)) {
			if (!loser && !totalLoser) {
				ShowSyncHudText(
					client, hudHandle,
					"Mission MVP: %N - %i%%\nWave MVP: %N - %i%%",
					missionWinner, maxMissionScore/completedWaves,
					waveWinner, maxScore
				);
			}
			else if (!loser && IsValidClient(missionLoser)) {
				ShowSyncHudText(
					client, hudHandle,
					"Mission MVP: %N - %i%%\nWave MVP: %N - %i%%\nMission Loser: %N - %i%%",
					missionWinner, maxMissionScore/completedWaves,
					waveWinner, maxScore,
					missionLoser, minMissionScore/completedWaves
				);
			}
			else if (!totalLoser && IsValidClient(waveLoser)) {
				ShowSyncHudText(
					client, hudHandle,
					"Mission MVP: %N - %i%%\nWave MVP: %N - %i%%\nWave Loser: %N - %i%%",
					missionWinner, maxMissionScore/completedWaves,
					waveWinner, maxScore,
					waveLoser, minScore
				);
			}
			else if (IsValidClient(waveLoser) && IsValidClient(missionLoser)) {
				ShowSyncHudText(
					client, hudHandle,
					"Mission MVP: %N - %i%%\nWave MVP: %N - %i%%\nWave Loser: %N - %i%%\nMission Loser: %N - %i%%",
					missionWinner, maxMissionScore/completedWaves,
					waveWinner, maxScore,
					waveLoser, minScore,
					missionLoser, minMissionScore/completedWaves
				);
			}
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
	LogMessage("Tank MVP: %N with %i%% damage!", tankWinner, percent);
	//PrintCenterTextAll("Tank MVP: %N with %i%% damage!", tankWinner, percent);
	
	new Handle:hudHandle = CreateHudSynchronizer();
	SetHudTextParams(-1.0, 0.5, 5.0, 255, 255, 255, 255);

	for (new client = 0; client < MaxClients; client++) {
		if (IsValidClient(client)) {
			ShowSyncHudText(client, hudHandle, "Tank MVP: %N with %i%% damage!", tankWinner, percent);
		}
	}
	
	CloseHandle(hudHandle);
}

// PANEL HANDLING =====================================================

public Action:StatsCommand(client, args)
{
	//LogMessage("StatsCommand: %N", client);
	
	// if(!client) {
		// PrintToServer("[MvM Stats] %t", "Command is in-game only");
		// return Plugin_Handled;
	// }
	
	if (g_currentWave < 0) {
		PrintToChat(client, "[MvM Stats] No waves complete");
		return Plugin_Handled;
	}
	
	UpdateWaveScores(g_currentWaveToView[client]);
	
	ShowWaveStatsClient(client, g_currentWaveToView[client]);
	
	return Plugin_Handled;
}

ShowWaveStatsAll(wave)
{
	for(new client = 0; client < MaxClients; client++) {
		if (IsValidClient(client)) {
			ShowWaveStatsClient(client, wave);
			PrintToChat(client, "Type !mvmstats anytime to display stats menu");
		}
	}
}

ShowWaveStatsClient(client, wave)
{
	ShowPanel(client, wave, 0);
}

ShowPanel(client, wave, panelIndex)
{
	new bool:showTotals = wave == g_currentWave + 1;

	new stat = g_panelOrder[panelIndex];
	g_lastPanel[client] = panelIndex;

	new stats[MaxClients+1][2];
	
	new Handle:panel = CreatePanel();
	
	new String:title[128];
	if (showTotals) {
		Format(title, sizeof(title), "[Wave Totals] %s", g_panelTitles[panelIndex]);
	}
	else {
		Format(title, sizeof(title), "[Wave %i] %s", (wave+1), g_panelTitles[panelIndex]);
	}
	SetPanelTitle(panel, title);
		
	DrawPanelText(panel, " ");

	new statCount = GetWaveStatsSorted(stats, wave, stat);
	DrawWaveStat(panel, stats, statCount, stat == SCORE);
	
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

	DrawPanelItem(panel, "Previous Wave");
	DrawPanelItem(panel, "Current Wave");
	DrawPanelItem(panel, "Next Wave");

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
			ShowPanel(client, g_currentWaveToView[client], prevPanel);
		} else if (key == 2) {
			new nextPanel = g_lastPanel[client]+1;
			if (nextPanel > sizeof(g_panelOrder)-1) {
				nextPanel = 0;
			}

			//LogMessage("PanelHandler Next>: %N", client);
			EmitSoundToClient(client, g_panelButton);
			ShowPanel(client, g_currentWaveToView[client], nextPanel);
		} else if (key == 3 || key == 5) {
			new bool:prev = key == 3;
			new change = 1;
			if (prev) {
				change = -1;
			}
			g_currentWaveToView[client] += change;
			if (g_currentWaveToView[client] < 0) {
				g_currentWaveToView[client] = 0;
			}
			else if (g_currentWaveToView[client] > g_currentWave + 1) {
				g_currentWaveToView[client] = g_currentWave + 1;
			}
			
			//LogMessage("PanelHandler Change Wave: %N", client);
			EmitSoundToClient(client, g_panelButton);
			ShowPanel(client, g_currentWaveToView[client], g_lastPanel[client]);
		} else if (key == 4) {
			g_currentWaveToView[client] = g_currentWave;

			//LogMessage("PanelHandler Current Wave: %N", client);
			EmitSoundToClient(client, g_panelButton);
			ShowPanel(client, g_currentWaveToView[client], g_lastPanel[client]);
		} else {
			//LogMessage("PanelHandler Exit: %N", client);
			EmitSoundToClient(client, g_panelExit);
		}
	}
}

DrawWaveStat(Handle:panel, stats[][], statCount, bool:score = false)
{
	decl String:line[128];
	decl String:playerScore[12];
	decl String:playerClass[32];
	decl String:widthString[16];
	decl String:lineFormat[32];
	decl String:lineFormatPercentage[32];

	strcopy(lineFormat, sizeof(lineFormat), "%-{width}i   %s   %N");
	strcopy(lineFormatPercentage, sizeof(lineFormatPercentage), "%-{width}i%%  %s   %N");

	new maxLen = 0;
	for(new i = 0; i < statCount; i++) {
		IntToString(stats[i][1], playerScore, sizeof(playerScore));
		new scoreLen = strlen(playerScore);
		if (scoreLen > maxLen)
			maxLen = scoreLen;
	}

	IntToString(maxLen + (score? 0 : 3), widthString, sizeof(widthString));
	ReplaceString(lineFormat, sizeof(lineFormat), "{width}", widthString);
	ReplaceString(lineFormatPercentage, sizeof(lineFormatPercentage), "{width}", widthString);
	
	for(new i = 0; i < statCount; i++) {
		GetClientClassName(stats[i][0], playerClass, sizeof(playerClass));
		if (score) {
			Format(line, sizeof(line), lineFormatPercentage, stats[i][1],  playerClass, stats[i][0]);
		}
		else {
			Format(line, sizeof(line), lineFormat, stats[i][1],  playerClass, stats[i][0]);
		}
		DrawPanelText(panel, line);
	}
}

public GetClientClassName(client, String:className[], classNameSize)
{
	new TFClassType:class = TF2_GetPlayerClass(client);
	
	if (class == TFClass_Scout)
		strcopy(className, classNameSize, "Scout       ");
	else if (class == TFClass_Sniper)
		strcopy(className, classNameSize, "Sniper      ");
	else if (class == TFClass_Soldier)
		strcopy(className, classNameSize, "Soldier     ");
	else if (class == TFClass_DemoMan)
		strcopy(className, classNameSize, "Demoman     ");
	else if (class == TFClass_Medic)
		strcopy(className, classNameSize, "Medic       ");
	else if (class == TFClass_Heavy)
		strcopy(className, classNameSize, "Heavy       ");
	else if (class == TFClass_Pyro)
		strcopy(className, classNameSize, "Pyro        ");
	else if (class == TFClass_Spy)
		strcopy(className, classNameSize, "Spy         ");
	else if (class == TFClass_Engineer)
		strcopy(className, classNameSize, "Engineer    ");
	else
		strcopy(className, classNameSize, "            ");
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

