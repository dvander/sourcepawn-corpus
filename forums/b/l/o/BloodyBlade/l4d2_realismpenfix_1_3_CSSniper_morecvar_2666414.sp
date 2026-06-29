#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdkhooks>

#define PLUGIN_VERSION "1.3"
#define CVAR_FLAGS FCVAR_NOTIFY

// %1 = client
#define IS_VALID_CLIENT(%1) (%1 > 0 && %1 <= MaxClients)
#define IS_CONNECTED_INGAME(%1) (IsClientConnected(%1) && IsClientInGame(%1))
#define IS_SURVIVOR(%1) (GetClientTeam(%1) == 2)
#define IS_INFECTED(%1) (GetClientTeam(%1) == 3)

#define IS_VALID_INGAME(%1) (IS_VALID_CLIENT(%1) && IS_CONNECTED_INGAME(%1))

#define IS_VALID_SURVIVOR(%1) (IS_VALID_INGAME(%1) && IS_SURVIVOR(%1))
#define IS_VALID_INFECTED(%1) (IS_VALID_INGAME(%1) && IS_INFECTED(%1))

#define IS_SURVIVOR_ALIVE(%1) (IS_VALID_SURVIVOR(%1) && IsPlayerAlive(%1))
#define IS_INFECTED_ALIVE(%1) (IS_VALID_INFECTED(%1) && IsPlayerAlive(%1))

ConVar cvarEnable, cvarMode, cvarDebug, cvarNerfMagnum, cvarBuffSniper, cvarBuffSniperScout, cvarBuffSniperAWP, cvarMagnumLimit, cvarSniperLimit, cvarSniperLimitScout, cvarSniperLimitAWP, difficulty, gamemode;
bool g_bDebug, g_bRealism, g_bHooked = false;
int g_iNerfMagnum, g_iBuffSniper, g_iBuffSniperScout, g_iBuffSniperAWP, g_iMagnumPenetrationLimit, g_iSniperPenetrationLimit, g_iSniperScoutPenetrationLimit, g_iSniperAWPPenetrationLimit, g_iMode, g_iCurrentPenetrationCount[MAXPLAYERS+1] = {0, ...};
float g_fDifficultyMultiplier;

public Plugin myinfo =
{
	name = "L4D2 Realism Penetration Fix",
	author = "dcx2",
	description = "Fixes penetration on Realism (or all) by buffing sniper and/or nerfing magnum",
	version = PLUGIN_VERSION,
	url = "www.AlliedMods.net"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();
	if( test != Engine_Left4Dead2 )
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 2.");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

public void OnPluginStart()
{
	cvarEnable = CreateConVar("sm_realismpenfix_enable", "1.0", "Plugin On/Off", CVAR_FLAGS);
	cvarMode = CreateConVar("sm_realismpenfix_mode", "1.0", "1 = realism only, 2 = all game modes", CVAR_FLAGS);
	cvarDebug = CreateConVar("sm_realismpenfix_debug", "0.0", "Print debug output.", CVAR_FLAGS);
	cvarNerfMagnum = CreateConVar("sm_realismpenfix_nerfmagnum", "1.0", "0: full penetration bonus\n1: half penetration bonus\n2: no penetration bonus, no distance penalty\n3: no penetration bonus, plus distance damage penalty", CVAR_FLAGS);
	cvarBuffSniper = CreateConVar("sm_realismpenfix_buffsniper", "1.0", "0: no penetration bonus\n1: half penetration bonus\n2: full penetration bonus", CVAR_FLAGS);
	cvarBuffSniperScout = CreateConVar("sm_realismpenfix_buffsniper_scout", "2.0", "0: no penetration bonus\n1: half penetration bonus\n2: full penetration bonus", CVAR_FLAGS);
	cvarBuffSniperAWP = CreateConVar("sm_realismpenfix_buffsniper_awp", "2.0", "0: no penetration bonus\n1: half penetration bonus\n2: full penetration bonus", CVAR_FLAGS);
	cvarMagnumLimit = CreateConVar("sm_realismpenfix_magnumlimit", "0.0", "Maximum number of enemies one magnum bullet can kill (0 disables feature)", CVAR_FLAGS);
	cvarSniperLimit = CreateConVar("sm_realismpenfix_sniperlimit", "0.0", "Maximum number of enemies one (non-CSS) sniper bullet can kill (0 disables feature)", CVAR_FLAGS);
	cvarSniperLimitScout = CreateConVar("sm_realismpenfix_sniperlimit_scout", "0.0", "Maximum number of enemies one scout (CSS) sniper bullet can kill (0 disables feature)", CVAR_FLAGS);
	cvarSniperLimitAWP = CreateConVar("sm_realismpenfix_sniperlimit_awp", "0.0", "Maximum number of enemies one AWP (CSS) sniper bullet can kill (0 disables feature)", CVAR_FLAGS);
	CreateConVar("sm_realismpenfix_ver", PLUGIN_VERSION, "L4D2 Realism Penetration Fix version", CVAR_FLAGS|FCVAR_DONTRECORD);

	cvarEnable.AddChangeHook(OnConVarPluginOnChanged);
	cvarMode.AddChangeHook(OnConVarsChanged);
	cvarDebug.AddChangeHook(OnConVarsChanged);
	cvarNerfMagnum.AddChangeHook(OnConVarsChanged);
	cvarBuffSniper.AddChangeHook(OnConVarsChanged);
	cvarBuffSniperScout.AddChangeHook(OnConVarsChanged);
	cvarBuffSniperAWP.AddChangeHook(OnConVarsChanged);
	cvarMagnumLimit.AddChangeHook(OnConVarsChanged);
	cvarSniperLimit.AddChangeHook(OnConVarsChanged);
	cvarSniperLimitScout.AddChangeHook(OnConVarsChanged);
	cvarSniperLimitAWP.AddChangeHook(OnConVarsChanged);

	difficulty = FindConVar("z_difficulty");
	difficulty.AddChangeHook(OnConVarsChanged);
	gamemode = FindConVar("mp_gamemode");
	gamemode.AddChangeHook(OnConVarsChanged);
	AutoExecConfig(true, "l4d2_realismpenfix");
}

public void OnConfigsExecuted()
{
	IsAllowed();
}

void IsAllowed()
{
	bool bAllowed = cvarEnable.BoolValue;
	if(bAllowed)
	{
		GetCvars();
		HookEvent("weapon_fire", Event_WeaponFire);
	}
	else
	{
		UnhookEvent("weapon_fire", Event_WeaponFire);
	}
}

void OnConVarPluginOnChanged(ConVar cvar, const char[] oldVal, const char[] newVal)
{
	IsAllowed();
}

void OnConVarsChanged(ConVar cvar, const char[] oldVal, const char[] newVal)
{
	GetCvars();
}

void GetCvars()
{
	// get cvars after AutoExecConfig
	g_iMode = cvarMode.IntValue;
	g_bDebug = cvarDebug.BoolValue;
	if (g_bDebug)
	{
		if (!g_bHooked)
		{
			HookEvent("infected_hurt", Event_InfectedHurt);
			g_bHooked = true;
		}
	}
	else
	{
		if(g_bHooked)
		{
			UnhookEvent("infected_hurt", Event_InfectedHurt);
			g_bHooked = false;
		}
	}
	g_iNerfMagnum = cvarNerfMagnum.IntValue;
	g_iBuffSniper = cvarBuffSniper.IntValue;
	g_iBuffSniperScout = cvarBuffSniperScout.IntValue;
	g_iBuffSniperAWP = cvarBuffSniperAWP.IntValue;
	g_iMagnumPenetrationLimit = cvarMagnumLimit.IntValue;
	g_iSniperPenetrationLimit = cvarSniperLimit.IntValue;
	g_iSniperScoutPenetrationLimit = cvarSniperLimitScout.IntValue;
	g_iSniperAWPPenetrationLimit = cvarSniperLimitAWP.IntValue;
	char difficultyString[32], gamemodeString[32];
	difficulty.GetString(difficultyString, sizeof(difficultyString));
	g_fDifficultyMultiplier = GetDifficultyMultiplier(difficultyString);
	gamemode.GetString(gamemodeString, sizeof(gamemodeString));
	g_bRealism = isGameModeRealism(gamemodeString);
	if (g_bDebug)
	{
		if (g_bRealism) PrintToChatAll("Realism");
		else PrintToChatAll("Not realism");
		PrintToChatAll("Difficulty multiplier %f", g_fDifficultyMultiplier);
	}
}

bool isGameModeRealism(const char[] GameMode)
{
	return (StrContains(GameMode, "realism", false) >= 0);
}

float GetDifficultyMultiplier(const char[] Difficulty)
{
	float ret = 1.0;
	if (g_bRealism)
	{
		if (StrEqual(Difficulty, "impossible", false)) ret = FindConVar("z_non_head_damage_factor_expert").FloatValue;
		if (StrEqual(Difficulty, "hard", false)) ret = FindConVar("z_non_head_damage_factor_expert").FloatValue;
		if (StrEqual(Difficulty, "normal", false)) ret = FindConVar("z_non_head_damage_factor_hard").FloatValue;
		if (StrEqual(Difficulty, "easy", false)) ret = FindConVar("z_non_head_damage_factor_normal").FloatValue;
	}
	else
	{
		if (StrEqual(Difficulty, "impossible", false)) ret = FindConVar("z_non_head_damage_factor_expert").FloatValue;
		if (StrEqual(Difficulty, "hard", false)) ret = FindConVar("z_non_head_damage_factor_hard").FloatValue;
		if (StrEqual(Difficulty, "normal", false)) ret = FindConVar("z_non_head_damage_factor_normal").FloatValue;
		if (StrEqual(Difficulty, "easy", false)) ret = FindConVar("z_non_head_damage_factor_easy").FloatValue;
	}

	ret *= FindConVar("z_non_head_damage_factor_multiplier").FloatValue;
	return ret;
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if (entity > MaxClients && entity <= 2048)
	{
		if (StrEqual(classname, "infected"))
		{
			SDKHook(entity, SDKHook_SpawnPost, RealismPenetrationFix_SpawnPost);
		}
	}
}

Action Event_InfectedHurt(Event event, const char[] name, bool dontBroadcast)
{
	if (g_iMode > 0 && g_bDebug)
	{
		int entityid = event.GetInt("entityid");
		PrintToChatAll("IH: Hit infected in the %d for %d damage (%d health)", event.GetInt("hitgroup"), event.GetInt("amount"), GetEntProp(entityid, Prop_Data, "m_iHealth"));
	}
	return Plugin_Continue;
}

// Model name does not exist until after the uncommon is spawned
void RealismPenetrationFix_SpawnPost(int entity)
{
	SDKHook(entity, SDKHook_TraceAttack, RealismPenetrationFixTraceAttack);
	SDKHook(entity, SDKHook_OnTakeDamage, RealismPenetrationFixOnTakeDamage);
}

float lastTraceAttackDamage = 0.0;
Action RealismPenetrationFixTraceAttack(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &ammotype, int hitbox, int hitgroup)
{
	if (g_bDebug)
	{
		char victimName[MAX_TARGET_LENGTH] = "Unconnected", attackerName[MAX_TARGET_LENGTH] = "Unconnected", inflictorName[32] = "Invalid";

		if (victim > 0 && victim <= MaxClients && IsClientConnected(victim))		GetClientName(victim, victimName, sizeof(victimName));
		else if (IsValidEntity(victim))												GetEntityClassname(victim, victimName, sizeof(victimName));

		if (attacker > 0 && attacker <= MaxClients && IsClientConnected(attacker))	GetClientName(attacker, attackerName, sizeof(attackerName));
		else if (IsValidEntity(attacker))											GetEntityClassname(attacker, attackerName, sizeof(attackerName));

		if (inflictor > 0 && IsValidEntity(inflictor))								GetEntityClassname(inflictor, inflictorName, sizeof(inflictorName));

		PrintToChatAll("TA: %s hit %s in the %d / %d with %s / %x / %d for %.2f", attackerName, victimName, hitbox, hitgroup, inflictorName, damagetype, ammotype, damage);
	}
	lastTraceAttackDamage = damage;
	return Plugin_Continue;
}

Action RealismPenetrationFixOnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3])
{
	bool changed = false, bModeEnabled = (g_iMode == 2) || (g_iMode == 1 && g_bRealism);
	char weaponName[32] = "Invalid";
	int buffSniper, sniperPenetrationLimit;

	// Are we enabled?
	// Is attacker a Survivor that is alive?
	if (bModeEnabled && IS_SURVIVOR_ALIVE(attacker))
	{
		g_iCurrentPenetrationCount[attacker]++;
		if (weapon > 0 && IsValidEntity(weapon)) GetEntityClassname(weapon, weaponName, sizeof(weaponName));

		// MasterMe: Determine sniper values to simplify other logic.
		// This is done even if the current weapon is not a sniper.
		if (StrEqual(weaponName, "weapon_sniper_scout"))
		{
			buffSniper = g_iBuffSniperScout;
			sniperPenetrationLimit = g_iSniperScoutPenetrationLimit;
		}
		else if (StrEqual(weaponName, "weapon_sniper_awp"))
		{
			buffSniper = g_iBuffSniperAWP;
			sniperPenetrationLimit = g_iSniperAWPPenetrationLimit;
		}
		else
		{
			buffSniper = g_iBuffSniper;
			sniperPenetrationLimit = g_iSniperPenetrationLimit;
		}

		// If not realism, is sniper being nerfed?
		// If realism, is sniper being buffed?
		// If any gamemode, is magnum being nerfed?
		// Did the attacker NOT do a head shot? (damagetype 0x40000000)
		// MasterMe: The odd indentation here helps with readability.
		if (((!g_bRealism && buffSniper < 2) || (g_bRealism && buffSniper > 0) || g_iNerfMagnum > 0) && !(damagetype & 0x40000000))
		{
			bool bNerfMag = g_iNerfMagnum > 0, bMagStumble = true;
			if ((bNerfMag || bMagStumble) && StrEqual(weaponName, "weapon_pistol_magnum"))
			{
				if (bNerfMag)
				{
					if (g_iNerfMagnum > 2) damage = g_fDifficultyMultiplier * lastTraceAttackDamage; // 3: no penetration bonus, distance penalty
					else if (g_iNerfMagnum > 1) damage = g_fDifficultyMultiplier * 78.0; // 2: no penetration bonus, no distace penalty
					else damage /= 2.0; // 1: half penetration bonus
					changed = true;
				}

				if (bMagStumble)
				{
					// TODO: get pos of infected and survivor, TeleportEntity the infected in that direction with some amount of velocity
					// TODO: SDKCall InfectedShoved::OnShoved(Infected *, CBaseEntity *)?  ScaleVector damageForce by something ridiculous?
				}
			}
			else if (((!g_bRealism && buffSniper < 2) || (g_bRealism && buffSniper > 0)) && (StrEqual(weaponName, "weapon_hunting_rifle") || StrEqual(weaponName, "weapon_sniper_military") || StrEqual(weaponName, "weapon_sniper_scout") || StrEqual(weaponName, "weapon_sniper_awp")))
			{
				float maxHealth = float(GetEntProp(victim, Prop_Data, "m_iMaxHealth")), newDamage = damage;
				// Penetration bonus is 1/2 for Fallen Survivor
				if (isFallenSurvivor(victim)) maxHealth /= 2.0;
				if (g_bRealism)
				{
					if (buffSniper > 1) newDamage = maxHealth; // 2: full penetration bonus
					else newDamage = maxHealth / 2.0; // 1: half penetration bonus
					if (newDamage > damage) damage = newDamage;
					changed = true;
				}
				else if (!g_bRealism)
				{
					if (buffSniper < 1) damage = g_fDifficultyMultiplier * damage; // 0: No penetration bonus
					else newDamage = maxHealth / 2.0; // 1: half penetration bonus
					if (newDamage < damage) damage = newDamage;
					changed = true;
				}
			}
		}

		if (g_bDebug)
		{
			char victimName[MAX_TARGET_LENGTH] = "Unconnected", attackerName[MAX_TARGET_LENGTH] = "Unconnected", inflictorName[32] = "Invalid";

			if (victim > 0 && victim <= MaxClients && IsClientConnected(victim))		GetClientName(victim, victimName, sizeof(victimName));
			else if (IsValidEntity(victim))												GetEntityClassname(victim, victimName, sizeof(victimName));

			if (attacker > 0 && attacker <= MaxClients && IsClientConnected(attacker))	GetClientName(attacker, attackerName, sizeof(attackerName));
			else if (IsValidEntity(attacker))											GetEntityClassname(attacker, attackerName, sizeof(attackerName));

			if (inflictor > 0 && IsValidEntity(inflictor))								GetEntityClassname(inflictor, inflictorName, sizeof(inflictorName));
			PrintToChatAll("OTD: %s hit %s %d with %s / %s / %x for %.2f [%.2f]", attackerName, victimName, g_iCurrentPenetrationCount[attacker], weaponName, inflictorName, damagetype, damage, GetVectorLength(damageForce));
		}

		if (g_iMagnumPenetrationLimit > 0 && g_iCurrentPenetrationCount[attacker] > g_iMagnumPenetrationLimit && StrEqual(weaponName, "weapon_pistol_magnum"))
		{
			return Plugin_Handled;
		}

		if (sniperPenetrationLimit > 0 && g_iCurrentPenetrationCount[attacker] > sniperPenetrationLimit && (StrEqual(weaponName, "weapon_hunting_rifle") || StrEqual(weaponName, "weapon_sniper_military") || StrEqual(weaponName, "weapon_sniper_scout") || StrEqual(weaponName, "weapon_sniper_awp")))
		{
			return Plugin_Handled;
		}
	}
	if (changed) return Plugin_Changed;
	else return Plugin_Continue;
}

Action Event_WeaponFire(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(client > 0) g_iCurrentPenetrationCount[client] = 0;
	return Plugin_Continue;
}

stock bool isFallenSurvivor(int entity)
{
	if (entity > 0 && entity <= 2048 && IsValidEdict(entity) && IsValidEntity(entity))
	{
		char model[128];
		GetEntPropString(entity, Prop_Data, "m_ModelName", model, sizeof(model));
		return StrContains(model, "fallen") != -1; // Common is a fallen uncommon
	}
	return false;
}
