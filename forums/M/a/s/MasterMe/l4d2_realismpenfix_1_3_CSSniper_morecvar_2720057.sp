#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdkhooks>

#define PLUGIN_VERSION "1.3"
#define PLUGIN_NAME "L4D2 Realism Penetration Fix"
#define CVAR_FLAGS FCVAR_NONE|FCVAR_NOTIFY

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


int g_iEnabled;
bool g_bDebug;
int g_iNerfMagnum;
int g_iBuffSniper;
int g_iBuffSniperScout;
int g_iBuffSniperAWP;
int g_iMagnumPenetrationLimit;
int g_iSniperPenetrationLimit;
int g_iSniperScoutPenetrationLimit;
int g_iSniperAWPPenetrationLimit;

int g_iCurrentPenetrationCount[MAXPLAYERS+1] = { 0, ... };

float g_fDifficultyMultiplier;
bool g_bRealism;

public Plugin myinfo =
{
	name = PLUGIN_NAME,
	author = "dcx2",
	description = "Fixes penetration on Realism (or all) by buffing sniper and/or nerfing magnum",
	version = PLUGIN_VERSION,
	url = "www.AlliedMods.net"
}

public void OnPluginStart()
{
	Require_L4D2();

	ConVar cvarEnable = CreateConVar("sm_realismpenfix_enable", "1.0", "Enables this plugin (1 = realism only, 2 = all game modes)", CVAR_FLAGS);
	ConVar cvarDebug = CreateConVar("sm_realismpenfix_debug", "0.0", "Print debug output.", CVAR_FLAGS);
	ConVar cvarNerfMagnum = CreateConVar("sm_realismpenfix_nerfmagnum", "1.0", "0: full penetration bonus\n1: half penetration bonus\n2: no penetration bonus, no distance penalty\n3: no penetration bonus, plus distance damage penalty", CVAR_FLAGS);
	ConVar cvarBuffSniper = CreateConVar("sm_realismpenfix_buffsniper", "1.0", "0: no penetration bonus\n1: half penetration bonus\n2: full penetration bonus", CVAR_FLAGS);
	ConVar cvarBuffSniperScout = CreateConVar("sm_realismpenfix_buffsniper_scout", "2.0", "0: no penetration bonus\n1: half penetration bonus\n2: full penetration bonus", CVAR_FLAGS);
	ConVar cvarBuffSniperAWP = CreateConVar("sm_realismpenfix_buffsniper_awp", "2.0", "0: no penetration bonus\n1: half penetration bonus\n2: full penetration bonus", CVAR_FLAGS);
	ConVar cvarMagnumLimit = CreateConVar("sm_realismpenfix_magnumlimit", "0.0", "Maximum number of enemies one magnum bullet can kill (0 disables feature)", CVAR_FLAGS);
	ConVar cvarSniperLimit = CreateConVar("sm_realismpenfix_sniperlimit", "0.0", "Maximum number of enemies one (non-CSS) sniper bullet can kill (0 disables feature)", CVAR_FLAGS);
	ConVar cvarSniperLimitScout = CreateConVar("sm_realismpenfix_sniperlimit_scout", "0.0", "Maximum number of enemies one scout (CSS) sniper bullet can kill (0 disables feature)", CVAR_FLAGS);
	ConVar cvarSniperLimitAWP = CreateConVar("sm_realismpenfix_sniperlimit_awp", "0.0", "Maximum number of enemies one AWP (CSS) sniper bullet can kill (0 disables feature)", CVAR_FLAGS);
	CreateConVar("sm_realismpenfix_ver", PLUGIN_VERSION, PLUGIN_NAME, CVAR_FLAGS|FCVAR_DONTRECORD);

	AutoExecConfig(true, "l4d2_realismpenfix");

	HookConVarChange(cvarEnable, OnRPFEnableChanged);
//	HookConVarChange(cvarDebug, OnRPFDebugChanged);
	HookConVarChange(cvarNerfMagnum, OnNerfMagnumChanged);
	HookConVarChange(cvarBuffSniper, OnBuffSniperChanged);
	HookConVarChange(cvarBuffSniperScout, OnBuffSniperScoutChanged);
	HookConVarChange(cvarBuffSniperAWP, OnBuffSniperAWPChanged);
	HookConVarChange(cvarMagnumLimit, OnMagnumLimitChanged);
	HookConVarChange(cvarSniperLimit, OnSniperLimitChanged);
	HookConVarChange(cvarSniperLimitScout, OnSniperLimitScoutChanged);
	HookConVarChange(cvarSniperLimitAWP, OnSniperLimitAWPChanged);

	// get cvars after AutoExecConfig
	g_iEnabled = GetConVarInt(cvarEnable);
	g_bDebug = GetConVarBool(cvarDebug);
	g_iNerfMagnum = GetConVarInt(cvarNerfMagnum);
	g_iBuffSniper = GetConVarInt(cvarBuffSniper);
	g_iBuffSniperScout = GetConVarInt(cvarBuffSniperScout);
	g_iBuffSniperAWP = GetConVarInt(cvarBuffSniperAWP);
	g_iMagnumPenetrationLimit = GetConVarInt(cvarMagnumLimit);
	g_iSniperPenetrationLimit = GetConVarInt(cvarSniperLimit);
	g_iSniperScoutPenetrationLimit = GetConVarInt(cvarSniperLimitScout);
	g_iSniperAWPPenetrationLimit = GetConVarInt(cvarSniperLimitAWP);

	HookEvent("weapon_fire", Event_WeaponFire);
	if (g_bDebug)
	{
		HookEvent("infected_hurt", Event_InfectedHurt);
	}

	ConVar difficulty = FindConVar("z_difficulty");
	HookConVarChange(difficulty, OnDifficultyChanged);
	char difficultyString[32];
	GetConVarString(difficulty, difficultyString, sizeof(difficultyString));
	g_fDifficultyMultiplier = GetDifficultyMultiplier(difficultyString);

	ConVar gamemode = FindConVar("mp_gamemode");
	HookConVarChange(gamemode, OnGameModeChanged);
	char gamemodeString[32];
	GetConVarString(gamemode, gamemodeString, sizeof(gamemodeString));
	g_bRealism = isGameModeRealism(gamemodeString);
}

stock void Require_L4D2()
{
	char game[32];
	GetGameFolderName(game, sizeof(game));
	if (!StrEqual(game, "left4dead2", false))
	{
		SetFailState("Plugin supports Left 4 Dead 2 only.");
	}
}

public void OnGameModeChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_bRealism = isGameModeRealism(newValue);
	if (g_bDebug)
	{
		if (g_bRealism) PrintToChatAll("Realism");
		else PrintToChatAll("Not realism");
	}
}

public void OnDifficultyChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_fDifficultyMultiplier = GetDifficultyMultiplier(newValue);
	if (g_bDebug) PrintToChatAll("Difficulty multiplier %f", g_fDifficultyMultiplier);
}

public bool isGameModeRealism(const char[] GameMode)
{
	return (StrContains(GameMode, "realism", false) >= 0);
}

public float GetDifficultyMultiplier(const char[] Difficulty)
{
	float ret = 1.0;
	if (g_bRealism)
	{
		if (StrEqual(Difficulty, "impossible", false)) ret = GetConVarFloat(FindConVar("z_non_head_damage_factor_expert"));
		if (StrEqual(Difficulty, "hard", false)) ret = GetConVarFloat(FindConVar("z_non_head_damage_factor_expert"));
		if (StrEqual(Difficulty, "normal", false)) ret = GetConVarFloat(FindConVar("z_non_head_damage_factor_hard"));
		if (StrEqual(Difficulty, "easy", false)) ret = GetConVarFloat(FindConVar("z_non_head_damage_factor_normal"));
	}
	else
	{
		if (StrEqual(Difficulty, "impossible", false)) ret = GetConVarFloat(FindConVar("z_non_head_damage_factor_expert"));
		if (StrEqual(Difficulty, "hard", false)) ret = GetConVarFloat(FindConVar("z_non_head_damage_factor_hard"));
		if (StrEqual(Difficulty, "normal", false)) ret = GetConVarFloat(FindConVar("z_non_head_damage_factor_normal"));
		if (StrEqual(Difficulty, "easy", false)) ret = GetConVarFloat(FindConVar("z_non_head_damage_factor_easy"));
	}

	ret *= GetConVarFloat(FindConVar("z_non_head_damage_factor_multiplier"));
	return ret;
}

public void OnNerfMagnumChanged(ConVar cvar, const char[] oldVal, const char[] newVal)
{
	g_iNerfMagnum = StringToInt(newVal);
}

public void OnBuffSniperChanged(ConVar cvar, const char[] oldVal, const char[] newVal)
{
	g_iBuffSniper = StringToInt(newVal);
}

public void OnBuffSniperScoutChanged(ConVar cvar, const char[] oldVal, const char[] newVal)
{
	g_iBuffSniperScout = StringToInt(newVal);
}

public void OnBuffSniperAWPChanged(ConVar cvar, const char[] oldVal, const char[] newVal)
{
	g_iBuffSniperAWP = StringToInt(newVal);
}

public void OnMagnumLimitChanged(ConVar cvar, const char[] oldVal, const char[] newVal)
{
	g_iMagnumPenetrationLimit = StringToInt(newVal);
}

public void OnSniperLimitChanged(ConVar cvar, const char[] oldVal, const char[] newVal)
{
	g_iSniperPenetrationLimit = StringToInt(newVal);
}

public void OnSniperLimitScoutChanged(ConVar cvar, const char[] oldVal, const char[] newVal)
{
	g_iSniperScoutPenetrationLimit = StringToInt(newVal);
}

public void OnSniperLimitAWPChanged(ConVar cvar, const char[] oldVal, const char[] newVal)
{
	g_iSniperAWPPenetrationLimit = StringToInt(newVal);
}

public void OnRPFEnableChanged(ConVar cvar, const char[] oldVal, const char[] newVal)
{
	g_iEnabled = StringToInt(newVal);
}
/*
public void OnRPFDebugChanged(ConVar cvar, const char[] oldVal, const char[] newVal)
{
	g_bDebug = StringToInt(newVal) == 1;
	if (g_bDebug)
	{
		HookEvent("infected_hurt", Event_InfectedHurt);
	}
	else
	{
		UnhookEvent("infected_hurt", Event_InfectedHurt);
	}
}
*/
public void OnEntityCreated(int entity, const char[] classname)
{
	if (entity <= MaxClients || entity > 2048) return;

	if (StrEqual(classname, "infected"))
	{
		SDKHook(entity, SDKHook_SpawnPost, RealismPenetrationFix_SpawnPost);
	}
}

public Action Event_InfectedHurt(Event event, const char[] name, bool dontBroadcast)
{
	if (g_iEnabled > 0 && g_bDebug)
	{
		int entityid = GetEventInt(event, "entityid");
		PrintToChatAll("IH: Hit infected in the %d for %d damage (%d health)", GetEventInt(event, "hitgroup"), GetEventInt(event, "amount"), GetEntProp(entityid, Prop_Data, "m_iHealth"));
	}
}

// Model name does not exist until after the uncommon is spawned
public void RealismPenetrationFix_SpawnPost(int entity)
{
	SDKHook(entity, SDKHook_TraceAttack, RealismPenetrationFixTraceAttack);
	SDKHook(entity, SDKHook_OnTakeDamage, RealismPenetrationFixOnTakeDamage);
}

float lastTraceAttackDamage = 0.0;
public Action RealismPenetrationFixTraceAttack(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &ammotype, int hitbox, int hitgroup)
{
	if (g_bDebug)
	{
		char victimName[MAX_TARGET_LENGTH] = "Unconnected";
		char attackerName[MAX_TARGET_LENGTH] = "Unconnected";
		char inflictorName[32] = "Invalid";

		if (victim > 0 && victim <= MaxClients && IsClientConnected(victim))		GetClientName(victim, victimName, sizeof(victimName));
		else if (IsValidEntity(victim))												GetEntityClassname(victim, victimName, sizeof(victimName));

		if (attacker > 0 && attacker <= MaxClients && IsClientConnected(attacker))	GetClientName(attacker, attackerName, sizeof(attackerName));
		else if (IsValidEntity(attacker))											GetEntityClassname(attacker, attackerName, sizeof(attackerName));

		if (inflictor > 0 && IsValidEntity(inflictor))								GetEntityClassname(inflictor, inflictorName, sizeof(inflictorName));

		PrintToChatAll("TA: %s hit %s in the %d / %d with %s / %x / %d for %.2f", attackerName, victimName, hitbox, hitgroup, inflictorName, damagetype, ammotype, damage);
	}
	/*
	// was trying to see if I could make magnum bullets have deeper penetration
	if (ammotype == 2)
	{
		ammotype = 10;
		return Plugin_Changed;
	}
	*/
	lastTraceAttackDamage = damage;
	return Plugin_Continue;
}

public Action RealismPenetrationFixOnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3])
{
	bool changed = false;
	bool bModeEnabled = (g_iEnabled == 2) || (g_iEnabled == 1 && g_bRealism);
	char weaponName[32] = "Invalid";

	// Are we enabled?
	// Is attacker a Survivor that is alive?
	if (bModeEnabled && IS_SURVIVOR_ALIVE(attacker))
	{
		g_iCurrentPenetrationCount[attacker]++;
		if (weapon > 0 && IsValidEntity(weapon))
		{
			GetEntityClassname(weapon, weaponName, sizeof(weaponName));
		}

		// MasterMe: Determine sniper values to simplify other logic.
		// This is done even if the current weapon is not a sniper.
		int buffSniper;
		int sniperPenetrationLimit;
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
		if (
			(
				(!g_bRealism && buffSniper < 2)
				|| (g_bRealism && buffSniper > 0)
				|| g_iNerfMagnum > 0
			)
			&& !(damagetype & 0x40000000)
		)
		{
			bool bNerfMag = g_iNerfMagnum > 0, bMagStumble = true;

			if ((bNerfMag || bMagStumble) && StrEqual(weaponName, "weapon_pistol_magnum"))
			{
				if (bNerfMag)
				{
					if (g_iNerfMagnum > 2)
					{
						// 3: no penetration bonus, distance penalty
						damage = g_fDifficultyMultiplier * lastTraceAttackDamage;
					}
					else if (g_iNerfMagnum > 1)
					{
						// 2: no penetration bonus, no distace penalty
						damage = g_fDifficultyMultiplier * 78.0;
					}
					else
					{
						// 1: half penetration bonus
						damage /= 2.0;
					}
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
				float maxHealth = float(GetEntProp(victim, Prop_Data, "m_iMaxHealth"));

				// Penetration bonus is 1/2 for Fallen Survivor
				if (isFallenSurvivor(victim)) maxHealth /= 2.0;

				float newDamage = damage;

				if (g_bRealism)
				{
					if (buffSniper > 1)
					{
						// 2: full penetration bonus
						newDamage = maxHealth;
					} else {
						// 1: half penetration bonus
						newDamage = maxHealth/2.0;
					}
					if (newDamage > damage) damage = newDamage;
					changed = true;
				}
				else if (!g_bRealism)
				{
					if (buffSniper < 1)
					{
						// 0: No penetration bonus
						damage = g_fDifficultyMultiplier * damage;
					}
					else
					{
						// 1: half penetration bonus
						newDamage = maxHealth/2.0;
					}
					if (newDamage < damage) damage = newDamage;
					changed = true;
				}
			}
		}
		if (g_bDebug)
		{
			char victimName[MAX_TARGET_LENGTH] = "Unconnected";
			char attackerName[MAX_TARGET_LENGTH] = "Unconnected";
			char inflictorName[32] = "Invalid";

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

public Action Event_WeaponFire(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	g_iCurrentPenetrationCount[client] = 0;
}

stock bool isFallenSurvivor(int entity)
{
	if (entity <= 0 || entity > 2048 || !IsValidEdict(entity)) return false;
	char model[128];
	GetEntPropString(entity, Prop_Data, "m_ModelName", model, sizeof(model));
	return StrContains(model, "fallen") != -1; // Common is a fallen uncommon
}
