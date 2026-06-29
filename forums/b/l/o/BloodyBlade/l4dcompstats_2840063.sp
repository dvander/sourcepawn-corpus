/**
 * =============================================================================
 * L4D Competitive Stats
 * Track and display various round-based survivor and infected statistics.
 * 
 * - Griffin and Philogl
 * =============================================================================
 */

public Plugin myinfo =
{
	name = "L4D Competitive Stats",
	author = "Griffin & Philogl",
	description = "Basic competitive stat tracking on a per map basis",
	version = "0.4.2"
};

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdkhooks>

#define MAXENTITIES 2048
#define SAYTEXT_MAXLENGTH 192
#define HIGHCHAR "*"
#define LOWCHAR "_"
#define TEAM_SPECTATOR 1
#define TEAM_SURVIVOR 2
#define TEAM_INFECTED 3
#define FLAG_SPECTATOR (1 << TEAM_SPECTATOR)
#define FLAG_SURVIVOR (1 << TEAM_SURVIVOR)
#define FLAG_INFECTED (1 << TEAM_INFECTED)
#define SM_REPLY_TO_CHAT ReplySource:1
#define MIN_DP_RATIO 0.8 // % of maximum DP damage to consider a DP, maybe make this a cvar?
#define BOOMER_STAGGER_TIME 4.0 // Amount of time after a boomer has been meleed that we consider the meleer the person who
								// shut down the boomer, this is just a guess value...

#define GetModifierChar(%0,%1) (%0 == lows_highs[%1][1] ? HIGHCHAR:%0 == lows_highs[%1][0] ? LOWCHAR:"")
#define GetModifierCharReversed(%0,%1) (%0 == lows_highs[%1][0] ? HIGHCHAR:%0 == lows_highs[%1][1] ? LOWCHAR:"")
#define IsSpectator(%0) (GetClientTeam(%0) == TEAM_SPECTATOR)
#define IsSurvivor(%0) (GetClientTeam(%0) == TEAM_SURVIVOR)
#define IsInfected(%0) (GetClientTeam(%0) == TEAM_INFECTED)
#define IsWitch(%0) (g_bIsWitch[%0])
#define IsPouncing(%0) (g_bIsPouncing[%0])
#define IsIncapped(%0) (GetEntProp(%0, Prop_Send, "m_isIncapacitated") > 0)
#define IsBoomed(%0) ((GetEntPropFloat(%0, Prop_Send, "m_vomitStart") + 20.1) > GetGameTime())

enum ZOMBIECLASS
{
	ZC_SMOKER = 1,
	ZC_BOOMER,
	ZC_HUNTER,
	ZC_WITCH,
	ZC_TANK
}

enum STATS
{
	FullSkeets,
	TeamSkeets,
	SkeetAssists,
	Deadstops,
	PouncesEaten,
	DPsEaten,
	CIKills,
	SIKills,
	FF,
	SIDamage,
	CIDamageTaken,
	SIDamageTaken,
	BoomerShutdowns,
	BoomAttempts,
	BoomSuccesses,
	BoomedSurvivorsByVomit,
	BoomedSurvivorsByProxy,
	PouncesLanded,
	DPsLanded,
	Skeeted,
	Deadstopped,
	DamageDealtAsSI,
	STATS_MAX
}

// Cvar related
//int		g_iMaxPlayerZombies				= 4;
int		g_iSurvivorLimit				= 4;
int		g_iMinDPDamage					= 20;
int		g_iWitchHealth					= 1000;	// Default
//ConVar	g_hCvarMaxPlayerZombies;
ConVar	g_hCvarSurvivorLimit;
ConVar	g_hCvarMaxPounceBonusDamage;
ConVar	g_hCvarWitchHealth;
ConVar	g_hCvarDirectorReadyDuration;

// Global state
bool	g_bShouldAnnounceWitchDamage = false;
bool	g_bHasRoundEnded			 = false;
bool	g_bLogFF					 = false;
Handle	g_hBoomerShoveTimer			 = null;

// Player/Entity state
int		g_iAccumulatedWitchDamage = 0;							// Current witch health = witch health - accumulated
int		g_iBoomerClient = 0;									// Client of last player to be boomer (or current boomer)
int		g_iBoomerKiller = 0;									// Client who shot the boomer
int		g_iBoomerShover = 0;									// Client who shoved the boomer
int		g_iLastHealth[MAXPLAYERS + 1] = {0, ...};
bool	g_bHasBoomLanded = false;
//bool	g_bStatsCooldown[MAXPLAYERS + 1] = {false, ...};					// Prevent spam of stats command (potential DoS vector I think)
bool	g_bHasLandedPounce[MAXPLAYERS + 1] = {false, ...};					// Used to determine if a deadstop was 'pierced'
bool	g_bIsWitch[MAXENTITIES];							// Membership testing for fast witch checking
bool	g_bIsPouncing[MAXPLAYERS + 1] = {false, ...};
bool	g_bShotCounted[MAXPLAYERS + 1][MAXPLAYERS +1];		// Victim - Attacker, used by playerhurt and weaponfired

// Map Stats, array for each player for easy trie storage
int		g_iMapStats[MAXPLAYERS + 1][STATS_MAX];

// Player temp stats
int		g_iWitchDamage[MAXPLAYERS + 1] = {0, ...};
int		g_iDamageDealt[MAXPLAYERS + 1][MAXPLAYERS + 1];			// Victim - Attacker
int		g_iShotsDealt[MAXPLAYERS + 1][MAXPLAYERS + 1];			// Victim - Attacker, count # of shots (not pellets)

public void OnPluginStart()
{
	if (GetMaxEntities() > MAXENTITIES)
	{
		LogError("Plugin needs to be recompiled with a new MAXENTITIES value of %d. Current value is %d. Witch tracking is unreliable!", GetMaxEntities(), MAXENTITIES);
	}

	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client)) continue;
		SDKHook(client, SDKHook_OnTakeDamage, PlayerHook_OnTakeDamagePre);
	}

	HookEvent("round_start", Event_RoundStart);
	HookEvent("round_end", Event_RoundEnd);

	HookEvent("player_hurt", Event_PlayerHurt);
	HookEvent("player_shoved", Event_PlayerShoved);
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("infected_death", Event_InfectedDeath);
	HookEvent("weapon_fire", Event_WeaponFire);
	// Witch tracking
	HookEvent("player_incapacitated", Event_PlayerIncapacitated);
	HookEvent("infected_hurt", Event_InfectedHurt);
	HookEvent("witch_killed", Event_WitchKilled);
	HookEvent("witch_spawn", Event_WitchSpawn);
	// Pounce tracking
	HookEvent("ability_use", Event_AbilityUse);
	HookEvent("lunge_pounce", Event_LungePounce);
	// Boomer tracking
	HookEvent("player_now_it", Event_PlayerBoomed);

//	g_hCvarMaxPlayerZombies = FindConVar("z_max_player_zombies");
	g_hCvarSurvivorLimit = FindConVar("survivor_limit");
	g_hCvarMaxPounceBonusDamage = FindConVar("z_hunter_max_pounce_bonus_damage");
	g_hCvarWitchHealth = FindConVar("z_witch_health");
	g_hCvarDirectorReadyDuration = FindConVar("director_ready_duration");

//	g_hCvarMaxPlayerZombies.AddChangeHook(Cvar_MaxPlayerZombies);
	g_hCvarSurvivorLimit.AddChangeHook(Cvar_SurvivorLimit);
	g_hCvarMaxPounceBonusDamage.AddChangeHook(Cvar_MaxPounceBonusDamage);
	g_hCvarWitchHealth.AddChangeHook(Cvar_WitchHealth);
	g_hCvarDirectorReadyDuration.AddChangeHook(Cvar_DirectorReadyDuration);

//	g_iMaxPlayerZombies = g_hCvarMaxPlayerZombies.IntValue;
	g_iSurvivorLimit = g_hCvarSurvivorLimit.IntValue;
	g_iWitchHealth = g_hCvarWitchHealth.IntValue;
	if (g_hCvarDirectorReadyDuration.IntValue > 0) g_bLogFF = true;
	CalculateMinDPDamage(GetConVarFloat(g_hCvarMaxPounceBonusDamage));

	// RegConsoleCmd("sm_stats", Command_Stats, "Prints the client's stats for the current round");
}

public void OnClientPutInServer(int client)
{
	if(client > 0)
	{
		SDKHook(client, SDKHook_OnTakeDamage, PlayerHook_OnTakeDamagePre);
	}
}

public void OnMapStart()
{
	g_bHasRoundEnded = false;
	ClearMapStats();
}

Action Timer_DelayedStatsPrint(Handle timer)
{
	PrintMVPAndTeamStats();
	PrintConsoleStats();
	return Plugin_Stop;
}

/*
MVP - SI: Philogl (2932 dmg[99%], 53 kills [100%]) Your SI rank: #4 (3 dmg [1%], 0 kills [0%])
MVP - CI: Philogl (232 common [90%]) Your CI rank: #4 (1 kills [0%])
*/

void PrintMVPAndTeamStats()
{
	int[] survivor_clients = new int[g_iSurvivorLimit];
	int i = 0;
	int survivor_count = 0;
	for (i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || !IsSurvivor(i)) continue;
		survivor_clients[survivor_count++] = i;
	}

	int[][] sortable = new int[survivor_count][2];
	int client = 0, val = 0;
	int total = 0, totalkills = 0, percent = 0;

	// --------------------------- SI Damage ---------------------------
	for (i = 0; i < survivor_count; i++)
	{
		client = survivor_clients[i];
		val = g_iMapStats[client][SIDamage];
		sortable[i][0] = client;
		sortable[i][1] = val;
		total += val;
		totalkills += g_iMapStats[client][SIKills];
	}
	if (total == 0 || totalkills == 0)
	{
		PrintToChatAll("\x01MVP - SI: \x03N/A\x01");
	}
	else
	{
		SortCustom2D(sortable, survivor_count, ClientValue2DSortDesc);
		client = sortable[0][0];
		val = sortable[0][1];
		percent = RoundFloat((float(val) / float(total)) * 100.0);
		int kills = g_iMapStats[client][SIKills];
		// This string (colors, etc) is stolen wholesale from Tabun's L4D2 MVP plugin, credit to him
		PrintToChatAll("\x01MVP - SI: \x03%N\x01 (\x05%d\x01 dmg [\x04%d%%\x01], \x05%d\x01 kills [\x04%d%%\x01])",
			client, val, percent, kills,
			RoundFloat((float(kills) / float(totalkills)) * 100.0));

		// Print individual reports for each survivor that isn't the MVP
		for (i = 1; i < survivor_count; i++)
		{
			client = sortable[i][0];
			val = sortable[i][1];
			kills = g_iMapStats[client][SIKills];
			percent = RoundFloat((float(val) / float(total)) * 100.0);
			PrintToChat(client, "\x01You - SI: \x05#%d\x01 (\x05%d\x01 dmg [\x04%d%%\x01], \x05%d\x01 kills [\x04%d%%\x01]", i + 1, val, percent, kills,
				RoundFloat((float(kills) / float(totalkills)) * 100.0));
		}
	}

	// --------------------------- CI Kills ---------------------------
	total = 0;
	for (i = 0; i < survivor_count; i++)
	{
		client = survivor_clients[i];
		val = g_iMapStats[client][CIKills];
		sortable[i][0] = client;
		sortable[i][1] = val;
		total += val;
	}
	if (total == 0)
	{
		PrintToChatAll("\x01MVP - CI: \x03N/A\x01");
	}
	else
	{
		SortCustom2D(sortable, survivor_count, ClientValue2DSortDesc);
		client = sortable[0][0];
		val = sortable[0][1];
		percent = RoundFloat((float(val) / float(total)) * 100.0);
		// Again, credit to Tabun
		PrintToChatAll("\x01MVP - CI: \x03%N\x01 (\x05%d\x01 common [\x04%d%%\x01])",
			client, val, percent);

		for (i = 1; i < survivor_count; i++)
		{
			client = sortable[i][0];
			val = sortable[i][1];
			percent = RoundFloat((float(val) / float(total)) * 100.0);
			PrintToChat(client, "\x01You - CI: \x05#%d\x01 (\x05%d\x01 common [\x04%d%%\x01])",
				i + 1, val, percent);
		}
	}

	// --------------------------- Team Stats ---------------------------
	int skeets = 0, /*fullskeets = 0, teamskeets = 0, */deadstops = 0, pounce_eats = 0, dp_eats = 0;
	int successful_booms = 0, shutdown_booms = 0, vomited_survivors = 0, proxied_survivors = 0;
	int dmg_from_si = 0, dmg_from_ci = 0, dmg_from_ff = 0;

	for (i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i)) continue;
		if (IsSurvivor(i))
		{
//			fullskeets += g_iMapStats[i][FullSkeets];
//			teamskeets += g_iMapStats[i][TeamSkeets];
			skeets += g_iMapStats[i][FullSkeets] + g_iMapStats[i][TeamSkeets];
			deadstops += g_iMapStats[i][Deadstops];
			pounce_eats += g_iMapStats[i][PouncesEaten];
			dp_eats += g_iMapStats[i][DPsEaten];
			shutdown_booms += g_iMapStats[i][BoomerShutdowns];
			dmg_from_si += g_iMapStats[i][SIDamageTaken];
			dmg_from_ci += g_iMapStats[i][CIDamageTaken];
			dmg_from_ff += g_iMapStats[i][FF];
		}
		else if (IsInfected(i))
		{
			successful_booms += g_iMapStats[i][BoomSuccesses];
			vomited_survivors += g_iMapStats[i][BoomedSurvivorsByVomit];
			proxied_survivors += g_iMapStats[i][BoomedSurvivorsByProxy];
		}
	}

/*
TEAM - Hunters: 40% (4/10) shutdown (3 skeets, 1 DS, 2 DPs landed)
TEAM - Boomers: 20% (1/5) shutdown (4 vomited, 3 proxied)
TEAM - Damage: 173 from SI, 97 from common, 23 from FF
*/

	if ((skeets + deadstops + pounce_eats) == 0)
	{
		PrintToChatAll("\x01TEAM - Hunters: \x03N/A\x01");
	}
	else
	{
		PrintToChatAll("\x01TEAM - Hunters: \x04%d%%\x01 (\x05%d\x01/\x05%d\x01) shutdown (\x05%d\x01 skeet%s, \x05%d\x01 DS, \x05%d\x01 DP%s landed)",
			RoundFloat((float(skeets + deadstops) / float(skeets + deadstops + pounce_eats)) * 100.0),
			(skeets + deadstops), (skeets + deadstops + pounce_eats),
			skeets, skeets == 1 ? "":"s", deadstops, dp_eats, dp_eats == 1 ? "":"s");
	}

	if ((successful_booms + shutdown_booms) == 0)
	{
		PrintToChatAll("\x01TEAM - Boomers: \x03N/A\x01");
	}
	else
	{
		PrintToChatAll("\x01TEAM - Boomers: \x04%d%%\x01 (\x05%d\x01/\x05%d\x01) shutdown (\x05%d\x01 vomited, \x05%d\x01 proxied)",
			RoundFloat((float(shutdown_booms) / float(successful_booms + shutdown_booms)) * 100.0),
			shutdown_booms, (shutdown_booms + successful_booms), vomited_survivors, proxied_survivors);
	}

	if ((dmg_from_si + dmg_from_ci + dmg_from_ff) == 0)
	{
		PrintToChatAll("\x01TEAM - Damage: \x03N/A\x01");
	}
	else
	{
		PrintToChatAll("\x01TEAM - Damage: \x05%d\x01 from \x03SI\x01, \x05%d\x01 from \x03common\x01, \x05%d\x01 from \x03FF\x01",
			dmg_from_si, dmg_from_ci, dmg_from_ff);
	}
}

// Spectators: Print survivor stats & infected stats
// Survivors: Print survivor stats
// Infected: Print infected stats
void PrintConsoleStats()
{
	CreateTimer(0.1, Timer_PrintSurvivorStatsHeader);
	CreateTimer(0.2, Timer_PrintSurvivorStatsBody);
	CreateTimer(0.3, Timer_PrintSurvivorStatsFooter);
	CreateTimer(0.4, Timer_PrintInfectedStatsHeader);
	CreateTimer(0.5, Timer_PrintInfectedStatsBody);
	CreateTimer(0.6, Timer_PrintInfectedStatsFooter);
}

Action Timer_PrintSurvivorStatsHeader(Handle timer)
{
	const int maxlength = 1024;
	char buf[maxlength];
	Format(buf, maxlength, "\n|----------------------------------------------- SURVIVOR STATS -----------------------------------------------|\n");
	Format(buf, maxlength, "%s| NAME                 | SIK  | SID    | CI   | DS  | Skeets         | SA  | BS  | FF   | DFC  | Pounces Eaten |\n", buf);
	Format(buf, maxlength, "%s|----------------------|------|--------|------|-----|----------------|-----|-----|------|------|---------------|", buf);
	PrintToTeamConsole(FLAG_SPECTATOR | FLAG_SURVIVOR, buf);
	return Plugin_Stop;
}

Action Timer_PrintSurvivorStatsBody(Handle timer)
{
    int i = 0, j = 0, val = 0;
    int lows_highs[STATS_MAX][2];
    // Initialize lows_highs
    for (i = 0; i < view_as<int>(STATS_MAX); i++)
    {
        lows_highs[i][0] = 9999999;
        lows_highs[i][1] = -1;
    }

    // Calculate actual lows_highs values
    for (i = 1; i <= MaxClients; i++)
    {
        if (!IsClientInGame(i) || !IsSurvivor(i)) continue;
        for (j = 0; j < view_as<int>(STATS_MAX); j++)
        {
            if (j == view_as<int>(TeamSkeets)) continue;
            else if (j == view_as<int>(FullSkeets))
            { // Store the total skeets value in fullskeets, just for checking lows_highs
                val = g_iMapStats[i][FullSkeets] + g_iMapStats[i][TeamSkeets];
            }
            else
            {
                val = g_iMapStats[i][j];
            }
            if (val < lows_highs[j][0]) lows_highs[j][0] = val;
            if (val > lows_highs[j][1]) lows_highs[j][1] = val;
        }
    }

    const int max_name_len = 20;
    const int s_len = 15;
    char name[MAX_NAME_LENGTH];
    char sikills[s_len], sidamage[s_len], cikills[s_len], deadstops[s_len];
    char skeets[s_len], skeetassists[s_len], boomershutdowns[s_len];
    char ff[s_len], cidamage[s_len], pounceseaten[s_len];

    for (i = 1; i <= MaxClients; i++)
    {
        if (!IsClientInGame(i) || !IsSurvivor(i)) continue;
        GetClientName(i, name, sizeof(name));
        name[max_name_len] = 0;
        val = g_iMapStats[i][SIKills];
        Format(sikills, s_len, "%s%d", GetModifierChar(val, SIKills), val);

        val = g_iMapStats[i][SIDamage];
        Format(sidamage, s_len, "%s%d", GetModifierChar(val, SIDamage), val);

        val = g_iMapStats[i][CIKills];
        Format(cikills, s_len, "%s%d", GetModifierChar(val, CIKills), val);

        val = g_iMapStats[i][Deadstops];
        Format(deadstops, s_len, "%s%d", GetModifierChar(val, Deadstops), val);

        val = g_iMapStats[i][FullSkeets] + g_iMapStats[i][TeamSkeets];
        Format(skeets, s_len, "%s%d (%dF/%dT)", GetModifierChar(val, FullSkeets), val,
                                                    g_iMapStats[i][FullSkeets], g_iMapStats[i][TeamSkeets]);

        val = g_iMapStats[i][SkeetAssists];
        Format(skeetassists, s_len, "%s%d", GetModifierChar(val, SkeetAssists), val);

        val = g_iMapStats[i][BoomerShutdowns];
        Format(boomershutdowns, s_len, "%s%d", GetModifierChar(val, BoomerShutdowns), val);

        val = g_iMapStats[i][FF];
        Format(ff, s_len, "%s%d", GetModifierCharReversed(val, FF), val);

        val = g_iMapStats[i][CIDamageTaken];
        Format(cidamage, s_len, "%s%d", GetModifierCharReversed(val, CIDamageTaken), val);

        val = g_iMapStats[i][PouncesEaten];
        Format(pounceseaten, s_len, "%s%d (%d DPs)", GetModifierCharReversed(val, PouncesEaten), val, g_iMapStats[i][DPsEaten]);

        PrintToTeamConsole(FLAG_SPECTATOR | FLAG_SURVIVOR,
            "| %20s | %4s | %6s | %4s | %3s | %14s | %3s | %3s | %4s | %4s | %13s |",
            name,
            sikills,
            sidamage,
            cikills,
            deadstops,
            skeets,
            skeetassists,
            boomershutdowns,
            ff,
            cidamage,
            pounceseaten);
    }
    return Plugin_Stop;
}

Action Timer_PrintSurvivorStatsFooter(Handle timer)
{
	const int maxlength = 1024;
	char buf[maxlength];
	Format(buf, maxlength, "\nLegend:\n");
	Format(buf, maxlength, "%s  %s = Best  %s = Worst\n", buf, HIGHCHAR, LOWCHAR);
	Format(buf, maxlength, "%s  SIK     - Special Infected killed\n", buf);
	Format(buf, maxlength, "%s  SID     - Damage dealt to Special Infected\n", buf);
	Format(buf, maxlength, "%s  CI      - Common infected killed\n", buf);
	Format(buf, maxlength, "%s  DS      - Deadstops landed\n", buf);
	Format(buf, maxlength, "%s  Skeets  - Total number of skeets (# full skeets/# team skeets)\n", buf);
	Format(buf, maxlength, "%s  SA      - Skeets assisted\n", buf);
	Format(buf, maxlength, "%s  BS      - Boomer shutdowns\n", buf);
	Format(buf, maxlength, "%s  FF      - Friendly Fire\n", buf);
	Format(buf, maxlength, "%s  DFC     - Damage from common infected\n", buf);
	PrintToTeamConsole(FLAG_SPECTATOR | FLAG_SURVIVOR, buf);
	return Plugin_Stop;
}

Action Timer_PrintInfectedStatsHeader(Handle timer)
{
	const int maxlength = 1024;
	char buf[maxlength];
	Format(buf, maxlength, "\n|----------------------------------- INFECTED STATS -----------------------------------|\n");
	Format(buf, maxlength, "%s| NAME                 | Dmg   | Pounce Success            | Boomer Success            |\n", buf);
	Format(buf, maxlength, "%s|----------------------|-------|---------------------------|---------------------------|", buf);
    //| Name | *1291 | *100% (10L (2DP)/10S/10D) | *100% (10A/13F/10V/10P) |
	PrintToTeamConsole(FLAG_SPECTATOR | FLAG_INFECTED, buf);
	return Plugin_Stop;
}

Action Timer_PrintInfectedStatsBody(Handle timer)
{
    int dmg_low = 99999999;
    int dmg_high = -1;
    int pounces_low = 99999999;
    int pounces_high = -1;
    int booms_low = 99999999;
    int booms_high = -1;

    int val = 0, i = 0;
    bool has_printed = false;

    for (i = 1; i <= MaxClients; i++)
    {
        if (!IsClientInGame(i) || !IsInfected(i) || IsFakeClient(i)) continue;
        val = g_iMapStats[i][DamageDealtAsSI];
        if (val < dmg_low) dmg_low = val;
        if (val > dmg_high) dmg_high = val;

        val = g_iMapStats[i][PouncesLanded];
        if (val < pounces_low) pounces_low = val;
        if (val > pounces_high) pounces_high = val;

        val = g_iMapStats[i][BoomSuccesses];
        if (val < booms_low) booms_low = val;
        if (val > booms_high) booms_high = val;
    }

    const int max_name_len = 20;
    const int s_len = 30;
    char name[MAX_NAME_LENGTH], dmg[s_len], pounce_success[s_len], boomer_success[s_len];

    for (i = 1; i <= MaxClients; i++)
    {
        // No infected bot stats...
        if (!IsClientInGame(i) || !IsInfected(i) || IsFakeClient(i)) continue;
        GetClientName(i, name, sizeof(name));
        name[max_name_len] = 0;

        val = g_iMapStats[i][DamageDealtAsSI];
        Format(dmg, s_len, "%s%d",
            val == dmg_high ? HIGHCHAR:val == dmg_low ? LOWCHAR:"",
            val);

        val = g_iMapStats[i][PouncesLanded];
        Format(pounce_success, s_len, "%s%d/%d (%d DPs/%d S/%d DS)",
            val == pounces_high ? HIGHCHAR:val == pounces_low ? LOWCHAR:"",
            val,
            val + g_iMapStats[i][Skeeted] + g_iMapStats[i][Deadstopped],
            g_iMapStats[i][DPsLanded],
            g_iMapStats[i][Skeeted],
            g_iMapStats[i][Deadstopped]);

        val = g_iMapStats[i][BoomSuccesses];
        Format(boomer_success, s_len, "%s%d/%d (%d Vomit/%d Proxy)",
            val == booms_high ? HIGHCHAR:val == booms_low ? LOWCHAR:"",
            val,
            g_iMapStats[i][BoomAttempts],
            g_iMapStats[i][BoomedSurvivorsByVomit],
            g_iMapStats[i][BoomedSurvivorsByProxy]);

        PrintToTeamConsole(FLAG_SPECTATOR | FLAG_INFECTED,
            "| %20s | %5s | %25s | %25s |",
            name,
            dmg,
            pounce_success,
            boomer_success);

        has_printed = true;
    }

    if (!has_printed)
    {
        PrintToTeamConsole(FLAG_SPECTATOR | FLAG_INFECTED, "No infected found.");
    }
    return Plugin_Stop;
}

Action Timer_PrintInfectedStatsFooter(Handle timer)
{
	const int maxlength = 1024;
	char buf[maxlength];
	Format(buf, maxlength, "\nLegend:\n");
	Format(buf, maxlength, "%s   Dmg              - Damage dealt to non-incapped survivors\n", buf);
	Format(buf, maxlength, "%s   Pounce Success   - DP = Damage Pounce, S = Skeeted, DS = Deadstop\n", buf);
	PrintToTeamConsole(FLAG_SPECTATOR | FLAG_INFECTED, buf);
	return Plugin_Stop;
}

/*
Action Command_Stats(int client, int args)
{
	if (g_bStatsCooldown[client]) return Plugin_Handled;
	g_bStatsCooldown[client] = true;
	decl String:name[MAX_NAME_LENGTH];
	GetClientName(client, name, sizeof(name));
	if (StrEqual(name, "Griffin"))
	{
		PrintMVPAndTeamStats();
		PrintConsoleStats();
	}
	else
	{
		ReplyToCommand(client, "[SM] This command is currently disabled, stats will print automatically at the end of the round.");
	}
	// PrintToChatAll("[DEBUG] Printing stats to all!\n");
	// PrintStatsToAll();

	// if (GetCmdReplySource() == SM_REPLY_TO_CHAT) PrintToChat(client, "[SM] Check console for output.\n");

	CreateTimer(1.0, Timer_StatsCooldown, client);
	return Plugin_Handled;
}

Action Timer_StatsCooldown(Handle timer, any client)
{
	g_bStatsCooldown[client] = false;
	return Plugin_Stop;
}*/

/*void Cvar_MaxPlayerZombies(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_iMaxPlayerZombies = StringToInt(newValue);
}*/

void Cvar_SurvivorLimit(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_iSurvivorLimit = StringToInt(newValue);
}

void Cvar_MaxPounceBonusDamage(ConVar convar, const char[] oldValue, const char[] newValue)
{
	CalculateMinDPDamage(StringToFloat(newValue));
}

void CalculateMinDPDamage(float bonus_pounce_damage)
{
	// Max pounce damage = bonus pounce damage + 1
	g_iMinDPDamage = RoundToFloor((bonus_pounce_damage + 1.0) * MIN_DP_RATIO);
}

void Cvar_WitchHealth(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_iWitchHealth = StringToInt(newValue);
}

void Cvar_DirectorReadyDuration(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_bLogFF = StringToInt(newValue) > 0 ? true:false;
}

void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	g_bHasRoundEnded = false;
}

void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	// In case witch is avoided
	g_iAccumulatedWitchDamage = 0;
	ResetWitchTracking();
	if (g_bHasRoundEnded) return;
	g_bHasRoundEnded = true;
	CreateTimer(2.0, Timer_DelayedStatsPrint);
	for (int i = 1; i <= MaxClients; i++)
	{
		// if (IsClientInGame(i) && IsSurvivor(i))
		// {
			// buf = GetStatString(i);
			// PrintToChat(i, "Round ended.");
		// }
		ClearDamage(i);
		g_iWitchDamage[i] = 0;
	}
}

Action PlayerHook_OnTakeDamagePre(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	// Non incapped survivor victim
	if (!victim ||
		victim > MaxClients ||
		!IsClientInGame(victim) ||
		!IsSurvivor(victim) ||
		IsIncapped(victim)
		) return Plugin_Continue;

	g_iLastHealth[victim] = GetClientHealth(victim);
	return Plugin_Continue;
}

void Event_PlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
	if (g_bHasRoundEnded) return;
	int victim = GetClientOfUserId(event.GetInt("userid"));

	if (victim == 0 ||
		!IsClientInGame(victim)
		) return;

	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	if (!attacker)
	{
		// Damage from common
		if (!IsCommonInfected(event.GetInt("attackerentid")) || IsIncapped(victim)) return;
		int damage = g_iLastHealth[victim] - event.GetInt("health");
		if (damage < 0 || damage > 2)
		{
			PrintToChatAll("[DEBUG] Invalid common damage value of %d detected for %N. Tell Griffin what happened!",
				damage,
				victim);
			damage = 1;
		}
		g_iMapStats[victim][CIDamageTaken] += damage;

		if (IsBoomed(victim) &&
			g_iBoomerClient &&
			IsClientInGame(g_iBoomerClient) &&
			!IsFakeClient(g_iBoomerClient))
		{
			g_iMapStats[g_iBoomerClient][DamageDealtAsSI] += damage;
		}
		return;
	}
	else if (!IsClientInGame(attacker)) return;

	int damage = event.GetInt("dmg_health");

	if (IsSurvivor(attacker))
	{
		// FF (don't log incapped damage, doesn't matter)
		if (IsSurvivor(victim) && !IsIncapped(victim) && g_bLogFF)
		{
			g_iMapStats[attacker][FF] += damage;
		}
		// Hot survivor on infected action, baby
		else if (IsInfected(victim))
		{
			int zombieclass = GetEntProp(victim, Prop_Send, "m_zombieClass");
			if (zombieclass == view_as<int>(ZC_TANK)) return; // We don't care about tank damage

			if (!g_bShotCounted[victim][attacker])
			{
				g_iShotsDealt[victim][attacker]++;
				g_bShotCounted[victim][attacker] = true;
			}

			int remaining_health = event.GetInt("health");

			// Let player_death handle remainder damage (avoid overkill damage)
			if (remaining_health <= 0) return;

			// remainder health will be awarded as damage on kill
			g_iLastHealth[victim] = remaining_health;

			g_iMapStats[attacker][SIDamage] += damage;
			g_iDamageDealt[victim][attacker] += damage;

			if (zombieclass == view_as<int>(ZC_BOOMER))
			{ /* Boomer Stuff Here */ }
			else if (zombieclass == view_as<int>(ZC_HUNTER))
			{ /* Hunter Stuff Here */ }
		}
	}
	if (IsInfected(attacker) && IsSurvivor(victim) && !IsIncapped(victim))
	{
		g_iMapStats[victim][SIDamageTaken] += damage;
		g_iMapStats[attacker][DamageDealtAsSI] += damage;
	}
}

void Event_PlayerShoved(Event event, const char[] name, bool dontBroadcast)
{
	if (g_bHasRoundEnded) return;
	int victim = GetClientOfUserId(event.GetInt("userid"));
	if (victim == 0 ||
		!IsClientInGame(victim) ||
		!IsInfected(victim)
		) return;

	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	if (attacker == 0 ||				// World dmg?
		!IsClientInGame(attacker) ||	// Unsure
		!IsSurvivor(attacker)
		) return;

	int zombieclass = GetEntProp(victim, Prop_Send, "m_zombieClass");
	if (zombieclass == view_as<int>(ZC_BOOMER))
	{
		if (g_hBoomerShoveTimer != null)
		{
			delete g_hBoomerShoveTimer;
			if (!g_iBoomerShover || !IsClientInGame(g_iBoomerShover)) g_iBoomerShover = attacker;
		}
		else
		{
			g_iBoomerShover = attacker;
		}
		g_hBoomerShoveTimer = CreateTimer(BOOMER_STAGGER_TIME, Timer_BoomerShove);
	}
	else if (zombieclass == view_as<int>(ZC_HUNTER) && IsPouncing(victim))
	{ // DEADSTOP

		// Groundtouch timer will do this for us, but
		// this prevents multiple deadstops being counted incorrectly
		g_bIsPouncing[victim] = false;
		// Delayed check to see if the pounce actually landed due to bug where player_shoved gets fired but pounce lands anyways
		g_bHasLandedPounce[attacker] = false;
		DataPack pack;
		CreateDataTimer(0.2, Timer_DeadstopCheck, pack);
		pack.WriteCell(attacker);
		pack.WriteCell(victim);
	}
}

Action Timer_DeadstopCheck(Handle timer, DataPack hPack)
{
	hPack.Reset();
	int attacker = hPack.ReadCell();
	if (!g_bHasLandedPounce[attacker])
	{
		int victim = hPack.ReadCell();
		// TODO: Add tracking for number of times a person was deadstopped (along with other pounce stats)
		g_iMapStats[attacker][Deadstops]++;
		if (IsClientInGame(victim) && IsClientInGame(attacker))
		{
			PrintToChat(attacker, "[SM] You deadstopped %N.", victim);
			if (!IsFakeClient(victim))
			{
				g_iMapStats[victim][Deadstopped]++;
				PrintToChat(victim, "[SM] You were deadstopped by %N.", attacker);
			}
		}
	}
	return Plugin_Stop;
}

Action Timer_BoomerShove(Handle timer)
{
	// PrintToChatAll("[DEBUG] BoomerShove timer expired, credit for boomer shutdown is available to anyone at this point!");
	g_hBoomerShoveTimer = null;
	g_iBoomerShover = 0;
	return Plugin_Stop;
}

void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (client == 0 || !IsClientInGame(client)) return;

	if (IsInfected(client))
	{
		int zombieclass = GetEntProp(client, Prop_Send, "m_zombieClass");
		if (zombieclass == view_as<int>(ZC_TANK)) return;

		if (zombieclass == view_as<int>(ZC_BOOMER))
		{
			// Fresh boomer spawning (if g_iBoomerClient is set and an AI boomer spawns, it's a boomer going AI)
			if (!IsFakeClient(client) || !g_iBoomerClient)
			{
				g_bHasBoomLanded = false;
				g_iBoomerClient = client;
				g_iBoomerShover = 0;
				g_iBoomerKiller = 0;
			}
			if (!IsFakeClient(client))
			{
				g_iMapStats[client][BoomAttempts]++;
			}
			if (g_hBoomerShoveTimer != null)
			{
				delete g_hBoomerShoveTimer;
			}
		}

		g_iLastHealth[client] = GetClientHealth(client);
	}
}

void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	if (g_bHasRoundEnded) return;
	int victim = GetClientOfUserId(event.GetInt("userid"));

	if (victim == 0 ||
		!IsClientInGame(victim)
		) return;

	int attacker = GetClientOfUserId(event.GetInt("attacker"));

	if (attacker == 0)
	{ // Check for a witch-related death (black & white survivor failing or no-incap configs e.g. 1v1)
		if (IsInfected(victim)) ClearDamage(victim);
		if (!IsWitch(event.GetInt("attackerentid")) ||
			!g_bShouldAnnounceWitchDamage					// Prevent double print on incap -> death by witch
			) return;
		
		int health = g_iWitchHealth - g_iAccumulatedWitchDamage;
		if (health < 0) health = 0;

		PrintToChatAll("[SM] Witch had %d health remaining.", health);
		for (int i = 1; i <= MaxClients; i++)
		{
			if (g_iWitchDamage[i] > 0 && IsClientInGame(i))
			{
				PrintToChat(i, "[SM] You dealt %d damage to the witch.", g_iWitchDamage[i]);
			}
		}
		g_iAccumulatedWitchDamage = 0;
		g_bShouldAnnounceWitchDamage = false;
		return;
	}

	if (!IsClientInGame(attacker))
	{
		if (IsInfected(victim)) ClearDamage(victim);
		return;
	}

	if (IsSurvivor(attacker) && IsInfected(victim))
	{
		int zombieclass = GetEntProp(victim, Prop_Send, "m_zombieClass");
		if (zombieclass == view_as<int>(ZC_TANK)) return; // We don't care about tank damage
	
		g_iMapStats[attacker][SIKills]++;
		int lasthealth = g_iLastHealth[victim];
		g_iMapStats[attacker][SIDamage] += lasthealth;
		g_iDamageDealt[victim][attacker] += lasthealth;
		if (zombieclass == view_as<int>(ZC_BOOMER))
		{
			// Only happens on mid map plugin load when a boomer is up
			if (!g_iBoomerClient) g_iBoomerClient = victim;

			CreateTimer(0.2, Timer_BoomerKilledCheck, victim);
			g_iBoomerKiller = attacker;
		}
		else if (zombieclass == view_as<int>(ZC_HUNTER) && IsPouncing(victim))
		{ // Skeet!
			if (!IsFakeClient(victim))
			{
				g_iMapStats[victim][Skeeted]++;
			}
			int[][] assisters = new int[g_iSurvivorLimit][2];
			int assister_count = 0, i = 0;
			int damage = g_iDamageDealt[victim][attacker];
			int shots = g_iShotsDealt[victim][attacker];
			char plural[1];
			if (shots == 1) plural[0] = 0;
			for (i = 1; i <= MaxClients; i++)
			{
				if (i == attacker) continue;
				if (g_iDamageDealt[victim][i] > 0 && IsClientInGame(i))
				{
					g_iMapStats[i][SkeetAssists]++;
					assisters[assister_count][0] = i;
					assisters[assister_count][1] = g_iDamageDealt[victim][i];
					assister_count++;
				}
			}
			if (assister_count)
			{
				// Sort by damage, descending
				SortCustom2D(assisters, assister_count, ClientValue2DSortDesc);
				char assister_string[128];
				char buf[MAX_NAME_LENGTH + 8];
				int assist_shots = g_iShotsDealt[victim][assisters[0][0]];
				// Construct assisters string
				Format(assister_string, sizeof(assister_string), "%N (%d/%d shot%s)",
					assisters[0][0],
					assisters[0][1],
					g_iShotsDealt[victim][assisters[0][0]],
					assist_shots == 1 ? "":"s");
				for (i = 1; i < assister_count; i++)
				{
					assist_shots = g_iShotsDealt[victim][assisters[i][0]];
					Format(buf, sizeof(buf), ", %N (%d/%d shot%s)",
						assisters[i][0],
						assisters[i][1],
						assist_shots,
						assist_shots == 1 ? "":"s");
					StrCat(assister_string, sizeof(assister_string), buf);
				}

				// Print to assisters
				for (i = 0; i < assister_count; i++)
				{
					PrintToChat(assisters[i][0], "[SM] %N teamskeeted %N for %d damage in %d shot%s. Assisted by: %s.",
						attacker, victim, damage, shots, plural, assister_string);
				}
				// Print to victim
				PrintToChat(victim, "[SM] You were teamskeeted by %N for %d damage in %d shot%s. Assisted by: %s.",
					attacker, damage, shots, plural, assister_string);

				// Finally print to attacker
				PrintToChat(attacker, "[SM] You teamskeeted %N for %d damage in %d shot%s. Assisted by: %s.",
					victim, damage, shots, plural, assister_string);

				g_iMapStats[attacker][TeamSkeets]++;
			}
			else
			{
				g_iMapStats[attacker][FullSkeets]++;
				PrintToChat(victim, "[SM] You were skeeted by %N in %d shot%s.", attacker, shots, plural);
				PrintToChat(attacker, "[SM] You skeeted %N in %d shot%s.", victim, shots, plural);
			}
		}
	}

	if (IsInfected(victim)) ClearDamage(victim);
}

Action Timer_BoomerKilledCheck(Handle timer, any client)
{
	// if g_iBoomerClient != client, boomer went AI, maybe do something with that info in the future?
	if (g_bHasBoomLanded) return Plugin_Stop;

	// In the following code even if it was an AI boomer that was shutdown, we're going to consider the AI boomer
	// the responsibility of the person who spawned it, aka g_iBoomerClient
	if (g_iBoomerShover && IsClientInGame(g_iBoomerShover))
	{
		if (IsClientInGame(g_iBoomerClient))
		{
			if (IsFakeClient(g_iBoomerClient))
			{
				PrintToChat(g_iBoomerShover, "[SM] You shut down an AI boomer.");
			}
			else
			{
				PrintToChat(g_iBoomerShover, "[SM] You shut down %N's boomer.", g_iBoomerClient);
				PrintToChat(g_iBoomerClient, "[SM] %N shut down your boomer.", g_iBoomerShover);
				// g_iMapStats[g_iBoomerClient][BoomFailures]++;
			}
		}
		g_iMapStats[g_iBoomerShover][BoomerShutdowns]++;
	}
	else if (IsClientInGame(g_iBoomerKiller))
	{
		if (IsClientInGame(g_iBoomerClient))
		{
			if (IsFakeClient(g_iBoomerClient))
			{
				PrintToChat(g_iBoomerKiller, "[SM] You shut down an AI boomer.");
			}
			else
			{
				PrintToChat(g_iBoomerKiller, "[SM] You shut down %N's boomer.", g_iBoomerClient);
				PrintToChat(g_iBoomerClient, "[SM] %N shut down your boomer.", g_iBoomerKiller);
				// g_iMapStats[g_iBoomerClient][BoomFailures]++;
			}
		}
		g_iMapStats[g_iBoomerKiller][BoomerShutdowns]++;
	}

	g_iBoomerClient = 0;
	return Plugin_Stop;
}

void Event_InfectedDeath(Event event, const char[] name, bool dontBroadcast)
{
	if (g_bHasRoundEnded) return;
	// NOTE: Has some interesting stats like headshots, if it was a minigun kill or from explosion (might use in future)
	int attacker = GetClientOfUserId(event.GetInt("attacker"));

	if (attacker == 0 ||				// Killed by world?
		!IsClientInGame(attacker) ||
		!IsSurvivor(attacker)			// Tank killing common?
		) return;

	g_iMapStats[attacker][CIKills]++;
}

void Event_WeaponFire(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	for (int i = 1; i <= MaxClients; i++)
	{
		// [Victim][Attacker]
		g_bShotCounted[i][client] = false;
	}
}

void Event_PlayerIncapacitated(Event event, const char[] name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(event.GetInt("userid"));
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	if (attacker && IsClientInGame(attacker) && IsInfected(attacker))
	{
		g_iMapStats[victim][SIDamageTaken] += g_iLastHealth[victim];
		g_iMapStats[attacker][DamageDealtAsSI] += g_iLastHealth[victim];
		return;
	}

	if (!IsWitch(event.GetInt("attackerentid")) ||
		!g_bShouldAnnounceWitchDamage					// Prevent double print on witch incapping 2 players (rare)
		) return;

	int health = g_iWitchHealth - g_iAccumulatedWitchDamage;
	if (health < 0) health = 0;

	PrintToChatAll("[SM] Witch had %d health remaining.", health);
	for (int i = 1; i <= MaxClients; i++)
	{
		if (g_iWitchDamage[i] > 0 && IsClientInGame(i) && IsSurvivor(i))
		{
			PrintToChat(i, "[SM] You dealt %d damage to the witch.", g_iWitchDamage[i]);
		}
	}
	g_iAccumulatedWitchDamage = 0;
	g_bShouldAnnounceWitchDamage = false;
}

void Event_InfectedHurt(Event event, const char[] name, bool dontBroadcast)
{
	if (g_bHasRoundEnded) return;
	int attacker = GetClientOfUserId(event.GetInt("attacker"));

	if (attacker == 0 ||								// Killed by world?
		!IsWitch(event.GetInt("entityid")) ||		// Tracking witch damage only
		!IsClientInGame(attacker) ||
		!IsSurvivor(attacker)							// Claws
		) return;

	int damage = event.GetInt("amount");
	g_iWitchDamage[attacker] += damage;
	g_iAccumulatedWitchDamage += damage;
}

void Event_WitchKilled(Event event, const char[] name, bool dontBroadcast)
{
	if (g_bHasRoundEnded) return;
	g_bIsWitch[event.GetInt("witchid")] = false;

	int killer = GetClientOfUserId(event.GetInt("userid"));

	if (killer == 0 ||				// Killed by world?
		!IsClientInGame(killer)
		) return;

	// Witch kills increment CI kill count, we don't want that (this seems hacky)
	if (IsSurvivor(killer)) g_iMapStats[killer][CIKills]--;

	// Not a crown, show all the survivors how they helped
	// TODO: will show someone how much damage they did on an unassisted drawcrown, fix? do we care?
	if (!event.GetBool("oneshot") && g_bShouldAnnounceWitchDamage)
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (g_iWitchDamage[i] > 0 && IsClientInGame(i) && IsSurvivor(i))
			{
				PrintToChat(i, "[SM] You dealt %d damage to the witch.", g_iWitchDamage[i]);
			}
			g_iWitchDamage[i] = 0;
		}
	}

	for (int i = 1; i <= MaxClients; i++) { g_iWitchDamage[i] = 0; }
	g_iAccumulatedWitchDamage = 0;
	g_bShouldAnnounceWitchDamage = true;
}

void Event_WitchSpawn(Event event, const char[] name, bool dontBroadcast)
{
	if (g_bHasRoundEnded) return;
	g_bIsWitch[event.GetInt("witchid")] = true;
	g_bShouldAnnounceWitchDamage = true;
}

// Pounce tracking, from skeet announce
void Event_AbilityUse(Event event, const char[] name, bool dontBroadcast)
{
	if (g_bHasRoundEnded) return;
	int client = GetClientOfUserId(event.GetInt("userid"));
	char ability_name[64];

	event.GetString("ability", ability_name, sizeof(ability_name));
	if (IsClientInGame(client) && strcmp(ability_name, "ability_lunge", false) == 0)
	{
		g_bIsPouncing[client] = true;
		CreateTimer(0.5, Timer_GroundedCheck, client, TIMER_REPEAT);
	}
}

Action Timer_GroundedCheck(Handle timer, any client)
{
	if (!IsClientInGame(client) || IsGrounded(client))
	{
		g_bIsPouncing[client] = false;
		timer = null;
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

void Event_LungePounce(Event event, const char[] name, bool dontBroadcast)
{
	int attacker = GetClientOfUserId(event.GetInt("userid"));
	int victim = GetClientOfUserId(event.GetInt("victim"));
	g_bIsPouncing[attacker] = false;
	g_bHasLandedPounce[attacker] = true;

	// Don't count pounce stats for pounces on incapped survivors
	if (IsIncapped(victim)) return;

	g_iMapStats[attacker][PouncesLanded]++;
	g_iMapStats[victim][PouncesEaten]++;
	if (event.GetInt("damage") >= g_iMinDPDamage)
	{
		g_iMapStats[attacker][DPsLanded]++;
		g_iMapStats[victim][DPsEaten]++;
	}
}

void Event_PlayerBoomed(Event event, const char[] name, bool dontBroadcast)
{
	// This will only occur if the plugin is loaded mid map (and a boomer is already spawned)
	if (!g_iBoomerClient)
	{
		g_iBoomerClient = GetClientOfUserId(event.GetInt("attacker"));
	}

	if (!g_bHasBoomLanded)
	{
		g_iMapStats[g_iBoomerClient][BoomSuccesses]++;
		g_bHasBoomLanded = true;
	}

	// Doesn't matter if we log stats to an out of play client, won't affect anything
	// if (!IsClientInGame(g_iBoomerClient) || IsFakeClient(g_iBoomerClient)) return;

	// We credit the person who spawned the boomer with booms even if it went AI
	if (event.GetBool("exploded"))
	{
		// possible TODO: g_iBoomerKiller's fault, use this for something?
		g_iMapStats[g_iBoomerClient][BoomedSurvivorsByProxy]++;
	}
	else
	{
		g_iMapStats[g_iBoomerClient][BoomedSurvivorsByVomit]++;
	}
}

stock void ClearMapStats()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		for (int j = 0; j < view_as<int>(STATS_MAX); j++) g_iMapStats[i][j] = 0;
		g_iWitchDamage[i] = 0;
		ClearDamage(i);
	}
	g_iAccumulatedWitchDamage = 0;
	ResetWitchTracking();
}

stock void ClearPlayerStatsAndState(int client)
{
	for (int i = 0; i < view_as<int>(STATS_MAX); i++) g_iMapStats[client][i] = 0;
	g_iWitchDamage[client] = 0;
	ClearDamage(client);
}

stock void ResetWitchTracking()
{
	for (int i = MaxClients + 1; i < MAXENTITIES; i++) g_bIsWitch[i] = false;
}

// Clear g_iDamageDealt, g_iShotsDealt, and g_iLastHealth for given client
stock void ClearDamage(int client)
{
	g_iLastHealth[client] = 0;
	for (int i = 1; i <= MaxClients; i++)
	{
		g_iDamageDealt[client][i] = 0;
		g_iShotsDealt[client][i] = 0;
	}
}

stock bool IsCommonInfected(int entity)
{
	if(entity > MaxClients && entity <= GetMaxEntities() && IsValidEntity(entity) && IsValidEdict(entity))
	{
		char classname[32];
		GetEdictClassname(entity, classname, sizeof(classname));
		return StrEqual(classname, "infected");
	}
	return false;
}

// Takes 2D arrays [index] = {client, value}
stock int ClientValue2DSortDesc(int[] x, int[] y, const int[][] array, Handle data)
{
	if (x[1] > y[1]) return -1;
	else if (x[1] < y[1]) return 1;
	else return 0;
}

// Jacked from skeet announce
stock bool IsGrounded(int client)
{
	return (GetEntProp(client, Prop_Data, "m_fFlags") & FL_ONGROUND) > 0;
}

stock void PrintToTeamConsole(int teamflag, const char[] format, any ...)
{
	char buffer[1024];
	for(int i = 1;i <= MaxClients;i++)
	{
		if(IsClientInGame(i) && (!teamflag || teamflag & (1 << GetClientTeam(i))))
		{
			VFormat(buffer, sizeof(buffer), format, 3);
			PrintToConsole(i, buffer);
		}
	}
}
