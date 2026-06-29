#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

public Plugin myinfo =
{
	name        = "L4D2 Survivor Bot Auto-Shove",
	author      = "BatoSaiX",
	description = "Survivor bots automatically shove nearby Common and Special Infected",
	version     = "1.57",
	url         = ""
}

/*
// ====================================================================================================

About:

    Makes survivor bots automatically shove (melee push) Common Infected and
    Special Infected that enter their personal space.

    Priority order when both types are nearby:
        1. Special Infected (Smoker, Boomer, Hunter, Spitter, Jockey)
        2. Common Infected

    Common Infected are NEVER ignored -- even when a Special Infected was
    shoved on the previous tick, the bot will keep shoving CI that crowd it.

    The shove is triggered via IN_ATTACK2 (secondary attack / push button).
    Bots do not suffer shove fatigue (only human players do), so no cooldown
    is applied -- they will shove every tick a threat is within range.

    Entity and client scanning is done inline every tick so bots react
    instantly without waiting on a cache rebuild timer.

    Works alongside l4d2_sb_fix or standalone.


// ====================================================================================================

CVars:

    sb_shove_enabled            <0/1>   Master on/off switch. Default: 1

    -- Common Infected --
    sb_shove_ci_range           <float> Distance (units) within which a CI
                                        triggers a shove. Default: 75.0
    sb_shove_ci_min_count       <int>   Minimum number of CI within range before
                                        shoving. 1 = any single CI. Default: 1
    sb_shove_ci_attack_only     <0/1>   When enabled, bots only shove CI that are
                                        actively attacking (m_nSequence <= 121).
                                        CI that are staggering, climbing, or already
                                        knocked down are ignored, matching the same
                                        logic l4d2_sb_fix uses to filter its CI
                                        targets. Default: 1

    -- Special Infected --
    sb_shove_si_enabled         <0/1>   Enable shoving Special Infected. Default: 1
    sb_shove_si_range           <float> Distance (units) within which an SI
                                        triggers a shove. Default: 75.0


// ====================================================================================================

Change Log:

1.57 (28-May-2026)
    - Added: sb_shove_ci_attack_only CVar (default: 0). When enabled, bots only
             shove CI whose m_nSequence indicates an active attack (sequence <= 121).
             CI that are staggering (122-134), climbing (182-223), or knocked down
             are skipped entirely. Uses the same sequence ranges as l4d2_sb_fix.

1.56 (27-May-2026)
    - Fixed: g_iMaxEntities was 0 on late plugin load (sm_load mid-game) because
             only OnMapStart populated it, which never fires on a late load. Now
             also set in OnPluginStart and OnAllPluginsLoaded, so the CI entity
             loop always has a valid upper bound regardless of when the plugin loads.
    - Fixed: m_pounceVictim was read on every SI including Smokers, Boomers,
             Spitters and Jockeys which don't have that network prop, risking a
             runtime error. The read is now gated behind a ZC_HUNTER check.
    - Fixed: m_iHealth was read before IsCommonInfected in the CI entity loop.
             Some valid entities don't have Prop_Data m_iHealth and would throw
             a native error. Reverted order to classname check first (safe to
             read on any entity), health check second (safe once we know it's CI).

1.55 (24-May-2026)
    - Fixed: Bots no longer shove at empty air when a Hunter is pouncing a
             survivor. When a Hunter has an active m_pounceVictim, both the
             Hunter and victim are prone on the ground, so the old +50u torso
             offset aimed well above the pile. The bot now aims at the victim's
             ground position + 20u so the shove arc connects with the Hunter
             crouching on top of them.

1.54 (24-May-2026)
    - Fixed: Removed unused defines PLUGIN_TAG, MAXPLAYERS1, and ZC_CHARGER.
    - Fixed: GetClientAbsOrigin was called twice per tick per bot to fill both
             botPos and botFeet. Now called once; botPos is derived from botFeet
             by adding 44.0 to the Z component.
    - Fixed: In the CI entity loop, the health check (cheap integer read) now
             runs before IsCommonInfected (GetEntityClassname string call),
             skipping dead entities without touching the classname at all.
    - Perf:  GetMaxEntities() is now cached in g_iMaxEntities on OnMapStart
             instead of being called every tick inside OnPlayerRunCmd.

1.53 (28-April-2026)
    - Removed: sb_shove_cache_interval CVar and the entire entity/client cache
               system (Timer_RebuildCache, g_CachedCI, g_CachedSI, etc).
               OnPlayerRunCmd now scans entities and client slots directly every
               tick so bots react instantly with no cache rebuild delay.

1.52 (28-April-2026)
    - Fixed: Bots no longer attempt to shove a Charger. The Charger is immune
             to shoves entirely, so ZC_CHARGER (6) is now excluded from
             IsShovableSI. The valid SI shove range is now Smoker through
             Jockey (ZC 1-5) only.

1.51 (26-April-2026)
    - Fixed: Bots holding a chainsaw no longer shove instead of using it.
             The chainsaw uses classname "weapon_chainsaw", not "weapon_melee"
             like all other melee weapons, so the existing IsHoldingMelee check
             silently missed it. Both classnames are now checked.

1.50 (26-April-2026)
    - Fixed: Bots no longer aim at the floor when a CI/SI is on top of a table
             or elevated prop. Two root causes addressed:
             (1) Eye position (~64u) sits above short props, making the chest-
                 to-torso vector point downward even on visually elevated targets.
                 Aim origin changed from eyes to CHEST (feet + 44u), a neutral
                 midpoint that stays below most table-height targets.
             (2) Replaced GetVectorAngles + normalization entirely. GetVectorAngles
                 returns pitch in [0, 360) where "up" produces values near 270-360,
                 requiring error-prone normalization. Now yaw and pitch are computed
                 directly with ArcTangent2, which already returns (-180, 180) and
                 naturally handles Source's down-positive pitch convention without
                 any post-processing.

1.40 (23-April-2026)
    - Fixed: Bots no longer aim at the head when a CI/SI is on elevated or
             lower ground. Aim origin switched from bot feet (GetClientAbsOrigin)
             to bot eyes (GetClientEyePosition), and shovePos now stores the
             target's torso (origin + 40 for CI, origin + 50 for SI) instead of
             their feet. The eye-to-torso vector naturally stays centered on the
             body at any terrain height. Pitch is soft-clamped to [-45, 45] as a
             safety net for extreme geometry.
    - Changed: Distance range checks still use foot-to-foot distance so
               sb_shove_ci_range and sb_shove_si_range remain intuitive.

1.30 (23-April-2026)
    - Fixed: Bots holding a melee weapon no longer have IN_ATTACK2 (shove)
             injected. The shove button cancels a melee swing, so the plugin
             now steps aside and lets the bot's normal AI handle the attack.

1.20 (22-April-2026)
    - Removed: sb_shove_cooldown CVar and per-bot cooldown logic. Bots do not
               have shove fatigue (only human players do), so the cooldown
               served no purpose and was unnecessarily limiting shove rate.

1.10 (21-April-2026)
    - Added: Shoving of nearby Special Infected (Smoker, Boomer, Hunter,
             Spitter, Jockey, Charger) with higher priority than CI.
    - Fixed: Common Infected are no longer ignored when an SI is also nearby.
             Bots now shove whichever threat is closest and most urgent.
    - Added: sb_shove_si_enabled and sb_shove_si_range CVars.
    - Added: sb_shove_si_range defaults to 150 (wider than CI range) because
             Special Infected pose a greater threat at approach distance.
    - Renamed shared CVars from sb_shove_ci_* to sb_shove_* where appropriate.

1.00 (21-April-2026)
    - Initial release.

// ====================================================================================================
*/

// ====================================================================================================
// Constants
// ====================================================================================================

// L4D2 team numbers
#define TEAM_SURVIVOR   2
#define TEAM_INFECTED   3

// L4D2 zombie classes for Special Infected player slots
#define ZC_SMOKER       1
#define ZC_BOOMER       2
#define ZC_HUNTER       3
#define ZC_SPITTER      4
#define ZC_JOCKEY       5
// ZC_CHARGER (6) is immune to shoves -- excluded.
// ZC_WITCH   (7) is a world entity, not a client -- excluded.
// ZC_TANK    (8) should be shot, not shoved -- excluded.

// ====================================================================================================
// ConVars
// ====================================================================================================
ConVar g_cvEnabled;
ConVar g_cvCIRange;
ConVar g_cvCIMinCount;
ConVar g_cvCIAttackOnly;
ConVar g_cvSIEnabled;
ConVar g_cvSIRange;

// ====================================================================================================
// Cached convar values (updated via hooks to avoid GetConVar overhead in hot path)
// ====================================================================================================
bool  g_bEnabled;
float g_fCIRange;
int   g_iCIMinCount;
bool  g_bCIAttackOnly;
bool  g_bSIEnabled;
float g_fSIRange;

// Cached at map start -- GetMaxEntities() return value never changes at runtime.
int   g_iMaxEntities;

/****************************************************************************************************/

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if (GetEngineVersion() != Engine_Left4Dead2)
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 2.");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

public void OnPluginStart()
{
	g_cvEnabled = CreateConVar(
		"sb_shove_enabled", "1",
		"Master on/off for survivor bot auto-shove. <0: Disable | 1: Enable>",
		FCVAR_NOTIFY, true, 0.0, true, 1.0);

	g_cvCIRange = CreateConVar(
		"sb_shove_ci_range", "75.0",
		"Distance (units) at which a bot shoves a Common Infected. <10.0 ~ 300.0 | def: 75.0>",
		FCVAR_NOTIFY, true, 10.0, true, 300.0);

	g_cvCIMinCount = CreateConVar(
		"sb_shove_ci_min_count", "1",
		"Minimum number of CI in range before the bot shoves. 1 = any single CI. <1 ~ 10 | def: 1>",
		FCVAR_NOTIFY, true, 1.0, true, 10.0);

	g_cvCIAttackOnly = CreateConVar(
		"sb_shove_ci_attack_only", "1",
		"Only shove CI that are actively attacking (m_nSequence <= 121). Ignores staggering/climbing/downed CI. <0: Disable | 1: Enable>",
		FCVAR_NOTIFY, true, 0.0, true, 1.0);

	g_cvSIEnabled = CreateConVar(
		"sb_shove_si_enabled", "1",
		"Enable shoving nearby Special Infected. <0: Disable | 1: Enable>",
		FCVAR_NOTIFY, true, 0.0, true, 1.0);

	g_cvSIRange = CreateConVar(
		"sb_shove_si_range", "75.0",
		"Distance (units) at which a bot shoves a Special Infected. <10.0 ~ 300.0 | def: 75.0>",
		FCVAR_NOTIFY, true, 10.0, true, 300.0);

	g_cvEnabled.AddChangeHook(OnConVarChanged);
	g_cvCIRange.AddChangeHook(OnConVarChanged);
	g_cvCIMinCount.AddChangeHook(OnConVarChanged);
	g_cvCIAttackOnly.AddChangeHook(OnConVarChanged);
	g_cvSIEnabled.AddChangeHook(OnConVarChanged);
	g_cvSIRange.AddChangeHook(OnConVarChanged);

	RefreshConVars();
	g_iMaxEntities = GetMaxEntities(); // populate for late plugin loads
	AutoExecConfig(true, "l4d2_sb_shove");
}

public void OnAllPluginsLoaded()
{
	RefreshConVars();
	g_iMaxEntities = GetMaxEntities(); // also refresh here in case it wasn't set yet
}

public void OnMapStart()
{
	g_iMaxEntities = GetMaxEntities();
}

/****************************************************************************************************/

public void OnConVarChanged(Handle cvar, const char[] oldVal, const char[] newVal)
{
	RefreshConVars();
}

void RefreshConVars()
{
	g_bEnabled    = g_cvEnabled.BoolValue;
	g_fCIRange      = g_cvCIRange.FloatValue;
	g_iCIMinCount   = g_cvCIMinCount.IntValue;
	g_bCIAttackOnly = g_cvCIAttackOnly.BoolValue;
	g_bSIEnabled  = g_cvSIEnabled.BoolValue;
	g_fSIRange    = g_cvSIRange.FloatValue;
}

/****************************************************************************************************/

// ====================================================================================================
// Core logic -- called every game tick per player
// ====================================================================================================
public Action OnPlayerRunCmd(int client, int &buttons, int &impulse,
	float vel[3], float angles[3], int &weapon)
{
	if (!g_bEnabled)             return Plugin_Continue;
	if (!IsSurvivorBot(client))  return Plugin_Continue;
	if (!IsPlayerAlive(client))  return Plugin_Continue;
	if (IsIncapacitated(client)) return Plugin_Continue;
	if (IsPinned(client))        return Plugin_Continue;
	if (IsOnLadder(client))      return Plugin_Continue;
	if (IsHoldingMelee(client))  return Plugin_Continue;

	// Distance checks use foot-to-foot distance so range CVars stay intuitive.
	// botPos is chest height (feet + 44u) used as the aim origin -- eyes (~64u)
	// sit above short props and would produce downward vectors on elevated targets.
	float botFeet[3];
	GetClientAbsOrigin(client, botFeet);
	float botPos[3];
	botPos = botFeet;
	botPos[2] += 44.0;

	// shoveTarget: entity index (CI) or client index (SI) to shove.
	// shovePos: TARGET'S TORSO position so the aim vector stays centered
	// on the body regardless of terrain height difference.
	int   shoveTarget = -1;
	float shovePos[3];

	// ==========================================================================
	// Step 1 -- Special Infected  (PRIORITY)
	//   Scan all client slots directly for the closest shovable SI.
	// ==========================================================================
	if (g_bSIEnabled)
	{
		float bestSIDist = g_fSIRange + 1.0;

		for (int i = 1; i <= MaxClients; i++)
		{
			if (!IsShovableSI(i)) continue;

			float siPos[3];
			GetClientAbsOrigin(i, siPos);

			float dist = GetVectorDistance(botFeet, siPos);
			if (dist >= bestSIDist) continue;

			bestSIDist  = dist;
			shoveTarget = i;

			// When a Hunter is actively pouncing a survivor, both the Hunter
			// and victim are on the ground. Using the Hunter's origin + 50
			// aims at empty air above the pile. Instead, aim at the victim's
			// ground position + 20 so the shove connects with the Hunter
			// crouching on top of them.
			// NOTE: m_pounceVictim only exists on Hunters (ZC_HUNTER == 3).
			//       Reading it on a Smoker/Boomer/etc would cause a runtime error.
			int zc = GetEntProp(i, Prop_Send, "m_zombieClass");
			if (zc == ZC_HUNTER)
			{
				int victim = GetEntPropEnt(i, Prop_Send, "m_pounceVictim");
				if (victim > 0 && IsClientInGame(victim))
				{
					GetClientAbsOrigin(victim, shovePos);
					shovePos[2] += 20.0; // low aim: Hunter and victim are both prone
				}
				else
				{
					shovePos    = siPos;
					shovePos[2] += 50.0; // Hunter is standing -- normal torso height
				}
			}
			else
			{
				shovePos    = siPos;
				shovePos[2] += 50.0; // normal standing SI torso height
			}
		}
	}

	// ==========================================================================
	// Step 2 -- Common Infected  (FALLBACK -- but NEVER ignored)
	//   Scan all entities directly for the closest CI within range.
	// ==========================================================================
	{
		int   ciInRange  = 0;
		int   bestCIEnt  = -1;
		float bestCIDist = g_fCIRange + 1.0;

		for (int i = MaxClients + 1; i <= g_iMaxEntities; i++)
		{
			if (!IsValidEntity(i))                           continue;
			if (!IsCommonInfected(i))                        continue; // classname check first
			if (GetEntProp(i, Prop_Data, "m_iHealth") <= 0) continue; // then health -- safe since we know it's a CI

			// If attack-only mode is enabled, skip CI that are staggering,
			// climbing, or already knocked down. Only shove CI whose sequence
			// indicates they are walking/running/attacking toward the bot.
			// Sequence ranges sourced from l4d2_sb_fix:
			//   Stagger:           122-134
			//   Down Stagger:      128-131
			//   Climb (Very Low):  182-189
			//   Climb (Low):       190-199
			//   Climb (High):      206-223
			// Active attack sequences are everything outside those ranges (<= 121
			// covers walk/run/attack; 200-205 and 224+ are other non-attack states).
			if (g_bCIAttackOnly)
			{
				int iSeq = GetEntProp(i, Prop_Send, "m_nSequence", 2);
				if (!((iSeq <= 121) || (iSeq >= 135 && iSeq <= 189) || (iSeq >= 200 && iSeq <= 205) || (iSeq >= 224)))
					continue;
			}

			float ciPos[3];
			GetEntPropVector(i, Prop_Data, "m_vecAbsOrigin", ciPos);

			float dist = GetVectorDistance(botFeet, ciPos);
			if (dist >= g_fCIRange) continue;

			ciInRange++;

			if (dist < bestCIDist)
			{
				bestCIDist = dist;
				bestCIEnt  = i;
			}
		}

		// Promote CI to shove target only if no SI was found AND min count is met
		if (shoveTarget < 0 && ciInRange >= g_iCIMinCount && bestCIEnt >= 0)
		{
			shoveTarget = bestCIEnt;
			GetEntPropVector(bestCIEnt, Prop_Data, "m_vecAbsOrigin", shovePos);
			shovePos[2] += 40.0; // aim at CI torso
		}
	}

	// ==========================================================================
	// Step 3 -- Execute shove
	// ==========================================================================
	if (shoveTarget < 0)
		return Plugin_Continue;

	// Compute yaw and pitch directly with ArcTangent2 -- never use GetVectorAngles.
	// GetVectorAngles returns pitch in [0, 360) where "up" produces values near
	// 270-360, which breaks naive clamping. ArcTangent2 returns (-180, 180)
	// directly and naturally matches Source's down-positive pitch convention.
	float dir[3];
	MakeVectorFromPoints(botPos, shovePos, dir);

	float yaw   = RadToDeg(ArcTangent2(dir[1], dir[0]));
	float hDist = SquareRoot(dir[0] * dir[0] + dir[1] * dir[1]);
	float pitch = RadToDeg(ArcTangent2(-dir[2], hDist));
	if      (pitch >  45.0) pitch =  45.0;
	else if (pitch < -45.0) pitch = -45.0;

	angles[0] = pitch;
	angles[1] = yaw;
	angles[2] = 0.0;
	TeleportEntity(client, NULL_VECTOR, angles, NULL_VECTOR);

	buttons |= IN_ATTACK2;

	return Plugin_Changed;
}

/****************************************************************************************************/

// ====================================================================================================
// Helper functions
// ====================================================================================================
bool IsSurvivorBot(int client)
{
	return (client > 0
		&& client <= MaxClients
		&& IsClientInGame(client)
		&& IsFakeClient(client)
		&& GetClientTeam(client) == TEAM_SURVIVOR);
}

bool IsIncapacitated(int client)
{
	return (GetEntProp(client, Prop_Send, "m_isIncapacitated", 1) == 1);
}

/* Returns true if the bot is currently grabbed/pinned by a Special Infected. */
bool IsPinned(int client)
{
	static const char pinProps[][] = {
		"m_tongueOwner",    // Smoker
		"m_pounceAttacker", // Hunter
		"m_jockeyAttacker", // Jockey
		"m_carryAttacker",  // Charger (carry)
		"m_pummelAttacker"  // Charger (pummel)
	};

	for (int i = 0; i < sizeof(pinProps); i++)
	{
		int attacker = GetEntPropEnt(client, Prop_Send, pinProps[i]);
		if (attacker > 0 && IsClientInGame(attacker))
			return true;
	}
	return false;
}

bool IsOnLadder(int client)
{
	return (GetEntityMoveType(client) == MOVETYPE_LADDER);
}

bool IsCommonInfected(int entity)
{
	static char cls[16];
	GetEntityClassname(entity, cls, sizeof(cls));
	return (strcmp(cls, "infected") == 0);
}

/* Returns true if the bot's active weapon is a melee weapon or chainsaw.
 * Melee weapons use classname "weapon_melee" (frying pan, machete, etc).
 * The chainsaw is a separate class "weapon_chainsaw" and must be checked
 * explicitly -- pressing shove while either is active cancels the attack. */
bool IsHoldingMelee(int client)
{
	int activeWep = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	if (activeWep <= 0 || !IsValidEntity(activeWep)) return false;

	static char cls[32];
	GetEntityClassname(activeWep, cls, sizeof(cls));
	return (strcmp(cls, "weapon_melee") == 0 || strcmp(cls, "weapon_chainsaw") == 0);
}

/* Returns true if the client is a live Special Infected eligible for shoving.
 * Charger (ZC 6) is excluded -- it is immune to shoves entirely.
 * Tank   (ZC 8) is excluded -- bots should shoot it, not shove it.
 * Witch  (ZC 7) is a world entity and never a client, so it can't appear here. */
bool IsShovableSI(int client)
{
	if (client <= 0 || client > MaxClients)     return false;
	if (!IsClientInGame(client))                return false;
	if (GetClientTeam(client) != TEAM_INFECTED) return false;
	if (!IsPlayerAlive(client))                 return false;

	int zc = GetEntProp(client, Prop_Send, "m_zombieClass");
	return (zc >= ZC_SMOKER && zc <= ZC_JOCKEY); // Smoker, Boomer, Hunter, Spitter, Jockey only
}
