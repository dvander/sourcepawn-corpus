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
#include <tf2>

#pragma semicolon 1

#define PLUGIN_VERSION "1.2h"

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

new bool:g_bombResetBonus[MAXPLAYERS+1];

#define TFCondLen _:TFCond

// NOTE: First flag is used to signal that a buff has been given
// The flag should be cleared when another flag is set to indicate which buff it is
// The flags for all players giving a buff to a player should be cleared for that
// buff when the buff wears off of the target
new bool:g_statusBonus[MAXPLAYERS+1][MAXPLAYERS+1][TFCondLen+1];
// Similar to the above; used for detecting which power is being shared
// via canteen sharing
new bool:g_canteenActive[MAXPLAYERS+1][TFCondLen+1];

// For buffs; shouldn't be necessary but the player_buff event is being strange(?)
new const g_buffTranslations[] = {
	0,
	TFCond_Buffed,
	TFCond_DefenseBuffed,
	TFCond_RegenBuffed
};
new g_buffCounter = 0;
new g_buffOrder[MAXPLAYERS+1];
new g_buffActive[MAXPLAYERS+1];

new g_currentWave = 0;
new g_currentWaveToView = 0;

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
		g_currentWaveToView = g_currentWave = currentWave;
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
	g_panelTitles[index++]  = "MvM SCORE";
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

	// The added weights are for events that don't fire reliably (?)

	new Float:statTotal = 0.0;
	// Base scoring is done by adjusted damage
	g_scoreWeights[ADJUSTED_BOT_DAMAGE] = 1.0; statTotal += 1.0;
	// Tanks require serious attention
	g_scoreWeights[ADJUSTED_TANK_DAMAGE] = 1.5 * g_scoreWeights[ADJUSTED_BOT_DAMAGE]; statTotal += 1.0;
	// Damaging giants is more important than damaging small bots
	g_scoreWeights[ADJUSTED_GIANT_DAMAGE] = 1.5 * g_scoreWeights[ADJUSTED_BOT_DAMAGE]; statTotal += 1.0;
	// Picking up cash is 70% as important as dealing damage because only about 70%
	// of the cash is needed to win (usually, and this is from PE so it may need adjusting)
	// Additionally, picking up cash is about 60% of the job of the person assigned the task,
	// so another 40% penalty in score value is incurred
	// Finally, cash is only able to be picked up if it is made to appear to begin with,
	// so another 30% penalty is incurred
	g_scoreWeights[CASH_PICKUP] = 0.7 * 0.6 * 0.7 * (
		g_scoreWeights[ADJUSTED_BOT_DAMAGE] +
		g_scoreWeights[ADJUSTED_TANK_DAMAGE] +
		g_scoreWeights[ADJUSTED_GIANT_DAMAGE]
	); statTotal += 1.0;
	// Killing uber medics is about 60% of the job of someone who is assigned the task,
	// so it is ranked as 60% as important as dealing damage
	g_scoreWeights[UBER_MEDIC_KILL] = 0.6 * (
		g_scoreWeights[ADJUSTED_BOT_DAMAGE] +
		g_scoreWeights[ADJUSTED_TANK_DAMAGE] +
		g_scoreWeights[ADJUSTED_GIANT_DAMAGE]
	); statTotal += 1.0;
	new Float:weightTotal = 0.0;
	for (new index = 0; index < MAXSTATS+1; index++) {
		weightTotal += g_scoreWeights[index];
	}
	// Bomb defenses buy the group a few precious seconds and total
	// 10% of the score (arbitrary guess at their worth; may need adjusting)
	g_scoreWeights[BOMB_DEFENDED] = 0.1 * weightTotal; statTotal += 1.0;
	weightTotal = 0.0;
	for (new index = 0; index < MAXSTATS+1; index++) {
		weightTotal += g_scoreWeights[index];
	}
	//LogMessage("Stat total: %f", statTotal);
	//LogMessage("Weight total: %f", weightTotal);
	new Float:normalFact = statTotal/weightTotal;
	//LogMessage("Normalization factor: %f", normalFact);
	for (new index = 0; index < MAXSTATS+1; index++) {
		g_scoreWeights[index] *= normalFact;
		// LogMessage(
			// "New weight: %f, %2.0f%",
			// g_scoreWeights[index],
			// (g_scoreWeights[index]/statTotal) * 100.0
		// );
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
	// These 2 don't work
	//HookEvent("player_jarated", PlayerJarated);
	//HookEvent("player_jarated_fade", PlayerJaratedFade);

	// TODO:
	// Scout death mark; treat as Jarate but with lower priority (and greater than Buff Banner)
	// This event doesn't work
	//HookEvent("mvm_scout_marked_for_death", ScoutDeathMark);

	// Engineer dispenser health and ammo bonuses
	// Medic heal bonus for low HP players
	// Vaccinator heal bonus
	// Vaccinator uber bonus
	// Give 35% of damage dealt to sapped targets to the sapper
		// Preferably 100% if it's a small bot
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
	g_currentWaveToView = g_currentWave = waveIndex;
	
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
	if (adjustedDamageIndex == ADJUSTED_TANK_DAMAGE) {
		new tankIndex = GetTankIndex(victim);
		if (tankIndex >= 0) {
			g_tanks[tankIndex][attacker] += damage;
			//LogMessage("Tank Damage! %i to %i/%i %s from %N, total %i", adjustedDamage, victim, tankIndex, className, attacker, g_tanks[tankIndex][attacker]);
		}
	}
}

DamageAdjust(attacker, victim, damage, adjustedDamageIndex, bool:wasCrit, bool:wasMiniCrit) {
	new Float:adjustedDamage = float(damage);
	new bool:crits = false;
	new bool:miniCrits = false;
	new bool:uber = false;
	for (new buffOwner = 0; buffOwner < MaxClients && !crits; buffOwner++) {
		if (buffOwner == attacker) {
			continue;
		}
		new Float:buffDamage = 0.0;
		// If Kritz'd
		if (g_statusBonus[buffOwner][attacker][TFCond_Kritzkrieged]) {
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
	for (new buffOwner = 0; buffOwner < MaxClients && !crits; buffOwner++) {
		if (buffOwner == attacker) {
			continue;
		}
		new Float:buffDamage = 0.0;
		// If Crit canteen'd
		if (g_statusBonus[buffOwner][attacker][TFCond_CritCanteen]) {
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
	// Check if the player is giving crits to themselves to avoid
	// giving a buff bonus to someone who is buffing a self-buffed
	// player with crits
	if (
		TF2_IsPlayerInCondition(attacker, TFCond_CritCanteen) ||
		TF2_IsPlayerInCondition(attacker, TFCond_Kritzkrieged) ||
		wasCrit
	) { crits = true; }
	for (new buffOwner = 0; buffOwner < MaxClients && !crits && !miniCrits; buffOwner++) {
		if (buffOwner == attacker) {
			continue;
		}
		new Float:buffDamage = 0.0;
		// If target is Jarate'd
		if (
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
	for (new buffOwner = 0; buffOwner < MaxClients && !crits && !miniCrits; buffOwner++) {
		if (buffOwner == attacker) {
			continue;
		}
		new Float:buffDamage = 0.0;
		// If Buff Banner'd
		if (g_statusBonus[buffOwner][attacker][TFCond_Buffed]) {
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
	for (new buffOwner = 0; buffOwner < MaxClients && !uber; buffOwner++) {
		if (buffOwner == attacker) {
			continue;
		}
		new Float:buffDamage = 0.0;
		// If Uber'd
		if (g_statusBonus[buffOwner][attacker][TFCond_Ubercharged]) {
			uber = true;
			buffDamage = (adjustedDamage * 2)/3;
			//adjustedDamage -= buffDamage;
			g_stats[buffOwner][g_currentWave][adjustedDamageIndex] +=
				RoundFloat(buffDamage);
			AddAdjustedTankDamage(
				buffOwner, victim,
				RoundFloat(buffDamage), adjustedDamageIndex
			);
			break;
		}
	}
	for (new buffOwner = 0; buffOwner < MaxClients && !uber; buffOwner++) {
		if (buffOwner == attacker) {
			continue;
		}
		new Float:buffDamage = 0.0;
		// If Uber canteen'd
		if (g_statusBonus[buffOwner][attacker][TFCond_UberchargedCanteen]) {
			uber = true;
			buffDamage = (adjustedDamage * 2)/3;
			//adjustedDamage -= buffDamage;
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
	for (new buffOwner = 0; buffOwner < MaxClients && !uber; buffOwner++) {
		if (buffOwner == attacker) {
			continue;
		}
		new Float:buffDamage = 0.0;
		// If target is Mad Milk'd
		if (
			adjustedDamageIndex != ADJUSTED_TANK_DAMAGE &&
			g_statusBonus[buffOwner][victim][TFCond_Milked]
		) {
			// LogMessage(
				// "Damage to milked target by %N against %N thanks to %N",
				// attacker, victim, buffOwner
			// );
			buffDamage = (adjustedDamage * 60)/160;
			//adjustedDamage -= buffDamage;
			g_stats[buffOwner][g_currentWave][adjustedDamageIndex] +=
				RoundFloat(buffDamage);
			// AddAdjustedTankDamage(
				// buffOwner, victim,
				// RoundFloat(buffDamage), adjustedDamageIndex
			// );
			break;
		}
	}
	for (new buffOwner = 0; buffOwner < MaxClients && !uber; buffOwner++) {
		if (buffOwner == attacker) {
			continue;
		}
		new Float:buffDamage = 0.0;
		// If Defense buff'd
		if (g_statusBonus[buffOwner][attacker][TFCond_DefenseBuffed]) {
			uber = true;
			buffDamage = (adjustedDamage * 35)/135;
			//adjustedDamage -= buffDamage;
			g_stats[buffOwner][g_currentWave][adjustedDamageIndex] +=
				RoundFloat(buffDamage);
			AddAdjustedTankDamage(
				buffOwner, victim,
				RoundFloat(buffDamage), adjustedDamageIndex
			);
			break;
		}
	}
	for (new buffOwner = 0; buffOwner < MaxClients && !uber; buffOwner++) {
		if (buffOwner == attacker) {
			continue;
		}
		new Float:buffDamage = 0.0;
		// If Regen buff'd
		if (g_statusBonus[buffOwner][attacker][TFCond_RegenBuffed]) {
			uber = true;
			buffDamage = (adjustedDamage * 35)/135;
			//adjustedDamage -= buffDamage;
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
			//LogMessage("Giant Damage! %i to %i %s from %N, total %i", damage, victim, botName, attacker, g_stats[attacker][g_currentWave][GIANT_DAMAGE]);			
		}
		else {
			
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
	ResetScoreBonuses();
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
	ResetScoreBonuses();
}

public MedicPowerShared(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetEventInt(event, "player");
	if (IsValidClient(client)) {
		LogMessage("MedicPowerShared: %N", client);
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
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new healingAmt = GetEventInt(event, "healing");
	new bool:wasCharged = GetEventBool(event, "charged");
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
		if (g_statusBonus[buffOwner][victim][TFCond_Jarated] == true) {
			alreadyJarated = true;
		}
		if (g_statusBonus[buffOwner][victim][TFCond_Milked] == true) {
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
	new buffType = GetEventInt(event, "buff_type");
	if (IsValidClient(client) && IsValidClient(target)) {
		//LogMessage("PlayerBuff: %N caused buff type %d to %N", client, buffType, target);
	}
}

public TF2_OnConditionAdded(client, TFCond:condition) {
	//LogMessage("TF2_OnConditionAdded: %N gained condition %d", client, condition);

	// XXX: This should be MAX_INT or similar
	new timeStamp = 0x7FFFFFFF;
	new buffOwnerID = 0x7FFFFFFF;
	for (new buffOwner = 0; buffOwner < MaxClients; buffOwner++) {
		if (buffOwner == client) {
			continue;
		}
		// Do we know that this buff came from an ally
		// and who it is?
		if (g_statusBonus[buffOwner][client][0]) {
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
			g_buffActive[buffOwner] = 0;
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
		g_currentWaveToView = g_currentWave = currentWave;
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
		g_buffActive[client] = 0;
	}
	g_buffCounter = 0;
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

	for (new client = 0; client < MaxClients; client++) {
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
	
	UpdateWaveScores(g_currentWaveToView);
	
	ShowWaveStatsClient(client, g_currentWaveToView);
	
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
			ShowPanel(client, g_currentWaveToView, prevPanel);
		} else if (key == 2) {
			new nextPanel = g_lastPanel[client]+1;
			if (nextPanel > sizeof(g_panelOrder)-1) {
				nextPanel = 0;
			}

			//LogMessage("PanelHandler Next>: %N", client);
			EmitSoundToClient(client, g_panelButton);
			ShowPanel(client, g_currentWaveToView, nextPanel);
		} else if (key == 3 || key == 5) {
			new bool:prev = key == 3;
			new change = 1;
			if (prev) {
				change = -1;
			}
			g_currentWaveToView += change;
			if (g_currentWaveToView < 0) {
				g_currentWaveToView = 0;
			}
			else if (g_currentWaveToView > g_currentWave) {
				g_currentWaveToView = g_currentWave;
			}
			
			//LogMessage("PanelHandler Change Wave: %N", client);
			EmitSoundToClient(client, g_panelButton);
			ShowPanel(client, g_currentWaveToView, g_lastPanel[client]);
		} else if (key == 4) {
			g_currentWaveToView = g_currentWave;

			//LogMessage("PanelHandler Current Wave: %N", client);
			EmitSoundToClient(client, g_panelButton);
			ShowPanel(client, g_currentWaveToView, g_lastPanel[client]);
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

